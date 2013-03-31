# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::JuegosControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :create, :edit, :update, :destroy ]

  test "index" do
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end

  test "new" do
    get :new, {}, {:user => 1}

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:game)
  end

  test "create" do
    num_games = Game.count

    post :create, {:game => {:name => 'fooname', :code => 'foa'}}, {:user => 1}

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_equal num_games + 1, Game.count
  end

  test "edit" do
    get :edit, {:id => 1}, {:user => 1}

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:game)
    assert assigns(:game).valid?
  end

  test "update" do
    post :update, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end

  test "destroy" do
    test_create
    g = Game.find_by_code('foa')
    assert_not_nil g

    post :destroy, {:id => g.id}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      Game.find(g.id)
    }
  end

  test "create_games_mode" do
    assert_count_increases(GamesMode) do
      post :create_games_mode, {:games_mode => { :game_id => 1, :entity_type => Game::ENTITY_USER, :name => 'CTF2'}}, { :user => 1 }
      assert_redirected_to '/admin/juegos/edit/1'
    end
  end

  test "create_games_version" do
    assert_count_increases(GamesVersion) do
      post :create_games_version, {:games_version => { :game_id => 1, :version => '0.99'}}, { :user => 1 }
      assert_redirected_to '/admin/juegos/edit/1'
    end
  end

  test "destroy_games_mode" do
    test_create_games_mode
    assert_count_decreases(GamesMode) do
      post :destroy_games_mode, { :id => GamesMode.find(:first, :order => 'id DESC').id }, { :user => 1 }
      assert_redirected_to '/admin/juegos/edit/1'
    end
  end

  test "destroy_games_version" do
    test_create_games_version
    assert_count_decreases(GamesVersion) do
      post :destroy_games_version, { :id => GamesVersion.find(:first, :order => 'id DESC').id }, { :user => 1 }
      assert_redirected_to '/admin/juegos/edit/1'
    end
  end
end
