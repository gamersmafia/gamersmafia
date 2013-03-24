# -*- encoding : utf-8 -*-
class UsersSkill < ActiveRecord::Base

  # TODO(slnc): replace ContentModerationQueue with PublishContent?
  # TODO(slnc): remove Editor, Sicario and Moderator after Dec 1st, 2012
  VALID_SKILLS = %w(
    Advertiser
    Antiflood
    Bank
    BazarManager
    Boss
    Bot
    BulkUpload
    Capo
    CompetitionAdmin
    CompetitionSupervisor
    ContentModerationQueue
    CreateEntity
    DeleteContents
    Don
    EditContents
    EditFaq
    Editor
    Gladiator
    GmShop
    GroupAdministrator
    GroupMember
    LessAds
    ManoDerecha
    MassModerateContents
    Moderator
    ProfileSignatures
    RateCommentsDown
    RateCommentsUp
    RateContents
    ReportComments
    ReportContents
    ReportUsers
    Sicario
    TagContents
    Underboss
    Webmaster
  )

  KARMA_SKILLS = {
    'Antiflood' => 8500,
    'Bank' => 35,
    'BulkUpload' => 100,
    'CreateEntity' => 1250,
    'ContentModerationQueue' => 50,
    'DeleteContents' => 10000,
    'EditContents' => 5000,
    'EditFaq' => 7000,
    'GmShop' => 25,
    'LessAds' => 500,
    'MassModerateContents' => 1000,
    'ProfileSignatures' => 20,
    'RateCommentsDown' => 250,
    'RateCommentsUp' => 10,
    'RateContents' => 15,
    'ReportComments' => 1500,
    'ReportContents' => 1750,
    'ReportUsers' => 2000,
    'TagContents' => 75,
  }

  NON_KARMA_SKILLS = [
    'BazarManager',
    'Boss',
    'Bot',
    'Capo',
    'CompetitionAdmin',
    'CompetitionSupervisor',
    'Don',
    'Gladiator',
    'ManoDerecha',
    'Moderator',
    'Sicario',
    'Underboss',
    'Webmaster',
  ]

  # role                  | role_data
  # ------------------------------------------
  # Advertiser            | advertiser_id
  # Don                   | bazar_district_id
  # ManoDerecha           | bazar_district_id
  # GroupMember           | group_id
  # GroupAdministrator    | group_id
  # Moderator             | faction_id
  # Editor                | {:content_type_id => 1, :faction_id => 2}.to_yaml
  # Boss                  | faction_id
  # Underboss             | faction_id
  # Sicario               | bazar_district_id
  # CompetitionAdmin      | competition_id
  # CompetitionSupervisor | competition_id

  SKILLS_ZOMBIES_LOSE = %w(
      Boss
      Don
      Editor
      ManoDerecha
      Moderator
      Sicario
      Underboss
  )

  validates_presence_of :role, :user_id
  validates_uniqueness_of :role, :scope => [:user_id, :role_data]

  belongs_to :user
  before_save :check_role
  before_save :toyaml_if_role_data_not_basic_type

  after_create :check_is_staff
  after_destroy :check_is_staff

  scope :special_skills,
        :conditions => ["role IN (?)", NON_KARMA_SKILLS]

  def self.give_karma_skills
    user_karma = Karma.karma_points_of_users_at_date_range(3.days.ago, Time.now)
    user_karma.each do |user_id, unused_karma|
      user = User.find(user_id.to_i)
      self.karma_skills_in_range(
          user.last_karma_skill_points + 1, user.karma_points).each do |role|
            user.users_skills.create(:role => role) if !user.has_skill_cached?(role)
          end
      user.update_column(:last_karma_skill_points, user.karma_points)
    end
  end

  def self.karma_skills_in_range(karma_start, karma_end)
    if karma_start > karma_end
      karma_start, karma_end = karma_end, karma_start
    end

    out = []
    KARMA_SKILLS.each do |name, karma|
      out.append([karma, name]) if karma >= karma_start && karma <= karma_end
    end
    # We sort the skills by increasing karma
    out.sort.collect {|skill_info| skill_info[1]}
  end

  def self.find_users_with_skill(skill_name)
    User.find(
        :all,
        :conditions => [
            "id IN (SELECT user_id FROM users_skills WHERE role = ?)",
            skill_name])
  end

  def self.kill_zombified_staff
    # bigbosses, editors, moderators and sicarios
    limit = 3.months.ago
    now = Time.now
    mrcheater = Ias.MrCheater
    UsersSkill.find(
        :all,
        :conditions => ["role IN (?)", SKILLS_ZOMBIES_LOSE],
        :include => :user).each do |ur|
      if ur.user.lastseen_on < limit
        ur.destroy
        Alert.create(
            :type_id => Alert::TYPES[:info],
            :headline => ("Quitando permiso de <strong>#{ur.role}</strong> a" +
                          " <strong>#{ur.user.login}</strong> por volverse" +
                          " zombie"),
            :reviewer_user_id => mrcheater.id,
            :completed_on => now)
      end
    end
  end


  def role_data_yaml
    YAML::load(role_data)
  end

  def role_data_yaml=(new_role_data)

  end

  def format_scope
    # cambiar tb cuenta_helper role_data
    case role
      when 'Advertiser'
      "Anunciante"
      when 'Don'
      "Don de #{BazarDistrict.find(self.role_data.to_i).name}"
      when 'ManoDerecha'
      "Mano derecha de #{BazarDistrict.find(self.role_data.to_i).name}"
      when 'Boss'
      "Boss de #{Faction.find(self.role_data.to_i).name}"
      when 'Underboss'
      "Underboss de #{Faction.find(self.role_data.to_i).name}"
      when 'Moderator'
      "Moderador de #{Faction.find(self.role_data.to_i).name}"
      when 'Sicario'
      "Sicario de #{BazarDistrict.find(self.role_data.to_i).name}"
      when 'Editor'
      "Editor de #{ContentType.find(self.role_data_yaml[:content_type_id]).name} en #{Faction.find(self.role_data_yaml[:faction_id].to_i).name}"
      when 'GroupAdministrator'
      "Administrador de #{Group.find(self.role_data.to_i).name}"
      when 'GroupMember'
      "Miembro de #{Group.find(self.role_data.to_i).name}"
      when 'CompetitionAdmin'
      "Admin de #{Competition.find(self.role_data.to_i).name}"
      when 'CompetitionSupervisor'
      "Supervisor de #{Competition.find(self.role_data.to_i).name}"
      else
        Translation.translate(role)
    end
  end

  protected
  def check_role
    if VALID_SKILLS.include?(self.role)
      true
    else
      self.errors.add("role", "Rol '#{self.role}' invalido.")
      false
    end
  end

  def toyaml_if_role_data_not_basic_type
    if !%w(NilClass String Fixnum).include?(self.role_data.class.name)
      self.role_data = self.role_data.to_yaml
    end
  end

  def check_is_staff
    if self.frozen? # quitando permiso
      if self.role == 'Don'
        bd = BazarDistrict.find(self.role_data.to_i)
        bd.update_don(bd.mano_derecha) if bd.mano_derecha
      end

      if self.role == 'Boss'
        bd = Faction.find_by_id(self.role_data.to_i)
       	# al borrar algunas facciones viejas no se borraban los roles
        bd.update_boss(bd.underboss) if bd && bd.underboss
      end
    end

    self.user.update_is_staff
  end

end
