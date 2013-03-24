# -*- encoding : utf-8 -*-
class BazarDistrict < ActiveRecord::Base
  ROLE_DON = 'Don'
  ROLE_MANO_DERECHA = 'ManoDerecha'

  validates_uniqueness_of :name, :slug
  validates_length_of :name, :within => 2..20
  validates_length_of :slug, :within => 2..20
  after_save :check_if_icon_updated
  after_save :rename_everything_if_name_or_slug_changed
  after_create :create_portal_and_terms
  before_create :check_can_be_created

  file_column :icon
  file_column :building_top
  file_column :building_middle
  file_column :building_bottom

  has_many :terms

  has_users_skill 'Don'
  has_users_skill 'ManoDerecha'
  has_users_skill 'Sicario'

  def top_level_category
    Term.single_toplevel(:bazar_district_id => self.id)
  end

  def code
    self.slug
  end

  def rename_everything_if_name_or_slug_changed
    if ((self.name_changed? || self.slug_changed?) &&
        self.slug_was.to_s != '')
      val = self.changed["slug"]
      field = :slug
      BazarDistrictPortal.send(
          "find_by_#{field}",(val)).update_attributes(
              :name => self.name, :code => self.slug)
      Cms::BAZAR_DISTRICTS_VALID.each do |cname|
        cls = Object.const_get(cname).category_class
        inst = cls.find(:first,
                        :conditions => ["#{field} = ?", self.send(field)])
        inst.update_attributes(:name => self.name, :slug => self.slug) if inst
      end
    end
  end

  def check_if_icon_updated
    if self.icon_changed?
      Skins.delay.update_portal_favicons
    end
    true
  end

  def _role(role)
    UsersSkill.find(
        :all,
        :conditions => ['role = ? AND role_data = ?', role, self.id.to_s],
        :include => :user)
  end

  def don
    urs = _role(ROLE_DON)
    urs.size > 0 ? urs[0].user : nil
  end

  def mano_derecha
    urs = _role(ROLE_MANO_DERECHA)
    urs.size > 0 ? urs[0].user : nil
  end

  def has_don?
    _role(ROLE_DON).size > 0
  end

  def has_mano_derecha?
    _role(ROLE_MANO_DERECHA).size > 0
  end

  def update_don(newuser)
    update_single_person_staff(newuser, ROLE_DON)
  end

  def update_mano_derecha(newuser)
    update_single_person_staff(newuser, ROLE_MANO_DERECHA)
  end

  def add_sicario(user)
    if UsersSkill.count(
        :conditions => ["role = 'Sicario' AND user_id = ? AND role_data = ?",
                        user.id, self.id.to_s]) == 0
      UsersSkill.create(
          :role => 'Sicario', :user_id => user.id, :role_data => self.id.to_s)
    end
  end

  def del_sicario(user)
    ur = UsersSkill.find(
        :first,
        :conditions => ["role = 'Sicario' AND user_id = ? AND role_data = ?",
                        user.id, self.id.to_s])
    if ur
      ur.destroy
    else
      Rails.logger.warn("No Sicario UserRole found for #{user}")
    end
  end

  def sicarios
    UsersSkill.find(
        :all,
        :conditions => ["role = 'Sicario' AND role_data = ?", self.id.to_s],
        :include => :user,
        :order => "LOWER(users.login)").collect { |ur| ur.user }
  end

  def has_building?
    self.building_top.to_s != ''
  end

  def update_single_person_staff(newuser, role)
    urs = _role(role)
    prev = urs.size > 0 ? urs[0] : nil

    # Cambia si no habia don y ahora hay, si habia y ahora no o si no es el
    # mismo.
    changed = ((newuser.nil? && prev) ||
               (newuser && prev.nil?) ||
               (newuser && prev && newuser.id != prev.user_id))
    return true unless changed

    if newuser
      # le quitamos los roles viejos como don/mano_derecha
      UsersSkill.find(
          :all,
          :conditions => ["role IN ('#{ROLE_DON}', '#{ROLE_MANO_DERECHA}')
                           AND user_id = ?", newuser.id]).each do |ur|
        ur.destroy
        Alert.create({
            :type_id => Alert::TYPES[:info],
            :reviewer_user_id => User.find_by_login('MrAchmed').id,
            :headline => (
                "Eliminado permiso <strong>#{ur.role}</strong> de" +
                " #{BazarDistrict.find(ur.role_data.to_i).name} a" +
                " #{newuser.login}"),
            :completed_on => Time.now,
        })
      end
      ur = UsersSkill.create(
          :role => role, :role_data => self.id.to_s, :user_id => newuser.id)
    end

    prev.destroy if prev

    receiver_name = newuser.nil? ? 'nadie' : newuser.login
    Alert.create({
        :type_id => Alert::TYPES[:info],
        :reviewer_user_id => User.find_by_login('MrAchmed').id,
        :headline => "Actualizado #{role} de #{self.name} a #{receiver_name}",
        :completed_on => Time.now,
    })
  end

  def user_is_editor_of_content_type?(user, content_type)
    user.has_skill_cached?("BazarManager") || self.is_sicario?(user)
  end

  def user_is_banned?(user)
    false
  end

  def user_is_moderator(u)
    # si puede moderar comentarios, vamos
    (u.has_skill_cached?("BazarManager") ||
     UsersSkill.count(
        :conditions => ["role IN ('#{ROLE_DON}',
                                  '#{ROLE_MANO_DERECHA}',
                                  'Sicario')
                         AND user_id = ?
                         AND role_data = ?", u.id, self.id.to_s]) > 0)
  end

  def is_sicario?(u)
    u.has_skill_cached?("BazarManager") || UsersSkill.count(:conditions => ["role IN ('Don', 'ManoDerecha', 'Sicario') AND role_data = ? AND user_id = ?", self.id.to_s, u.id]) > 0
  end

  def is_bigboss?(u)
    u.has_skill_cached?("BazarManager") || UsersSkill.count(:conditions => ["role IN ('Don', 'ManoDerecha') AND role_data = ? AND user_id = ?", self.id.to_s, u.id]) > 0
  end

  def self.find_by_bigboss(u)
    ur = u.users_skills.find(:first, :conditions => 'role IN (\'Don\', \'ManoDerecha\')')
    BazarDistrict.find(ur.role_data.to_i) if ur
  end

  def self.find_by_sicario(u)
    u.users_skills.find(:all, :conditions => 'role = \'Sicario\'').collect { |ur| BazarDistrict.find(ur.role_data.to_i) }
  end

  protected
  def check_can_be_created
    root_term = Term.single_toplevel(:slug => self.slug)
    if root_term
      self.errors.add("slug",
                      "Ya existe un Term con el mísmo código: #{root_term}.")
      return false
    end

    if BazarDistrictPortal.find_by_code(self.slug)
      self.errors.add("slug", "Ya existe un portal para este distrito.")
      return false
    end
    true
  end

  def create_portal_and_terms
    root_term = Term.create({
        :bazar_district_id => self.id,
        :name => self.name,
        :slug => self.slug,
        :taxonomy => "BazarDistrict",
    })

    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      term = root_term.children.create(:name => c[1], :taxonomy => c[0])
      if term.new_record?
        error = term.errors.full_messages_html
        raise "Unable to create term for new district: #{error}"
      end
    end

    BazarDistrictPortal.create(:code => self.slug, :name => self.name)
  end

  def roles_by_user
    # devuelve un hash con user id como key
    roles = {}
    UsersSkill.find(
        :all,
        :conditions => ["role IN ('#{ROLE_DON}',
                                  '#{ROLE_MANO_DERECHA}',
                                  'Sicario') AND role_data = ?",
                        self.id.to_s]).each do |ur|
      roles[ur.user_id] ||= []
      roles[ur.user_id] << ur.role
    end
    roles
  end
end
