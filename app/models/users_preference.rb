# -*- encoding : utf-8 -*-
class UsersPreference < ActiveRecord::Base
  belongs_to :user
  DEFAULTS = {
    :comments_autoscroll => 1,
    :contact_origin => String,
    :contact_psn_id => String,
    :contact_steam => String,
    :homepage_mode => String,
    :hw_case => String,
    :hw_heatsink => String,
    :hw_keyboard => String,
    :hw_mousepad => String,
    :hw_powersupply => String,
    :hw_speakers => String,
    :hw_ssd => String,
    :looking_for => String,
    :public_ban_reason => String,
    :quicklinks => Array,
    :show_all_comments => 0,
    :suicidal_chicken => 1,
    :use_elastic_comment_editor => 1,
    :user_forums => Array,
    :hw_heatsink => String,
    :hw_ssd => String,
    :hw_powersupply => String,
    :hw_case => String,
    :hw_speakers => String,
    :hw_mousepad => String,
    :hw_keyboard => String,
    :radar_notifications => 0,
 }

  serialize :value
end
