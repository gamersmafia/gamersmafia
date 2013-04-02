# -*- encoding : utf-8 -*-
# Order matters!
%w(
   slnc_file_column
   slnc_file_column_helper
   has_hid
   has_slug
   can_have_faction
   ruby_mixings
   acts_as_categorizable
   acts_as_content
   acts_as_content_browser
   acts_as_tree
   all
   authorization
   cms
   bank
   gmstats
   formatting
   skins
   ads
   translation
   stats
   stats_mixings_ab_tests
   acts_as_rootable
   redefine_task
   staff
   crs
  ).each do |f|
  require "#{Rails.root}/lib/#{f}.rb"
end

Cms.uncompress_ckeditor_if_necessary
