# -*- encoding : utf-8 -*-
class Game < ActiveRecord::Base
  has_many :games_maps
  has_many :games_modes
  has_many :games_versions
  has_many :users_guids
  has_many :competitions
  belongs_to :user

  has_many :terms, :dependent => :destroy

  has_slug
  can_have_faction

  file_column :icon

  after_save :update_img_file
  after_save :update_slug_in_other_places_if_changed

  validates_format_of :name, :with => /^[a-z\/$%\+\?&~.,0-9\(\)!':[:space:]\[\]-]{1,100}$/i
  validates_uniqueness_of :name, :scope => :gaming_platform_id
  validates_presence_of :gaming_platform_id
  validates_presence_of :user_id

  ENTITY_USER = 0
  ENTITY_CLAN = 1

  def self.final_decision_made(decision)
    case decision.decision_type_class
    when "CreateGame"
      user = User.find(decision.context[:initiating_user_id] || Ias.jabba.id)
      if decision.final_decision_choice.name == Decision::BINARY_YES
        game = Game.create(decision.context[:game])
        if game.new_record?
          description = (
              "Tu solicitud para crear el juego <strong>#{game.name}</strong>
              ha sido aceptada pero han ocurrido los siguientes errores al
              intentar crear el juego: #{game.errors.full_messages_html}. Por
              favor contacta con <a href=\"/miembros/slnc\">el webmaster</a>.
              <br /><br />
              Muchas gracias y disculpa por las molestias.")
        else
          description = (
              "¡Enhorabuena! Tu <a href=\"/decisiones/#{decision.id}\">solicitud</a>
              para crear el juego <strong>#{game.name}</strong> ha sido
              aceptada.")
        end
      else  # no
        description =  (
            "Tu solicitud para crear el juego '#{decision.context[:tag_name]}'" +
            " ha sido rechazada. <a href=\"/decisiones/#{decision.id}\">Más" +
            " información</a>.")
      end
      user.notifications.create({
          :sender_user_id => Ias.mrman.id,
          :type_id => Notification::DECISION_RESULT,
          :description => description,
      })

    else
      raise ("final decision made on unknown type" +
             " (#{decision.decision_type_class})")
    end
  end

  def code
    self.slug
  end

  def faction
    Faction.find_by_code(self.slug)
  end

  def valid_guid?(guid)
    raise 'non-GUID game' unless has_guids
    guid =~ Regexp.compile(self.guid_format)
  end

  def file=(incoming_file)
    @temp_file = incoming_file
    @filename = incoming_file.original_filename if incoming_file.to_s != ''
    @content_type = incoming_file.content_type if incoming_file.to_s != ''
  end

  def portals
    [GmPortal.new] +
      FactionsPortal.find_by_sql(
          "SELECT *
          FROM portals
          WHERE id in (
            SELECT portal_id
            FROM factions_portals a
            JOIN factions b ON a.faction_id = b.id
            AND b.code = '#{self.slug}')")
  end

  def update_img_file
    if @temp_file and @filename != ''
      base_dir = "#{File.dirname(self.img_file)}"
      if not File.exists?(base_dir)
        FileUtils.mkdir_p(base_dir)
      end

      File.open(self.img_file, "wb+") do |f|
        f.write(@temp_file.read)
      end
      @temp_file = nil
    end
  end

  def has_img_file?
    File.exists?(self.img_file)
  end

  def img_file
    "#{self.select(:icon)"
  end

  # TODO tb a plataformas
  def update_slug_in_other_places_if_changed
    [:slug, :name].each do |thing|
    if self.slug_changed?
      return if self.send("#{thing}_changed?".to_sym)
      f = Faction.send("find_by_#{thing}", self.send("#{thing}_was".strip))
      f.send("#{thing}=", self.send(thing))
      f.save
      Term.find(
          :first,
          :conditions => [
              'id = root_id AND slug = ?',
              self.changed["slug"].strip]).update_attributes(:slug => self.slug)
      Content.find(:all, :conditions => ['id = ?', self.id]).each do |c|
        User.db_query("UPDATE contents SET url = nil WHERE id = #{c.id}")
      end
    end
    end
    true
  end
end
