# -*- encoding : utf-8 -*-
class Faction < ActiveRecord::Base
  has_many :factions_banned_users, :dependent => :destroy
  has_bank_account

  has_and_belongs_to_many :portals
  has_many :avatars
  has_many :users
  has_many :gmtv_channels, :dependent => :destroy
  has_many :factions_links, :dependent => :destroy
  has_many :factions_headers, :dependent => :destroy

  after_save :update_img_files

  after_create :notify_capos_on_create  # TODO mover a otro sitio

  has_users_skill 'Moderator'
  has_users_skill 'Boss'
  has_users_skill 'Underboss'

  GRACE_DAYS = 7

  # Factions permanent are out of the grace period where they can be deleted.
  scope :permanent, :conditions => [
      "created_on <= NOW() - '? days'::interval", GRACE_DAYS]

  scope :orphan, :conditions => [
      "(SELECT COUNT(*)
        FROM users_skills
        WHERE role IN ('Boss', 'Underboss')
        AND role_data = factions.id::text) = 0"]

  scope :parented, :conditions => [
      "(SELECT COUNT(*)
        FROM users_skills
        WHERE role IN ('Boss', 'Underboss')
        AND role_data = factions.id::text) > 0"]

  before_destroy :set_users_faction_id_to_nil
  before_destroy :destroy_editors_too
  before_destroy :destroy_related_portals
  after_save :update_related_portal

  validates_format_of :code, :with => /^[a-z0-9]{1,7}$/
  validates_format_of :name, :with => /^[a-z0-9':[:space:]-]{1,36}$/i
  validates_uniqueness_of :code
  validates_uniqueness_of :name

  # Checks daily karma for each faction. Factions with bosses that haven't
  # generated karma for some time will receive a warning or a coup d'etat from
  # MrCheater.
  def self.check_daily_karma
    Faction.parented.permanent.find(:all, :order => "id").each do |faction|
      next if faction.boss_age_days < 14

      contents_last_two_weeks = Content.published.count(
          :conditions => ["portal_id = ? AND created_on BETWEEN ? AND ?",
                          faction.my_portal.id, 15.days.ago, 1.day.ago])

      if contents_last_two_weeks == 0
        Rails.logger.warn("Coup d'etat to '#{faction}'")
        faction.golpe_de_estado
      else
        contents_last_week = Content.published.count(
            :conditions => ["portal_id = ? AND created_on BETWEEN ? AND ?",
                            faction.my_portal.id, 7.days.ago, 1.day.ago])
        if contents_last_week == 0
          Rails.logger.warn("Sent coup d'etat warning to '#{faction}'")
          faction.send_warning_coup_detat
        end
      end
    end
  end

  def self.check_faction_leaders
    # TODO TEMP, esto no debería ser necesario
    User.db_query("update users set cache_is_faction_leader = 't' where id in (select user_id FROM users_skills WHERE role IN ('Boss', 'Underboss'));")
  end

  # Returns number of days that the current boss has been a boss.
  # If the faction has no boss an exception is raised
  def boss_age_days
    boss_roles = self._role('Boss')
    raise "Faction #{self} has no boss." unless boss_roles.size > 0
    ((Time.now - boss_roles[0].created_on) / 86400).floor
  end

  def send_warning_coup_detat
    mrcheater = User.find_by_login!("MrCheater")
    [self.boss, self.underboss].compact.each do |user|
      Notification.create({
          :sender_user_id => Ias.mrcheater.id,
          :user_id => user.id,
          :description => (
              "Peligro: Golpe de estado inminente. Han pasado muchos días sin"+
              " generarse karma en #{self.name}). Si no se genera karma en la"+
              " próxima semana perderás el control de la facción."),
      })
    end
  end

  def self.update_factions_cohesion
    Faction.find(:all, :order => 'id').each do |f|
      f.cache_member_cohesion = nil
      f.member_cohesion
      f.save
    end
  end

  def has_building?
    File.exists?(
        "#{Rails.root}/public/storage/factions/#{self.id}/building_top.png")
  end

  # TODO migrate them to files
  def building_top
    "storage/factions/#{self.id}/building_top.png"
  end

  def building_middle
    "storage/factions/#{self.id}/building_middle.png"
  end

  def building_bottom
    "storage/factions/#{self.id}/building_bottom.png"
  end

  def update_related_portal
    if self.code_changed? && self.code_was.to_s != ""
        portal = FactionsPortal.find_by_code(self.code_was)
        portal.update_attributes(:code => self.code) if portal
    end

    if self.name_changed? && self.name_was.to_s != ''
        portal = FactionsPortal.find_by_code(self.code)
        portal.update_attributes(:name => self.name) if portal
    end

    true
  end

  def my_portal
    FactionsPortal.find_by_code!(self.code)
  end

  def destroy_related_portals
    self.portals.clear
    portal = FactionsPortal.find_by_code(self.code)
    portal.destroy if portal && portal.factions.size == 0
    true
  end

  def destroy_editors_too
    UsersSkill.find(
        :all,
        :conditions => [
            "role = 'Editor'
         AND role_data LIKE E'%%faction_id: #{self.id}\\n%%'"]).each do |role|
      role.destroy
    end
    true
  end

  def moderators
    UsersSkill.find(
        :all,
        :conditions => [
              "role = 'Moderator' AND role_data = ?", self.id.to_s],
        :include => :user,
        :order => "LOWER(users.login)").collect {|ur| ur.user }
  end

  def set_users_faction_id_to_nil
    self.users.each {|u| Factions.user_joins_faction(u, nil)}
  end

  def is_moderator?(u)
    (u.has_skill?("Capo") ||
     UsersSkill.count(
        :conditions => [
            "role IN ('Boss', 'Underboss', 'Moderator')
         AND role_data = ? AND user_id = ?", self.id.to_s, u.id]) > 0)
  end

  def is_editor_of_content_type?(u, content_type)
    user_is_editor_of_content_type?(u, content_type)
  end

  def is_editor?(user)
    return true if user.has_skill?("Capo")
    if self.is_bigboss?(user)
      true
    elsif UsersSkill.count(
        :conditions => [
            "role = 'Editor'
         AND user_id = ?
         AND role_data LIKE E'%%faction_id: #{self.id}\\n%%'", user.id]) != 0
      true
    else
      false
    end
  end

  def has_boss?
    _role('Boss').size > 0
  end

  def has_underboss?
    _role('Underboss').size > 0
  end

  def is_bigboss?(u)
    u.has_skill?("Capo") || is_boss?(u) || is_underboss?(u)
  end

  def is_boss?(u)
    self.boss && self.boss.id == u.id
  end

  def is_underboss?(u)
    self.underboss && self.underboss.id == u.id
  end

  def reload(options=nil)
    super
    @_cache_boss = nil
    @_cache_underboss = nil
  end

  def boss
    @_cache_boss ||= begin
      urs = _role('Boss')
      urs.size > 0 ? urs[0].user : nil
    end
  end

  def underboss
    @_cache_underboss ||= begin
      urs = _role('Underboss')
      urs.size > 0 ? urs[0].user : nil
    end
  end

  def is_orphan?
    self.boss.nil? && self.underboss.nil?
  end

  def update_single_person_staff(newuser, role)
    urs = _role(role)
    prev = urs.size > 0 ? urs[0] : nil

    # cambia si no habia don y ahora hay, si habia y ahora no o si no es el
    # mismo.
    changed = ((newuser.nil? && prev) ||
               (newuser && prev.nil?) ||
               (newuser && prev && newuser.id != prev.user_id))
    if !changed
      Rails.logger.warn("User role didn't change, not doing anything.")
      return true
    end

    if newuser
      self.remove_boss_incompatible_user_roles(newuser)

      if newuser.faction_id != self.id
        Factions.user_joins_faction(newuser, self)
        # we need this because faction_id appears as changed and that will
        # delete permissions at the next update_attributes
        newuser = User.find(newuser.id)
      end
      ur = UsersSkill.create(
        :role => role, :role_data => self.id.to_s, :user_id => newuser.id)

      newuser.update_attributes(:cache_is_faction_leader => 't')
    end

    if prev && (newuser.nil? || (newuser && prev.user_id != newuser.id))
      prev.user.update_attributes(:cache_is_faction_leader => 'f')
      prev.destroy
    end

    dst_role_name = newuser.nil? ? 'nadie' : newuser.login
    Alert.create(
        :type_id => Alert::TYPES[:info],
        :reviewer_user_id => User.find_by_login('MrAchmed').id,
        :headline => "Actualizado #{role} de #{self.name} a #{dst_role_name}",
        :completed_on => Time.now)
  end

  def remove_boss_incompatible_user_roles(user)
    UsersSkill.find(
        :all,
        :conditions => ["role IN ('Boss', 'Underboss') AND user_id = ?",
                        user.id]).each do |ur|
        ur.destroy
        Alert.create(
          :type_id => Alert::TYPES[:info],
          :reviewer_user_id => User.find_by_login('MrAchmed').id,
          :headline => (
            "Eliminado permiso <strong>#{ur.role}</strong> de" +
            " #{Faction.find(ur.role_data.to_i).name} a #{user.login}" +
            " por hacerse boss en <strong>#{self.code}</strong>"),
            :completed_on => Time.now)
    end

  end


  def update_boss(newuser)
    @_cache_boss = nil
    self.update_single_person_staff(newuser, 'Boss')
  end

  def update_underboss(newuser)
    @_cache_underboss = nil
    self.update_single_person_staff(newuser, 'Underboss')
  end

  def _role(role)
    UsersSkill.find(
        :all,
        :conditions => ['role = ? AND role_data = ?', role, self.id.to_s],
        :include => :user)
  end

  def editors(content_type=nil)
    if content_type.nil?
      UsersSkill.find(
          :all,
          :conditions => "role = 'Editor'
                          AND role_data LIKE E'%faction_id: #{self.id}\\n%'",
          :include => :user,
          :order => 'LOWER(users.login)').collect do |ur|
        [ContentType.find(ur.role_data_yaml[:content_type_id].to_i), ur.user]
      end
    else
      UsersSkill.find(
          :all,
          :conditions => (
              "role = 'Editor'
               AND role_data LIKE E'%faction_id: #{self.id}\\n%'
               AND role_data LIKE E'%content_type_id: #{content_type.id}\\n%'"),
          :include => :user,
          :order => 'LOWER(users.login)').collect do |ur|
        ur.user
      end
    end
  end

  def add_moderator(user)
    if UsersSkill.count(
        :conditions => ["role = 'Moderator' AND user_id = ? AND role_data = ?",
                        user.id, self.id.to_s]) == 0
      ur = UsersSkill.new(
          :role => 'Moderator', :user_id => user.id, :role_data => self.id.to_s)
      ur.save
    end
  end

  def del_moderator(user)
    ur = UsersSkill.find(
        :first,
        :conditions => ["role = 'Moderator' AND user_id = ? AND role_data = ?",
                        user.id, self.id.to_s])
    ur.destroy if ur
  end

  def add_editor(user, content_type)
    if UsersSkill.count(
        :conditions => [
            "role = 'Editor'
             AND user_id = ?
             AND role_data LIKE E'%%faction_id: #{self.id}\\n%%'
             AND role_data LIKE E'%%content_type_id: #{content_type.id}\\n%%'",
             user.id]) == 0
      ur = UsersSkill.new(
          :role => 'Editor',
          :user_id => user.id,
          :role_data => {
              :faction_id => self.id,
              :content_type_id => content_type.id
          }.to_yaml)
      ur.save
    end
  end

  def del_editor(user, content_type)
    ur = UsersSkill.find(
        :first,
        :conditions => [
            "role = 'Editor'
             AND user_id = ?
             AND role_data LIKE E'%%faction_id: #{self.id}\\n%%'
             AND role_data LIKE E'%%content_type_id: #{content_type.id}\\n%%'",
            user.id])
    ur.destroy if ur
  end

  def notify_capos_on_create
    Alert.create({
        :type_id => Alert::TYPES[:info],
        :headline => (
            "Nueva facción creada <strong><a href=\"#{Routing.gmurl(self)}\">" +
            "#{self.name}</a></strong>.")
    })
  end

  def pib
    User.db_query(
        "SELECT sum(cash) FROM users WHERE faction_id = #{self.id}"
    )[0]['sum'].to_f
  end

  def to_s
    "Faction id: #{id}, name: #{name}"
  end

  def needs_you
    is_orphan?
  end

  def members
    self.users.find(:all)
  end

  def oldest_active_member
    us = User.find_by_sql("SELECT * FROM users WHERE faction_id = #{self.id} AND lastseen_on > now() - '3 months'::interval ORDER BY faction_last_changed_on ASC LIMIT 1")
    us.size > 0 ? us[0] : nil
  end

  def active_members_count
    User.count(:conditions => ['faction_id = ? AND lastseen_on > now() - \'3 months\'::interval', self.id])
  end

  def inactive_members_count
    User.count(:conditions => ['faction_id = ? AND lastseen_on <= now() - \'3 months\'::interval', self.id])
  end

  def editors_total
    UsersSkill.count(:conditions => "role = 'Moderator' AND role_data LIKE E'%%faction_id: #{self.id}\\\n%%'")
  end

  def moderators_total
    UsersSkill.count(:conditions => "role = 'Moderator AND role_data = #{self.id}'")
  end

  def referenced_thing
    Game.find_by_code(self.code) || Platform.find_by_code(self.code)
  end

  def game
    # TODO esto debería estar en el modelo
    Game.find_by_name(self.name)
  end

  def Faction.find_by_game_id(game_id)
    Faction.find(:first, :conditions => "code = (SELECT code FROM games WHERE id = #{game_id})")
  end

  def new_members_per_day
    self.db_query("SELECT COUNT(id)AS op
                                          FROM users
                                         WHERE faction_last_changed_on > now() - '1 week'::interval
                                           AND faction_id = #{self.id}")[0]['op']
  end

  def health
    self.users.count(:conditions => "lastseen_on >= now() - '3 months'::interval") / (self.members_count > 0 ? self.members_count : 1).to_f
  end


  def self.fastest_growing(limit = 3)
    stats = self.db_query("SELECT COUNT(id) AS op,
                                               faction_id
                                          FROM users
                                         WHERE faction_last_changed_on > now() - '1 week'::interval
                                           AND faction_id is not null
                                      GROUP BY faction_id
                                      ORDER BY count(id) DESC
                                         LIMIT #{limit}")
    stats2 = []

    for s in stats
      stats2<< [s['op'], Faction.find(s['faction_id'].to_i)]
    end

    stats2
  end

  def self.fastest_karma_growing
    # devuelve el top de facciones cuyo karma está creciendo más rápidamente
    stats = []
    db_query("select COALESCE(sum(karma), 0)::decimal / (select COALESCE(sum(karma),0)+50
                                                  from stats.portals
                                                 where portal_id = parent.portal_id
                                                   and created_on between now() - '2 weeks'::interval and now() - '1 week'::interval) as susum,
                     (select id
                        from factions
                       where code = (select code
                                       from portals
                                      where id = parent.portal_id)) as faction_id
                from stats.portals as parent
               where portal_id in (select id
                                     from portals
                                    where code in (select code
                                                     from factions
                                                    where created_on < now() - '2 weeks'::interval))
                 AND created_on > now() - '1 week'::interval
            group by portal_id
              having sum(karma) > 0
                 and COALESCE(sum(karma), 0) > 100
            order by susum desc
               limit 3").each do |dbf|
      stats<< [dbf['susum'].to_f, Faction.find(dbf['faction_id'].to_i)]
    end
    stats
  end

  def self.most_visited(opts={})
    opts = {:sql_interval => '1 month', :limit => 10}.merge(opts)
    stats = []
    db_query("select count(*),
                     portal_id
                FROM stats.pageviews
               WHERE created_on >= now() - '#{opts[:sql_interval]}'::interval
                 AND portal_id IN (SELECT id FROM portals WHERE type = 'FactionsPortal')
            GROUP BY portal_id
            ORDER BY count(*) desc
               LIMIT #{opts[:limit]}").each do |dbr|
      stats << [Faction.find(dbr['portal_id'].to_i), dbr['count']]
    end
    stats
  end

  def self.fastest_karma_generators
    # devuelve el top de facciones que más karma han generado en la última semana
    stats = []
    db_query("select sum(karma) as sum,
                     (select id
                        from factions
                       where code = (select code
                                       from portals
                                      where id = parent.portal_id)) as faction_id
                from stats.portals as parent
               where portal_id in (select id
                                     from portals
                                    where code in (select code
                                                     from factions
                                                    where created_on < now() - '2 weeks'::interval))
                 AND created_on > now() - '1 week'::interval
            group by portal_id
              having sum(karma) > 100
            order by sum(karma) desc
               limit 3").each do |dbf|
      stats<< [dbf['sum'].to_f, Faction.find(dbf['faction_id'].to_i)]
    end
    stats
  end

  def self.top_cohesion(limit=3)
    Faction.find(
        :all,
        :conditions => "cache_member_cohesion IS NOT NULL
                        AND cache_member_cohesion > 0",
        :order => 'cache_member_cohesion DESC',
        :limit => limit)
  end

  def building_top=(incoming_file)
    # WARNING: incoming_file.nil? es un valid upload
    if Cms::is_valid_upload(incoming_file) and incoming_file
      @temp_file_building_top = incoming_file
      @filename_building_top = incoming_file.original_filename
    end
  end

  def building_middle=(incoming_file)
    # WARNING: incoming_file.nil? es un valid upload
    if Cms::is_valid_upload(incoming_file) and incoming_file
      @temp_file_building_middle = incoming_file
      @filename_building_middle = incoming_file.original_filename
    end
  end

  def building_bottom=(incoming_file)
    # WARNING: incoming_file.nil? es un valid upload
    if Cms::is_valid_upload(incoming_file) and incoming_file
      @temp_file_building_bottom = incoming_file
      @filename_building_bottom = incoming_file.original_filename
    end
  end

  def update_img_files
    basedir = "#{Rails.root}/public/storage/factions/#{self.id}"

    if not File.exists?(basedir)
      FileUtils.mkdir_p(basedir)
    end

    for c in [
        [@temp_file_building_top, @filename_building_top, 'building_top'],
        [@temp_file_building_middle, @filename_building_middle, 'building_middle'],
        [@temp_file_building_bottom, @filename_building_bottom, 'building_bottom']]
      if c[0] and c[1] != ''
        File.open("#{basedir}/#{c[2]}.png", "wb+") do |f|
          f.write(c[0].read)
        end
        c = nil
      end
    end
  end

  def referenced_thing_field
    "#{self.referenced_thing.class.name.downcase}_id".to_sym
  end

  def single_toplevel_term
    Term.single_toplevel(self.referenced_thing_field => self.referenced_thing.id)
  end

  def karma_points
    Karma.calculate_karma_points(self)
  end

  def rank_members
    # devuelve el rango que ocupa la facción en cuanto a número de usuarios
    # registrados.
    i = 1

    for f in Faction.db_query(
        "SELECT a.id, count(b.id)
         FROM factions a
         JOIN users b ON a.id = b.faction_id
         GROUP BY a.id ORDER BY count(b.id)")
      if f['id'].to_i == self.id then
        break
      end

      i += 1
    end

    return i
  end

  def user_is_moderator(user)
    # devuelve true si el usuario puede moderar contenidos de esta facción
    if is_bigboss?(user)
      true
    else
      UsersSkill.count(
          :conditions => ["role = 'Moderator'
                           AND user_id = ?
                           AND role_data = ?", user.id, self.id.to_s]) != 0
    end
  end

  def member_cohesion
    if cache_member_cohesion.nil?
      u_ids = [0] # user_ids
      three_months_ago = 3.months.ago
      self.users.each { |u| u_ids<< u.id if u.lastseen_on >= three_months_ago }
      dbt = User.db_query(
          "SELECT count(*)
           FROM friendships
           WHERE sender_user_id IN (#{u_ids.join(',')})
           AND receiver_user_id IN (#{u_ids.join(',')})
           AND accepted_on IS NOT NULL")
      max_rels = 1
      Range.new(2, u_ids.size - 1).each { |s| max_rels += s }
      max_rels *= 2  # la amistad va en 2 direcciones
      self.cache_member_cohesion = dbt[0]['count'].to_f / (max_rels)
    end
    self.cache_member_cohesion
  end

  def user_is_banned?(user)
    !factions_banned_users.find_by_user_id(user.id).nil?
  end

  def golpe_de_estado
    mrcheater = Ias.MrCheater
    root_term = Term.single_toplevel(
        self.referenced_thing_field => self.referenced_thing.id)

    cat = root_term.children.find_by_name('General')
    if cat.nil?  # si no hay General buscamos cualquier otra
      cat = root_term.children.find(
          :first, :conditions => "taxonomy = 'TopicsCategory'")
    end

    who = self.boss ? self.boss.login : self.underboss.login
    t = Topic.create(
        :user_id => mrcheater.id,
        :title => "¡Golpe de estado! ¡Abajo #{who}!",
        :terms => cat.id,
        :main => Comments::formatize("[IMG]http://gamersmafia.com/images/golpe_de_estado.jpg[/IMG]\n[~#{who}] no es un buen líder, no presta atención a la facción y los usuarios han hablado. ¡Quieren un cambio!\n¡Por esta razón y con el poder que el poder en la sombra me ha otorgado declaro esta facción libre de boss y underboss!\n\nCualquiera que desee hacerse cargo de esta facción puede comprarla en la tienda."))

    notification_options = {
        :sender_user_id => Ias.mrcheater.id,
        :description => (
            "¡Golpe de estado en #{self.name}!
            <a href=\"#{Routing.url_for_content_onlyurl(t)}\">Más
            información</a>."),
    }

    sent_uids = []
    [self.boss, self.underboss].each do |u|
      next if u.nil?
      sent_uids << u.id
      Notification.create({:user_id => u.id}.merge(notification_options))

    end

    self.update_boss(nil)
    self.update_underboss(nil)

    self.members.each do |u|
      next if sent_uids.include?(u.id)
      Notification.create({:user_id => u.id}.merge(notification_options))
    end
  end

  def user_is_editor_of_content_type?(user, content_type)
    if user.has_any_skill?(%w(Capo Webmaster)) || self.is_bigboss?(user)
      return true
    end

    UsersSkill.count(
        :conditions => [
            "role = 'Editor'
             AND user_id = ?
             AND role_data LIKE E'%%faction_id: #{self.id}\\n%%'
             AND role_data LIKE E'%%content_type_id: #{content_type.id}\\n%%'",
            user.id]) != 0
  end

  def self.find_by_boss(u)
    ur = u.users_skills.find(:first, :conditions => 'role IN (\'Boss\')')
    Faction.find(ur.role_data.to_i) if ur
  end

  def self.find_by_moderator(u)
    u.users_skills.find(:all, :conditions => 'role = \'Moderator\'').collect { |ur| Faction.find(ur.role_data.to_i) }
  end

  def self.find_by_underboss(u)
    ur = u.users_skills.find(:first, :conditions => 'role IN (\'Underboss\')')
    Faction.find(ur.role_data.to_i) if ur
  end

  def self.find_by_bigboss(u)
    ur = u.users_skills.find(:first, :conditions => 'role IN (\'Boss\', \'Underboss\')')
    Faction.find(ur.role_data.to_i) if ur
  end

  def self.find_orphaned
    self.find(:all, :conditions => "id NOT IN (SELECT role_data::int4 FROM users_skills WHERE role IN ('Boss', 'Underboss'))", :order => 'lower(name)')
  end

  def self.count_orphaned
    self.count(:conditions => "id NOT IN (SELECT role_data::int4 FROM users_skills WHERE role IN ('Boss', 'Underboss'))")
  end

  def self.find_unorphaned
    self.find(:all, :conditions => "id IN (SELECT role_data::int4 FROM users_skills WHERE role IN ('Boss', 'Underboss'))", :order => 'lower(name)')
  end

  def self.factions_ids_with_bigbosses
    "(SELECT role_data::int4 FROM users_skills WHERE role IN ('Boss', 'Underboss'))"
  end
end
