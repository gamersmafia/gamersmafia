# -*- encoding : utf-8 -*-
require 'test_helper'

class BazarDistrictTest < ActiveSupport::TestCase

  test "should_create_basic_content_categories" do
    newbd = BazarDistrict.new(:name => 'Yoga', :slug => 'yoga')
    assert newbd.save
    assert_not_nil BazarDistrictPortal.find_by_code('yoga')

    t = Term.find(
        :first,
        :conditions => ['bazar_district_id = ? AND parent_id IS NULL',
                        newbd.id])
    assert t
    assert_equal newbd.name, t.name
    assert_equal newbd.slug, t.slug
    assert t.children.count > 0
  end

  test "single_person_staff" do
    bd = BazarDistrict.find(:first)
    assert !bd.has_don?
    assert !bd.has_mano_derecha?
    bd.update_don(User.find(1))
    assert bd.has_don?
    assert_equal 1, bd.don.id
    bd.update_mano_derecha(User.find(2))
    assert bd.has_mano_derecha?
    assert_equal 2, bd.mano_derecha.id

    # test no boss de varios a la vez
    bd2 = BazarDistrict.find(:first, :conditions => ['id <> ?', bd.id])
    bd2.update_don(User.find(1))
    assert_equal 1, bd2.don.id
    bd.reload
    assert bd.has_don?
    assert_equal 2, bd.don.id

    # test update a nil
    bd2.update_don(nil)
    assert !bd2.has_don?
  end

  test "user_is_editor_if_boss" do
    bd = BazarDistrict.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !bd.user_is_editor_of_content_type?(u59, ctype)
    bd.update_don(u59)
    assert bd.user_is_editor_of_content_type?(u59, ctype)
  end

  test "user_is_editor_if_underboss" do
    bd = BazarDistrict.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !bd.user_is_editor_of_content_type?(u59, ctype)
    bd.update_mano_derecha(u59)
    assert bd.user_is_editor_of_content_type?(u59, ctype)
  end

  test "user_is_editor_if_sicario" do
    bd = BazarDistrict.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !bd.user_is_editor_of_content_type?(u59, ctype)
    bd.add_sicario(u59)
    assert bd.user_is_editor_of_content_type?(u59, ctype)
  end

  test "update_portal_favicons_should_be_executed" do
    b = BazarDistrict.first
    Skins.expects(:update_portal_favicons)
    b.save
  end
end
