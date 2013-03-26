# -*- encoding : utf-8 -*-
require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  test "index" do
    sym_login 1
    get :index, {}
    assert_response :success
  end

  test "show" do
    get :show, :id => 1
    assert_response :success
  end

  test "new" do
    get :new, {}, {:user => 1}

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:game)
  end

  test "create" do
    num_games = Game.count

    sym_login 1
    assert_difference("Decision.count") do
      post :create, {
        :game => {
          :name => 'fooname',
          :gaming_platform_id => 1,
        },
      }
    end

    assert_response :redirect
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

  test "create_games_mode" do
    assert_count_increases(GamesMode) do
      post :create_games_mode, {:games_mode => { :game_id => 1, :entity_type => Game::ENTITY_USER, :name => 'CTF2'}}, { :user => 1 }
      assert_redirected_to '/juegos/1/edit'
    end
  end

  test "create_games_version" do
    assert_count_increases(GamesVersion) do
      post :create_games_version, {:games_version => { :game_id => 1, :version => '0.99'}}, { :user => 1 }
      assert_redirected_to '/juegos/1/edit'
    end
  end

  test "destroy_games_mode" do
    test_create_games_mode
    assert_count_decreases(GamesMode) do
      post :destroy_games_mode, { :id => GamesMode.find(:first, :order => 'id DESC').id }, { :user => 1 }
      assert_redirected_to '/juegos/1/edit'
    end
  end

  test "destroy_games_version" do
    test_create_games_version
    assert_count_decreases(GamesVersion) do
      post :destroy_games_version, { :id => GamesVersion.find(:first, :order => 'id DESC').id }, { :user => 1 }
      assert_redirected_to '/juegos/1/edit'
    end
  end

  test "create_gaming_platform unauthorized" do
    assert_raises(AccessDenied) do
      post :create_gaming_platform, {
          :gaming_platform => { :name => "Una Plataforma" }
      }
    end
  end

  test "create_gaming_platform" do
    sym_login 1
    assert_count_increases(Decision) do
      post :create_gaming_platform, {
          :gaming_platform => { :name => "Una Plataforma" }
      }
      assert_redirected_to '/juegos'
    end
  end
end
