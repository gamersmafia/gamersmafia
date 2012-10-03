# -*- encoding : utf-8 -*-
class UsersSkill < ActiveRecord::Base
  VALID_ROLES = %w(
    Advertiser
    Boss
    CompetitionAdmin
    CompetitionSupervisor
    Don
    Editor
    GroupAdministrator
    GroupMember
    ManoDerecha
    Moderator
    Sicario
    Underboss
  )

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

  validates_presence_of :role, :user_id
  validates_uniqueness_of :role, :scope => [:user_id, :role_data]

  belongs_to :user
  before_save :check_role
  before_save :toyaml_if_role_data_not_basic_type

  after_create :check_is_staff
  after_destroy :check_is_staff

  def self.kill_zombified_staff
    # bigbosses, editors, moderators and sicarios
    limit = 3.months.ago
    now = Time.now
    mrcheater = Ias.MrCheater
    UsersSkill.find(:all, :conditions => "role IN ('Don', 'ManoDerecha', 'Boss', 'Underboss', 'Editor', 'Moderator', 'Sicario')", :include => :user).each do |ur|
      if ur.user.lastseen_on < limit
        ur.destroy
        Alert.create(:type_id => Alert::TYPES[:info], :headline => "Quitando permiso de <strong>#{ur.role}</strong> a <strong>#{ur.user.login}</strong> por volverse zombie", :reviewer_user_id => mrcheater.id, :completed_on => now)
      end
    end
  end


  def role_data_yaml
    YAML::load(role_data)
  end

  def role_data_yaml=(new_role_data)

  end

  protected
  def check_role
    if VALID_ROLES.include?(self.role)
      true
    else
      self.errors.add("role", "Rol '#{self.role}' invalido.")
      false
    end
  end

  def toyaml_if_role_data_not_basic_type
    self.role_data = self.role_data.to_yaml unless %w(NilClass String Fixnum).include?(self.role_data.class.name)
  end

  def check_is_staff
    nagato = Ias.nagato
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

      Message.create(
          :title => "Permiso de #{format_scope} eliminado",
          :message => "Ya no tienes permisos de #{format_scope}",
          :user_id_from => nagato.id,
          :user_id_to => self.user_id) if bd
    else
      if (self.role == 'Boss' || self.role == 'Underboss')
      Message.create(
          :title => "Recibido permiso de #{format_scope}",
          :message => "Acabas de recibir permisos de #{format_scope}."+
                      " Si tienes alguna duda sobre "+
                      "cómo administrar la facción, puedes "+
                      "echarle un vistazo al tutorial "+
                      "[url=/tutoriales/show/1611]cómo administrar tu facción[/url].",
          :user_id_from => nagato.id,
          :user_id_to => self.user_id)

      elsif (self.role == 'Don' || self.role == 'ManoDerecha')
      Message.create(
          :title => "Recibido permiso de #{format_scope}",
          :message => "Acabas de recibir permisos de #{format_scope}."+
                      " Si tienes alguna duda sobre "+
                      "cómo administrar el distrito, puedes "+
                      "echarle un vistazo al tutorial "+
                      "[url=/tutoriales/show/1609]cómo administrar tu distrito[/url].",
          :user_id_from => nagato.id,
          :user_id_to => self.user_id)
      else
      Message.create(
          :title => "Recibido permiso de #{format_scope}",
          :message => "Acabas de recibir permisos de #{format_scope}",
          :user_id_from => nagato.id,
          :user_id_to => self.user_id)
      end
  end


    self.user.update_is_staff
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
    end
  end
end
