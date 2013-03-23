# -*- encoding : utf-8 -*-
class Skin < ActiveRecord::Base
  has_hid
  has_and_belongs_to_many :portals
  has_many :skins_files, :dependent => :destroy

  file_column :file
  serialize :skin_variables

  after_save :update_assets_file
  before_create :check_names

  scope :only_public, :conditions => "is_public = 't'", :order => 'lower(name)'

  validates_uniqueness_of :name
  validates_presence_of :user_id
  validates_presence_of :name
  belongs_to :user

  APPEND=0
  PREPPEND=1

  BUILTIN_SKINS = {
    0 => "bricks",
  }

  CGEN_CSS_START = '/* COLOR GEN START - DO NOT REMOVE */'
  CGEN_CSS_END = '/* COLOR GEN END - DO NOT REMOVE */'
  DEFAULT_SKINS_IDS  = {'default' => -1, 'arena' => -2, 'bazar' => -3}
  FAVICONS_CSS_FILENAME = (
      "#{Rails.root}/public/skins/_core/css/games_sprites.css")

  SKINS_DIR = "#{Rails.root}/public/storage/skins"

  ASSETS_BASE_DIR = "#{Rails.root}/app/assets/stylesheets/user_skins"

  SKIN_COLORS = %w(
    alt1-bg
    bad-block-bg
    bad-block-border-color
    bad-block-color
    bad-color
    bad-link-color
    blockquote-bg
    blockquote-border-color
    body-bg
    body-color
    button-border-color
    button-border-shadow-color
    button-color
    button-bg
    dropdown-color
    dropdown-bg
    dropdown-header-color
    footer-bg
    footer-border-color
    full-page-overlay-bg
    good-block-bg
    good-block-color
    good-block-border-color
    good-color
    good-link-color
    heading-color
    link-color
    link-visited-color
    link-hover-color
    page-level-content-bg
    page-level-content-color
    page-level-content-border-color
    page-level-header-bg
    percent-bar-fg
    percent-bar-bg
    percent-bar-bg-border-color
    percent-bar-twoclasses-bg
    percent-bar-twoclasses-fg
    popup-bg
    popup-color
    popup-border-color
    selected-bg
    secondary-color
    secondary-block-bg
    secondary-block-border-color
    secondary-link-hover-color
    header-bg
    header-color
    header-secondary-color
    header-secondary-bg
    subheader-bg
    subheader-color
    subheader-border-color
    submenu-bg
    submenu-color
    submenu-link-color
    topbar-bg
    topbar-color
    topbar-link-color
    topbar-notification-color
    unread-item-bg
    unread-item-color
    user-input-bg
    user-input-border-color
    user-input-color
    user-input-selected-bg
    user-input-overlay-control-bg
    user-input-overlay-control-color
  )

  def self.find_by_hid(hid)
    if %w(arena default bazar).include?(hid)
      s = Skin.new({
        :name => hid,
        :hid => hid,
        :version => AppR.ondisk_git_version,
      })
      s.id = DEFAULT_SKINS_IDS[hid]
      s
    else
      super(hid)
    end
  end

  def complete_skin_variables
    self.update_attribute('skin_variables', {}) if self.skin_variables.nil?

    out = {}
    SKIN_COLORS.each do |k|
      v = self.skin_variables[k]
      if v.to_s == ""
        v = 'none'
        Rails.logger.error("Skin #{self.id} doesn't have color key #{k}")
      end
      out[k] = v
    end
    out
  end

  # Updates the final assets file that will be rendered by the browser.
  def update_assets_file
    dst_file = "#{Skin::ASSETS_BASE_DIR}/#{self.id}.css.scss"
    out = []
    complete_skin_variables.each do |k, v|
      out.append("$#{k}: #{v};")
    end
    out.append('@import "../colors";')

    File.open(dst_file, "w") do |f|
      f.write(out.join("\n"))
    end
  end

  def check_names
    return !%w(arena bazar default).include?(self.hid)
  end

  def resolve_hid
    self.name
  end

  def used_by_users_count
    UsersPreference.count(
        :conditions => "name = 'skin' AND value = '#{YAML::dump(self.id)}'")
  end
end
