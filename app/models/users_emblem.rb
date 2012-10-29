# -*- encoding : utf-8 -*-
class UsersEmblem < ActiveRecord::Base
  T_COMMENTS_COUNT_1 = 10
  T_COMMENTS_COUNT_2 = 500
  T_COMMENTS_COUNT_3 = 7500
  T_THE_BEAST_KARMA_POINTS = 100000
  T_COMMENT_VALORATIONS_1 = 1
  T_COMMENT_VALORATIONS_2 = 100
  T_COMMENT_VALORATIONS_2_MATCHING_USERS = 7
  T_COMMENT_VALORATIONS_3 = 5000
  T_COMMENT_VALORATIONS_3_MATCHING_USERS = 10
  T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_1 = 50
  T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1 = 10
  T_COMMENT_VALORATIONS_RECEIVED_USERS_1 = 5
  T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_2 = 500
  T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2 = 100
  T_COMMENT_VALORATIONS_RECEIVED_USERS_2 = 50
  T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_3 = 5000
  T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3 = 100
  T_COMMENT_VALORATIONS_RECEIVED_USERS_3 = 200
  T_REFERER_1 = 1
  T_REFERER_2 = 25
  T_REFERER_3 = 100
  T_KARMA_RAGE_1 = 7
  T_KARMA_RAGE_2 = 30
  T_KARMA_RAGE_3 = 90
  T_ROCKEFELLER = 1000000
  T_SUV_MIN_KARMA_POINTS = 5

  FREQ_NAME = {
      "common" => "común",
      "legendary" => "legendario",
      "rare" => "raro",
      "special" => "especial",
      "unfrequent" => "poco frecuente",
  }

  SORTED_DECREASE_FREQUENCIES = %w(
      common
      unfrequent
      rare
      legendary
      special
  )

  EMBLEMS_INFO = {
      "comments_count_1" => {
          :frequency => "common",
          :name => "Hablador",
          :description => (
              "#{T_COMMENTS_COUNT_1} comentarios visibles."),
      },

      "comments_count_2" => {
          :frequency => "unfrequent",
          :name => "Parlanchín",
          :description => (
              "#{T_COMMENTS_COUNT_2} comentarios visibles por defecto."),
      },

      "comments_count_3" => {
          :frequency => "rare",
          :name => "Gran Orador",
          :description => (
              "#{T_COMMENTS_COUNT_3} comentarios visibles por defecto."),
      },

      "comments_valorations_1" => {
          :frequency => "common",
          :name => "Asertivo",
          :description => "#{T_COMMENT_VALORATIONS_1} comentario valorado.",
      },

      "comments_valorations_2" => {
          :frequency => "unfrequent",
          :name => "Sentencioso",
          :description => (
              "#{T_COMMENT_VALORATIONS_2} comentarios valorados en comentarios" +
              " con al menos #{T_COMMENT_VALORATIONS_2_MATCHING_USERS}" +
              " valoraciones."),
      },

      "comments_valorations_3" => {
          :frequency => "rare",
          :name => "Dogmático",
          :description => (
              "#{T_COMMENT_VALORATIONS_3} comentarios valorados en comentarios" +
              " con al menos #{T_COMMENT_VALORATIONS_3_MATCHING_USERS}" +
              " valoraciones."),
      },

      "comments_valorations_received_informativo_1" => {
          :frequency => "common",
          :name => "Clippy",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_1} valoraciones de" +
              " informativo recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_informativo_2" => {
          :frequency => "unfrequent",
          :name => "Wikipedia",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_2} valoraciones de" +
              " informativo recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_informativo_3" => {
          :frequency => "rare",
          :name => "Guía Galáctico",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_3} valoraciones de" +
              " informativo recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_profundo_1" => {
          :frequency => "common",
          :name => "Galletita China",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_1} valoraciones de" +
              " profundo recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_profundo_2" => {
          :frequency => "unfrequent",
          :name => "Meditador",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_2} valoraciones de" +
              " profundo recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_profundo_3" => {
          :frequency => "rare",
          :name => "Yoda",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_3} valoraciones de" +
              " profundo recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_divertido_1" => {
          :frequency => "common",
          :name => "Gracioso",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_1} valoraciones de" +
              " divertido recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_divertido_2" => {
          :frequency => "unfrequent",
          :name => "Cómico",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_2} valoraciones de" +
              " divertido recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_divertido_3" => {
          :frequency => "rare",
          :name => "Cachondo Mental",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_3} valoraciones de" +
              " divertido recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_interesante_1" => {
          :frequency => "common",
          :name => "Informe Semanal",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_1} valoraciones de" +
              " interesante recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_1}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_interesante_2" => {
          :frequency => "unfrequent",
          :name => "Expediente X",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_2} valoraciones de" +
              " interesante recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_2}" +
              " usuarios diferentes."),
      },

      "comments_valorations_received_interesante_3" => {
          :frequency => "rare",
          :name => "G-Man",
          :description => (
              "#{T_COMMENT_VALORATIONS_RECEIVED_VALORATIONS_3} valoraciones de" +
              " interesante recibidas por #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " comentarios y #{T_COMMENT_VALORATIONS_RECEIVED_COMMENTS_3}" +
              " usuarios diferentes."),
      },

      "first_content" => {
          :frequency => "common",
          :name => "Periodista",
          :description => "Primer contenido publicado.",
      },

      "suv" => {
          :frequency => "unfrequent",
          :name => "Todoterreno",
          :description => (
              "Un contenido de cada tipo publicado con al menos" +
              " #{T_SUV_MIN_KARMA_POINTS}."),
      },

      "karma_rage_1" => {
          :frequency => "common",
          :name => "Furia asesina",
          :description => (
              "#{T_KARMA_RAGE_1} días seguidos generando karma."),
      },

      "karma_rage_2" => {
          :frequency => "unfrequent",
          :name => "Imparable",
          :description => (
              "#{T_KARMA_RAGE_2} días seguidos generando karma."),
      },

      "karma_rage_3" => {
          :frequency => "rare",
          :name => "Godlike",
          :description => (
              "#{T_KARMA_RAGE_3} días seguidos generando karma."),
      },

      "rockefeller" => {
          :frequency => "legendary",
          :name => "Rockefeller",
          :description => (
              "#{T_ROCKEFELLER} gamersmafios ganados por méritos propios."),
      },

      "the_beast" => {
          :frequency => "legendary",
          :name => "La Bestia",
          :description => "#{T_THE_BEAST_KARMA_POINTS} puntos de karma.",
      },

      "user_referer_1" => {
          :frequency => "common",
          :name => "Puerta",
          :description => (
              "#{T_REFERER_1} usuario referido activo durante al menos el" +
               " primer mes."),
      },

      "user_referer_2" => {
          :frequency => "unfrequent",
          :name => "Sacerdote",
          :description => (
              "#{T_REFERER_2} usuarios referidos activos durante al menos el" +
               " primer mes."),
      },

      "user_referer_3" => {
          :frequency => "rare",
          :name => "Espagueti Volador",
          :description => (
              "#{T_REFERER_3} usuarios referidos activos durante al menos el" +
              " primer mes."),
      },
  }


  VALID_EMBLEMS = EMBLEMS_INFO.keys

  before_save :check_valid_emblem
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :emblem
  validates_uniqueness_of :emblem, :scope => :user_id

  after_create :reset_user_mask
  after_destroy :reset_user_mask

  scope :emblem,
        lambda {|emblem|
            {:conditions => ["emblem = ?", emblem]}
        }

  def self.inline_html_from_info(info)
    "<div class=\"emblem sprite1 #{info[:frequency]}\">
       <div class=\"name\" title=\"#{info[:description]}\">#{info[:name]}</div>
    </div>"
  end

  def reset_user_mask
    self.user.emblems_mask = nil
    self.user.emblems_mask_or_calculate
  end

  def name
    EMBLEMS_INFO[self.emblem][:name]
  end

  def frequency
    EMBLEMS_INFO[self.emblem][:frequency]
  end

  def inline_html
    UsersEmblem.inline_html_from_info(EMBLEMS_INFO[self.emblem])
  end

  protected
  def check_valid_emblem
    VALID_EMBLEMS.include?(self.emblem)
  end
end
