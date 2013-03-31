# -*- encoding : utf-8 -*-
require 'test_helper'

class FactionTest < ActiveSupport::TestCase
  test "has_building should work" do
    f1 = Faction.find(1)
    touch_bldg_file = (
        "touch #{Rails.root}/public/storage/factions/#{f1.id}/building_top.png")
    system(touch_bldg_file) unless File.exists?(touch_bldg_file)
    assert f1.has_building?
  end

  test "should update related portal" do
    f1 = Faction.find(1)
    fp1 = FactionsPortal.find_by_code(f1.code)
    assert f1.update_attributes(:code => 'lolii')
    fp1.reload
    assert_equal 'lolii', fp1.code

    assert f1.update_attributes(:name => 'macguire')
    fp1.reload
    assert_equal 'macguire', fp1.name
  end

  test "find_by_bigboss" do
    f1 = Faction.find(1)
    u1 = User.find(1)
    f1.update_boss(u1)
    assert_equal 1, Faction.find_by_bigboss(u1).id
    u1 = User.find(1)
    f1.update_boss(nil)
    f1.update_underboss(u1)
    assert_equal 1, u1.faction_id
    assert_equal 1, Faction.find_by_bigboss(u1).id
  end

  test "destroy_faction_should_destroy_related_factions_portals" do
    f1 = Faction.find(1)
    faction_portal = f1.portals.find(1)
    assert_not_nil faction_portal
    f1.destroy
    assert Faction.find_by_id(f1.id).nil?
    assert FactionsPortal.find_by_id(faction_portal.id).nil?
  end

  test "faction_editors" do
    f1 = Faction.find(1)
    assert_equal [], f1.editors
  end

  test "create_should_create_alert" do
    assert_count_increases(Alert) do
      f = Faction.new({:code => "oo-1", :name => "Oinoiroko 1"})
      assert f.save, f.errors.full_messages_html
    end
  end

  test "update_boss_shouldnt_touch_faction_last_changed_on_if_already_member" do
    f1 = Faction.find(1)
    f1.members.clear
    u2 = User.find(2)
    Factions.user_joins_faction(u2, f1.id)
    assert u2.update_attributes(:faction_last_changed_on => 1.year.ago)
    f1.update_boss(u2)
    u2.reload
    assert u2.faction_last_changed_on < 1.day.ago
  end

  test "golpe_de_estado_should_work" do
    f1 = Faction.find(1)
    f1.members.clear
    assert f1.update_boss(User.find(2))
    f1.update_underboss(nil)
    Factions.user_joins_faction(User.find(3), f1.id)

    m = Notification.count
    tgen = Term.single_toplevel(:slug => f1.code).children.find(
        :first,
        :conditions => ["taxonomy = 'TopicsCategory' AND name = 'General'"])
    topics_count = tgen.contents_count(:cls_name => 'Topic')
    assert_count_increases(Topic) do
      f1.golpe_de_estado
    end
    assert_equal topics_count + 1, tgen.contents_count(:cls_name => 'Topic')
    assert Notification.count > m

    f1.reload
    assert_nil f1.boss
  end

  test "user_is_editor_if_editor" do
    f1 = Faction.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !f1.user_is_editor_of_content_type?(u59, ctype)
    f1.add_editor(u59, ctype)
    assert f1.user_is_editor_of_content_type?(u59, ctype)
  end

  test "user_is_editor_if_boss" do
    f1 = Faction.find(1)
    ctype = ContentType.find(:first)
    assert !f1.user_is_editor_of_content_type?(User.find(59), ctype)
    assert f1.update_boss(User.find(59))
    assert f1.user_is_editor_of_content_type?(User.find(59), ctype)
  end

  test "user_is_editor_if_underboss" do
    f1 = Faction.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !f1.user_is_editor_of_content_type?(u59, ctype)
    assert f1.update_boss(u59)
    assert f1.user_is_editor_of_content_type?(u59, ctype)
  end

  test "proper_boss" do
    f1 = Faction.find(1)
    u59 = User.find(59)
    assert f1.update_boss(u59)
    f1.reload
    assert_equal 59, f1.boss.id
  end

  test "karma_points_should_work_correctly" do
    f1 = Faction.find(1)
    assert_equal 41, f1.karma_points
  end

  test "check_daily_karma smoke test" do
    Faction.find(1)
    Faction.check_daily_karma
  end

  def setup_faction_with_boss(boss_age_days=0)
    faction = Faction.find(1)
    boss_user = User.find(1)
    faction.update_boss(boss_user)
    assert_equal boss_user, faction.boss
    if boss_age_days > 0
      boss_skill = boss_user.users_skills.find(
          :first, :conditions => "role = 'Boss'")
      boss_skill.update_attribute(:created_on, boss_age_days.days.ago)
    end
    [faction, boss_user]
  end

  test "check_daily_karma young boss" do
    faction, boss_user = self.setup_faction_with_boss
    User.db_query(
        "UPDATE contents
            SET portal_id = -1
          WHERE portal_id = #{faction.my_portal.id}")
    Faction.check_daily_karma
    faction.reload
    assert_equal boss_user, faction.boss
  end

  test "check_daily_karma not young boss" do
    faction, boss_user = self.setup_faction_with_boss(15)
    User.db_query(
        "UPDATE contents
            SET portal_id = -1
          WHERE portal_id = #{faction.my_portal.id}")
    Faction.check_daily_karma
    faction.reload
    assert_nil faction.boss
  end

  test "check_daily_karma faction generated karma" do
    faction, boss_user = self.setup_faction_with_boss(15)
    User.db_query(
        "UPDATE contents SET created_on = now() - '3 days'::interval")
    Faction.check_daily_karma
    faction.reload
    assert_equal boss_user, faction.boss
  end

  test "check_daily_karma faction generated karma but not last week" do
    faction, boss_user = self.setup_faction_with_boss(15)
    User.db_query("UPDATE contents SET created_on = now() - '9 days'::interval")
    assert_difference("boss_user.notifications.count") do
      Faction.check_daily_karma
    end
    faction.reload
    assert_equal boss_user, faction.boss
  end
end
