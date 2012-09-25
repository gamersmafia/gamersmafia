# -*- encoding : utf-8 -*-
class UsersPreference < ActiveRecord::Base
  belongs_to :user
  DEFAULTS = {
    :comments_autoscroll => 1,
    :looking_for => String,
    :public_ban_reason => String,
    :quicklinks => Array,
    :show_all_comments => 0,
    :use_elastic_comment_editor => 1,
    :user_forums => Array,
    :hw_heatsink => String,
    :hw_ssd => String,
    :hw_powersupply => String,
    :hw_case => String,
    :hw_speakers => String,
    :hw_mousepad => String,
    :hw_keyboard => String,
 }

  serialize :value
end
