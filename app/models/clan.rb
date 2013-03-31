# -*- encoding : utf-8 -*-
class Clan < ActiveRecord::Base
  has_many :avatars, :dependent => :destroy
  has_many :clans_groups, :dependent => :destroy
  has_many :clans_logs_entries, :dependent => :destroy
  has_many :clans_movements, :dependent => :destroy
  has_many :clans_portals, :dependent => :destroy
  has_many :clans_sponsors, :dependent => :destroy
  has_many :recruitment_ads
  has_many :terms

  has_and_belongs_to_many :games
  file_column :logo, :format => :jpg
  file_column :competition_roster
  after_create :setup_clan
  has_bank_account

  scope :in_games,
        lambda { |games|
            game_ids = [0] + games.collect { |g| g.id }
            {:conditions => "id IN (SELECT clan_id FROM clans_games WHERE" +
                            " game_id IN (#{game_ids.join(",")}))"
            }
        }
  scope :active, :conditions => "deleted IS FALSE"

  before_save :update_rosters
  after_update :update_competition_name

  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_user_id'

  def game_ids_changed?
    @game_ids_changed || false
  end

  def mark_as_deleted
    self.members.each { |member| self.member_leave(member) }
    self.recruitment_ads.each { |rad| rad.mark_as_deleted }
    self.update_attributes(:name => "_deleted#{self.name}", :deleted => true)
  end

  def code
	  self.tag.bare
  end

  def show_logo
    if self.logo
      "/#{self.logo}"
    else
      "/images/default_avatar.jpg"
    end
  end

  def website
    if not self.website_activated then
      begin
        "http://#{self.clans_portals[0].code}.#{App.domain}"
      rescue
        "" # TODO log a warning in this case
      end
    elsif self.website_external.to_s =~ (/^http:\/\//) then
      "#{self.website_external}"
    elsif self.website_external.to_s =~ (/^www/) then
      "http://#{self.website_external}"
    else
      nil
    end
  end

  attr_accessor :game_ids_was

  def update_games(game_ids)
    @game_ids_changed = true
    self.game_ids_was = self.game_ids
    self.update_attributes(game_ids)
  end

  def update_rosters
    if self.competition_roster_changed?
      for cp in CompetitionsParticipant.find(:all, :conditions => ['competition_id IN (select id from competitions WHERE state < 4 and competitions_participants_type_id = 2) and participant_id = ?', self.id])
        cp.roster = nil
        cp.save
      end
    end
  end

  def update_competition_name
    if self.tag_changed?
      for cp in CompetitionsParticipant.find(:all, :conditions => ['competition_id IN (select id from competitions WHERE state < 4 and competitions_participants_type_id = 2) and participant_id = ?', self.id]) # TODO magic number
        cp.name = self.tag
        cp.save
      end
    end
  end
  def to_s
    name
  end

  def member_leave(user)
    for cg in self.clans_groups
      cg.users.delete(user)
    end
    user.last_clan_id = nil
    user.save
    CacheObserver.user_may_have_joined_clan(user)
    self.log("#{user} abandona el clan")
  end

  def log(msg)
    self.clans_logs_entries.create({:message => msg})
  end

  def admins
    self.clans_groups.find_by_clans_groups_type_id(
        ClansGroupsType::CLANLEADERS).users
  end

  def all_users_of_this_clan_sql
    "(SELECT user_id
        FROM clans_groups_users a
        JOIN clans_groups b
          ON a.clans_group_id = b.id
       WHERE clans_groups_type_id = 2
         AND clan_id = #{self.id}
      UNION ALL
      SELECT user_id
        FROM clans_groups_users a
        JOIN clans_groups b
          ON a.clans_group_id = b.id
       WHERE clans_groups_type_id = 1
         AND clan_id = #{self.id})"
  end

  def all_users_of_this_clan
    members + admins
  end

  def members
    self.clans_groups.find_by_clans_groups_type_id(2).users
  end

  def members_of_game(game)
    users2 = []
    for u in self.clans_groups.find_by_clans_groups_type_id(2).users
      users2<< u if u.games.find_by_id(game.id)
    end
    for u in self.clans_groups.find_by_clans_groups_type_id(1).users
      users2<< u if u.games.find_by_id(game.id)
    end
    users2.uniq || []
  end

  def self.leaded_by(user_id)
    Clan.find(:all,
              :conditions => "id in (SELECT clan_id FROM clans_groups a JOIN clans_groups_users b on a.id = b.clans_group_id WHERE a.clans_groups_type_id = (SELECT id FROM clans_groups_types WHERE name = 'clanleaders') and b.user_id = #{user_id.to_i})",
    :order => 'lower(name) ASC')
  end

  def self.related_with_user(user_id)
    Clan.find(:all,
              :conditions => "id in (SELECT clan_id
                                       FROM clans_groups a
                                       JOIN clans_groups_users b on a.id = b.clans_group_id
                                      WHERE b.user_id = #{user_id.to_i})",
              :order => 'lower(name) ASC')
  end


  def friends
    Clan.find_by_sql("SELECT *
                        FROM clans
                       WHERE id IN (SELECT to_clan_id
                                      FROM clans_friends
                                     WHERE from_clan_id = #{self.id}
                                       AND to_clan_id <> #{self.id}
                                       AND from_wants = 't'
                                 UNION ALL
                                    SELECT from_clan_id
                                      FROM clans_friends
                                     WHERE to_clan_id = #{self.id}
                                       AND from_clan_id <> #{self.id}
                                       AND to_wants = 't')
                    ORDER BY UPPER(tag) ASC")
  end



  def activate_website
    code = Cms::get_unique_portal_code(Cms::to_fqdn(self.tag))
    cp = ClansPortal.create({:name => self.name, :code => code, :clan_id => self.id})
    cs = ClansSkin.create({:name => self.name, :is_public => true, :user_id => self.admins[0].id})
    cp.skins<< cs
    cp.skin_id = cs.id
    cp.save
    all_users_of_this_clan.each do |u| CacheObserver.user_may_have_joined_clan(u) end
    self.website_activated = true
    create_contents_categories
    self.save
  end

  private
  def create_contents_categories
    root_term = Term.single_toplevel(:clan_id => self.id)
    root_term.children.create(:name => 'General', :taxonomy => 'TopicsCategory')
  end

  public
  def consider_us_friends
    Clan.find_by_sql("SELECT *
                       FROM clans
                      WHERE id IN (SELECT to_clan_id
                                     FROM clans_friends
                                    WHERE from_clan_id = #{id}
                                      AND to_clan_id <> #{id}
                                      AND to_wants = 't'
                                UNION ALL
                                   SELECT from_clan_id
                                     FROM clans_friends
                                    WHERE to_clan_id = #{id}
                                      AND from_clan_id <> #{id}
                                      AND from_wants = 't')")
  end

  def add_friend(clan)
    # TODO de-normalizar y dejarnos de paranoias

    if friends.size >= 5 or clan.id == id then
      return
    end

    dbcheck1  = db_query("SELECT from_wants
                            FROM clans_friends
                           WHERE from_clan_id = #{id}
                             AND to_clan_id   = #{clan.id}")

    if dbcheck1.size >  0 then
      if (dbcheck1[0]['from_wants'] != 't')
        db_query("UPDATE clans_friends
                      SET from_wants = 't'
                    WHERE from_clan_id = #{id}
                      AND to_clan_id = #{clan.id}");
      end
    else # check the other way around
      dbcheck2 = db_query("SELECT to_wants
                            FROM clans_friends
                           WHERE to_clan_id = #{id}
                             AND from_clan_id   = #{clan.id}")

      if (dbcheck2.size > 0) then
        if (dbcheck2[0]['to_wants'] != 't') then
          db_query("UPDATE clans_friends
                        SET to_wants = 't'
                      WHERE to_clan_id = #{id}
                        AND from_clan_id = #{clan.id}")
        end
      else # no hay relación preexistente, la creamos
        db_query(
            "INSERT INTO clans_friends (from_clan_id, to_clan_id, from_wants)
                  VALUES (#{id}, #{clan.id}, 't')")
      end
    end
    self.log("Añadido clan #{clan} a la lista de amigos")
  end

  def del_friend(clan)
    # TODO script para que limpie relaciones rotas
    db_query("UPDATE clans_friends
                  SET to_wants = 'f'
                WHERE from_clan_id = #{clan.id}
                  AND to_clan_id = #{id}")

    db_query("UPDATE clans_friends
                  SET from_wants = 'f'
                WHERE to_clan_id = #{clan.id}
                  AND from_clan_id = #{id}")

    self.log("Eliminado clan #{clan} de la lista de amigos")
  end

  def old_members_count
    # TODO cache this
    User.db_query(
        "SELECT count(distinct(user_id))
           FROM clans_groups_users a
           JOIN clans_groups b ON a.clans_group_id = b.id
            AND b.clan_id = #{self.id}")[0]['count'].to_i
  end

  def recalculate_members_count
    self.members_count = old_members_count
    save
  end

  def user_is_clanleader(user_id)
    clanleaders = ClansGroup.find(
        :first,
        :conditions => ["clan_id = ? AND clans_groups_type_id = ?",
                        self.id,
                        ClansGroupsType::CLANLEADERS])
    clanleaders.has_user(user_id)
  end

  def user_is_member(user_id)
    is_member = false
    for g in ClansGroup.find(:all, :conditions => "clan_id = #{self.id}")
      if g.has_user(user_id) then
        is_member = true
        break
      end
    end
    is_member
  end

  def add_user_to_group(user, clans_groups_type_name)
    if clans_groups_type_name == "clanleaders"
      group_type_id = ClansGroupsType::CLANLEADERS
    elsif clans_groups_type_name == "members"
      group_type_id = ClansGroupsType::MEMBERS
    else
      raise "Invalid Group Name: #{clans_groups_type_name}"
    end

    cg = ClansGroup.find(
        :first,
        :conditions => ['clan_id = ? and clans_groups_type_id = ?',
                        id, group_type_id])
    cg.users<< user
    self.log("Añadido usuario #{user} al grupo #{cg}")
    recalculate_members_count
    CacheObserver.user_may_have_joined_clan(user)
  end

  private
  def setup_clan
    # creamos grupos
    cleaders = ClansGroup.create({
        :name => "Clanleaders",
        :clans_groups_type_id => ClansGroupsType::CLANLEADERS,
        :clan_id => self.id})
    members = ClansGroup.create({
        :name => 'Miembros',
        :clans_groups_type_id => ClansGroupsType::MEMBERS,
        :clan_id => self.id})
    Term.create({
        :clan_id => self.id,
        :name => self.name,
        :slug => self.tag,
        :taxonomy => "Clan",
    })
    self.log("Clan creado")
  end

  def self.find_by_name(name)
    c = Clan.find(:first, :conditions => ['lower(name) = lower(?)', name])
    if c.nil? then
      raise ActiveRecord::RecordNotFound
    else
      c
    end
  end

  def self.hot(limit, t1, t2)
    t1, t2 = t2, t1 if t1 > t2
    # TODO PERF no podemos hacer esto, dios, hay que calcular esta info en segundo plano y solo leerla
    dbi = User.db_query("select count(distinct(visitor_id)),
                                model_id
                           from stats.pageviews
                          where controller = 'clanes'
                            and action = 'clan'
                            and created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'
                            and model_id not in (select id::varchar
                                                   from clans
                                                  where deleted = 't')
                       group by model_id
                       order by count(distinct(visitor_id)) desc
                          limit #{limit}")
    results = []
    dbi.each do |dbu|
      clan = Clan.find_by_id(dbu['model_id'].to_i)
      next unless clan
      results<< [clan, dbu['count'].to_i]
    end
    results
  end


  validates_format_of :tag,
      :with => /^[a-z0-9<>¿\?[:space:]|\]\[\(\):;^\.,_¡!\/&%"\+\-]{1,15}$/i,
      :message => ("El tag tiene más de 15 caracteres o bien tiene caracteres" +
                   " ilegales")

  validates_format_of :irc_server,
      :with => Cms::DNS_REGEXP,
      :if => Proc.new{ |c| c.irc_server.to_s != '' }

  validates_format_of :irc_channel,
      :with => /^[a-z0-9_¡!¿\?.-]{1,30}$/i,
      :if => Proc.new{ |c| c.irc_channel.to_s != '' }

  validates_format_of :website_external,
      :with => Cms::URL_REGEXP_FULL,
      :if => Proc.new{ |c| c.website_external.to_s != '' }

  validates_uniqueness_of :tag
  validates_uniqueness_of :name
end
