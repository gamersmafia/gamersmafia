# -*- encoding : utf-8 -*-
require 'test_helper'

class GameTest < ActiveSupport::TestCase

  def setup
    @game = Game.find(1)
  end

  test "should_not_create_if_missing_fields" do
    c = Game.count
    g = Game.new({:name => 'foo'})
    assert_equal false, g.save

    g = Game.new({:slug => 'foo'})
    assert_equal false, g.save

    g = Game.new()
    assert_equal false, g.save

    assert_equal c, Game.count
  end

  test "should_create_if_everything_ok" do
    @g = Game.new({
        :name => 'Worms',
        :slug => 'w',
        :gaming_platform_id => 1,
        :user_id => 1,
    })
    assert_equal true, @g.save, @g.errors.full_messages_html
    assert_not_nil Game.find_by_name('Worms')
    assert_not_nil Game.find_by_slug('w')
  end

  test "should_not_create_if_duplicated_name_or_slug" do
    test_should_create_if_everything_ok
    g2 = Game.new({
      :name => 'Worms',
      :slug => 'w',
      :gaming_platform_id => 1,
      :user_id => 1,
    })
    assert_equal false, g2.save
    assert_not_nil g2.errors[:name]
    assert_not_nil g2.errors[:slug]
  end

  test "should_not_create_if_invalid_chars_in_name_or_slug" do
    g = Game.new({:name => 'Battlefield Vietnäm', :slug => 'Bf: 2'})
    assert_equal false, g.save
    assert_not_nil g.errors[:slug]
    assert_not_nil g.errors[:name]
  end

  test "should_create_faction_if_everything_ok" do
    test_should_create_if_everything_ok
    @g.create_contents_categories
    assert_not_nil Faction.find_by_code(@g.slug)
    assert_not_nil Faction.find_by_name(@g.name)
  end

  test "should_create_contents_categories_if_everything_ok" do
    test_should_create_if_everything_ok
    @g.create_contents_categories
    root_term = Term.single_toplevel(:game_id => @g.id)
    assert_not_nil root_term
    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      assert_not_nil root_term.children.find(:first, :conditions => ['taxonomy = ? AND name = ?', c[0], c[1]])
    end
  end

  test "should_create_portal_if_everything_ok" do
    test_should_create_if_everything_ok
    @g.create_faction
    p = Portal.find(:first, :conditions => ['name = ? and code = ?', @g.name, @g.slug])
    f = Faction.find(:first, :conditions => ['name = ? and code = ?', @g.name, @g.slug])
    assert_not_nil p
    assert_equal 1, p.factions.size
    assert_equal p.factions[0].id, f.id
  end
end
