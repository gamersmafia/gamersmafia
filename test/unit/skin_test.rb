# -*- encoding : utf-8 -*-
require 'test_helper'

class SkinTest < ActiveSupport::TestCase

  # Skin default should return an special skin
  test "default_skin_is_special" do
    defskin = Skin.find_by_hid('default')
    assert_equal 'default', defskin.hid
    assert_equal 'default', defskin.name
    assert_equal -1, defskin.id
  end

  test "other_skin_is_found" do
    defskin = Skin.find_by_hid('skinguay')
    assert_equal 'skinguay', defskin.hid
    assert_equal 1, defskin.id
  end

  test "create skin should work" do
    myskin = Skin.new(:name => "mi skin", :user_id => 1)
    assert myskin.save, myskin.errors.full_messages_html
  end
end
