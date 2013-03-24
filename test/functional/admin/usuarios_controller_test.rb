# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::UsuariosControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [
      :index,
      :destroy,
      :check_registered_on,
      :check_karma,
  ]

  test "index" do
    sym_login :superadmin
    get :index, {}
    assert_response :success
    assert_template 'index'
  end

  test "search" do
    sym_login :superadmin
    get :index, {:s => 'panzer'}
    assert_response :success
    assert_template 'index'
    assert_not_nil @response.body =~ /panzer/
  end

  test "check_registered_on" do
    sym_login 1
    post :check_registered_on, { :id => 1}
    assert_response :success
  end

  test "check_karma" do
    sym_login 1
    post :check_karma, { :id => 1}
    assert_response :success
  end

  test "check_gmf" do
    sym_login 1
    post :check_karma, { :id => 1}
    assert_response :success
  end

  test "should update banned reason" do
    sym_login 1
    assert_equal 'Desconocida', User.find(51).ban_reason
    post :update_public_ban_reason, { :id => 51, :public_ban_reason => 'feooo' }
    assert_equal 'feooo', User.find(51).ban_reason
  end

  test "del_comments_should_work" do
    sym_login :superadmin
    post :del_comments, { :comments => ['1']}
    assert Comment.find(1).deleted?
    assert_response :redirect
  end

  test "should_destroy_non_superadmin_user" do
    sym_login :superadmin
    assert_not_nil User.find_by_id(3)
    post :destroy, :id => 3
    assert_redirected_to '/admin/usuarios'
    assert_nil User.find_by_id(3)
  end

  test "should_edit_existing_user" do
    sym_login :superadmin
    get :edit, :id => 2
    assert_response :success
    assert_template 'edit'
  end

  test "should_update_existing_user" do
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    post :update, { :id => 2, :edituser => { :login => 'panzerito' } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert_equal 'panzerito', panzer.login
  end

  test "should_update_existing_user_without_changing_faction_if_nil_faction" do
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    old_faction_id = panzer.faction_id
    old_last_changed_faction = panzer.faction_last_changed_on
    post :update, { :id => 2, :edituser => { :login => 'panzerito', :faction_id => panzer.faction_id.to_s } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert_equal old_faction_id, panzer.faction_id
    assert_equal old_last_changed_faction, panzer.faction_last_changed_on
  end

  test "should_update_existing_user_without_changing_faction_if_not_nil_faction" do
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    panzer.faction_id = 1
    panzer.faction_last_changed_on = 3.months.ago
    panzer.save
    panzer.reload
    old_faction_id = panzer.faction_id
    old_last_changed_faction = panzer.faction_last_changed_on
    post :update, { :id => 2, :edituser => { :login => 'panzerito', :faction_id => panzer.faction_id.to_s } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert_equal old_faction_id, panzer.faction_id
    assert_equal old_last_changed_faction.to_i, panzer.faction_last_changed_on.to_i
  end

  test "should_update_existing_users_new_state_deleted" do
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    post :update, { :id => 2, :edituser => { :login => 'panzer', :state => User::ST_DISABLED } }
    assert_redirected_to :action => 'edit', :id => panzer.id
    panzer.reload
    assert panzer.state == User::ST_DISABLED
  end

  # TODO faltan tests de check_*
  #
  test "should_fix_gmf_ammount_if_incorrect" do
    sym_login :superadmin
    User.db_query("UPDATE users SET cash = cash + 50 WHERE login = 'panzer'")
    panzer = User.find_by_login(:panzer)
    post :check_gmf, { :id => 2 }
    assert_response :success
    assert_template 'check_gmf_fixed'
  end

  test "should_do_nothing_if_gmf_ammount_is_correct" do
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    Bank.transfer(:bank, panzer, 10, 'test')
    panzer.reload
    post :check_gmf, { :id => 2 }
    assert_response :success
    assert_template 'check_gmf_ok'
  end

  test "reset_avatar_should_reset_avatar" do
    sym_login :superadmin
    panzer = User.find_by_login(:panzer)
    panzer.avatar_id = 1
    assert_equal true, panzer.save
    post :reset_avatar, { :id => panzer.id}
    assert_redirected_to "/admin/usuarios/edit/#{panzer.id}"
    panzer.reload
    assert_equal nil, panzer.avatar_id
  end

  test "ban_should_work" do
    sym_login :superadmin
    u2 = User.find(2)
    assert_not_equal User::ST_BANNED, u2.state
    post :ban, { :id => 2 }
    u2.reload
    assert_equal User::ST_BANNED, u2.state
  end

  test "ban_request_shouldnt_work_for_normal_user" do
    assert_raises(AccessDenied) { get :ban_request }
  end

  test "ban_request_should_work_for_capo" do
    give_skill(2, "Capo")
    sym_login 2
    @u3 = User.find(3)
    get :ban_request, :login => @u3.login
    assert_response :success
  end


  test "confirmar_ban_request_should_work_for_capo" do
    give_skill(2, "Capo")
    sym_login 2
    get :confirmar_ban_request, :id => 1
    assert_response :success
  end

  test "create_ban_request_should_work_for_capo" do
    give_skill(2, "Capo")
    @u3 = User.find(3)
    sym_login 2
    assert_count_increases(UsersPreference) do
      assert_count_increases(BanRequest) do
        post :create_ban_request, {
            :login => @u3.login,
            :reason => "Reiteradas violaciones del código de conducta.",
            :public_reasons => ['Foo', 'Bar'],
        }
        assert_redirected_to "/miembros/#{@u3.login}"
      end
    end
    assert_not_nil @u3.pref_public_ban_reason == "<ul><li>Foo</li><li>Bar</li></ul>"
  end

  test "confirm_ban_request_should_work_for_capo" do
    test_create_ban_request_should_work_for_capo
    give_skill(56, "Capo")
    @u4 = User.find(56)
    sym_login @u4
    last = BanRequest.find(:first, :order => 'id desc')
    post :confirm_ban_request, {:id => last.id }
    last.reload
    assert_equal @u4.id, last.confirming_user_id
    assert_redirected_to "/alertas/capo"
  end

  test "create_unban_request_should_work_for_capo" do
    test_confirm_ban_request_should_work_for_capo
    sym_login 2
    post :create_unban_request, {:login => @u3.login, :reason_unban => "ahora es buen chico" }
    @br = BanRequest.find_by_banned_user_id(@u3.id)
    assert_equal 2, @br.unban_user_id
  end

  test "confirm_unban_request_should_work_for_capo" do
    test_create_unban_request_should_work_for_capo
    sym_login @u4.id
    post :confirm_unban_request, {:id => @br.id }
    @br.reload
    assert_equal @u4.id, @br.unban_confirming_user_id
    @u3.reload
    assert_not_equal User::ST_BANNED, @u3.state
  end

  test "cancel_ban_request_should_work_for_owner" do
    test_create_ban_request_should_work_for_capo
    last = BanRequest.find(:first, :order => 'id desc')
    assert_count_decreases(BanRequest) { post :cancel_ban_request, {:id => last.id } }
    assert_redirected_to "/site/alertas"
  end

  test "should_set_antiflood_level_if_skill" do
    @u4 = User.find(56)
    give_skill(@u4.id, "Antiflood")
    sym_login @u4
    u2 = User.find(2)
    assert_equal -1, u2.antiflood_level
    post :set_antiflood_level, {:user_id => 2, :antiflood_level => '5'}
    assert_redirected_to "/miembros/#{u2.login}"
    u2.reload
    assert_equal 5, u2.antiflood_level
  end

  test "should_not_set_antiflood_level_if_not_skill" do
    @u4 = User.find(56)
    sym_login @u4
    u2 = User.find(2)
    assert_equal -1, u2.antiflood_level
    assert_raises(AccessDenied) do
      post :set_antiflood_level, {:user_id => 2, :antiflood_level => '5'}
    end
  end

  test "should_set_antiflood_max_if_antiflood" do
    @u4 = User.find(56)
    @u4.users_skills.clear
    give_skill(@u4.id, "Antiflood")
    @u4.reload
    assert @u4.save

    sym_login @u4
    u2 = User.find(2)
    assert_equal -1, u2.antiflood_level
    assert_count_increases(Alert) do
      post :set_antiflood_level, {:user_id => 2, :antiflood_level => '5'}
    end
    assert_redirected_to "/miembros/#{u2.login}"
    u2.reload
    assert_equal 5, u2.antiflood_level
  end

  test "clear_description" do
    @u4 = User.find(56)
    give_skill(56, "Capo")
    sym_login @u4
    @u2 = User.find(2)
    @u2.description = "I rock"
    assert @u2.save
    post :clear_description, :id => @u2.id
    assert_response :redirect
    assert_redirected_to "/miembros/#{@u2.login}"
    @u2.reload
    assert_nil @u2.description
  end

  test "clear_photo" do
    give_skill(56, "Capo")
    @u4 = User.find(56)
    sym_login @u4
    @u2 = User.find(2)
    User.db_query("UPDATE users SET photo = 'asdadad' WHERE id = #{@u2.id}")
    post :clear_photo, :id => @u2.id
    assert_response :redirect
    assert_redirected_to "/miembros/#{@u2.login}"
    @u2.reload
    assert_nil @u2.photo
  end

  test "report with skill" do
    give_skill(56, "ReportUsers")
    sym_login 56
    assert_count_increases(Alert) do
      post :report, :id => User.find(:first)
    end
    assert_response :success
  end

  test "report no skill" do
    sym_login 56
    assert_raises(AccessDenied) do
      post :report, :id => User.find(:first)
    end
  end

  test "capos should be able to delete underboss roles" do
    u2 = User.find(2)
    u3 = User.find(3)
    give_skill(2, "Capo")
    u2.reload
    assert u2.has_skill_cached?("Capo")

    f1 = Faction.find(1)
    f1.update_underboss(u3)

    last_id = UsersSkill.last.id
    post :users_skill_destroy, :id => last_id
    assert_response :success
    assert_nil UsersSkill.find_by_id(last_id)
  end

  test "capos should be able to update users data" do
    u2 = User.find(2)
    u3 = User.find(3)
    give_skill(2, "Capo")
    u2.reload
    post :update, :id => u3.id, :edituser => { :email => 'foo@barbaz.com' }
    u3.reload
    assert_response :redirect
    assert_equal 'foo@barbaz.com', u3.email
  end
end
