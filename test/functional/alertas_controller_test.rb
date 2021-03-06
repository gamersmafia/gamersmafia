# -*- encoding : utf-8 -*-
require 'test_helper'

class AlertasControllerTest < ActionController::TestCase

  test "submenu shouldnt crash if 401 error" do
    assert_raises(AccessDenied) { get :index }
    exception = AccessDenied.new
    @request.remote_addr = '0.0.0.0'
    @controller.send :render_error, exception
    assert_response 401
    assert !@response.body.index("gamersmafia").nil?

    sym_login 1
    get :index
    assert_response :success
    assert_template 'alertas/webmaster'
    assert_not_nil @response.body.index('Webmaster')
  end

  test "index_should_work" do
    assert_raises(AccessDenied) { get :index }
    sym_login 1
    get :index
    assert_response :success
  end

  test "bazar_manager" do
    sym_login 2
    assert_raises(AccessDenied) { get :bazar_manager }
    give_skill(2, "BazarManager")
    @u2 = User.find(2)
    get :bazar_manager
    assert_response :success
  end

  test "capo" do
    sym_login 2
    assert_raises(AccessDenied) { get :capo }
    give_skill(2, "Capo")
    @u2 = User.find(2)
    get :capo
    assert_response :success
  end

  test "gladiador" do
    sym_login 2
    assert_raises(AccessDenied) { get :gladiador }
    give_skill(2, "Gladiator")
    @u2 = User.find(2)
    get :gladiador
    assert_response :success
  end

  test "webmaster" do
    sym_login 2
    assert_raises(AccessDenied) { get :webmaster }
    sym_login 1
    get :webmaster
    assert_response :success
  end

  test "boss" do
    sym_login 2
    assert_raises(AccessDenied) { get :faction_bigboss }
    @u2 = User.find(2)
    @f = Faction.find(1)
    @f.update_boss(@u2)
    get :faction_bigboss
    assert_response :success
  end

  test "underboss" do
    sym_login 2
    assert_raises(AccessDenied) { get :faction_bigboss }
    @u2 = User.find(2)
    @f = Faction.find(1)
    @f.update_underboss(@u2)
    get :faction_bigboss
    assert_response :success
  end

  test "editor" do
    sym_login 2
    @u2 = User.find(2)
    @u2.users_skills.clear

    assert_raises(AccessDenied) { get :editor }

    @f = Faction.find(1)
    @f.add_editor(@u2, ContentType.find(1))
    get :editor
    assert_response :success
  end

  test "moderator" do
    sym_login 2
    assert_raises(AccessDenied) { get :moderator }
    @u2 = User.find(2)
    @u2 = User.find(2)
    @f = Faction.find(1)
    @f.add_moderator(@u2)
    get :moderator
    assert_response :success
    get :index
    assert_response :success
  end

  test "don" do
    sym_login 2
    assert_raises(AccessDenied) { get :bazar_district_bigboss }
    @u2 = User.find(2)
    @bd = BazarDistrict.find(1)
    @bd.update_don(@u2)
    get :bazar_district_bigboss
    assert_response :success
  end

  test "mano_derecha" do
    sym_login 2
    assert_raises(AccessDenied) { get :bazar_district_bigboss }
    @u2 = User.find(2)
    @bd = BazarDistrict.find(1)
    @bd.update_mano_derecha(@u2)
    get :bazar_district_bigboss
    assert_response :success
  end

  test "sicario" do
    sym_login 2
    assert_raises(AccessDenied) { get :sicario }
    @u2 = User.find(2)
    @bd = BazarDistrict.find(1)
    @bd.add_sicario(@u2)
    get :sicario
    assert_response :success
  end

  test "competition_admin" do
    sym_login 2
    assert_raises(AccessDenied) { get :competition_admin }
    @u2 = User.find(2)
    c = Competition.find(:first, :conditions => 'state = 3')
    c.add_admin(@u2)
    get :competition_admin
    assert_response :success
  end

  test "competition_supervisor" do
    sym_login 2
    assert_raises(AccessDenied) { get :competition_supervisor }
    @u2 = User.find(2)
    c = Competition.find(:first, :conditions => 'state = 3')
    c.add_supervisor(@u2)
    get :competition_supervisor
    assert_response :success
  end

  def atest_alert_reviewed
    assert_raises(AccessDenied) { get :alert_reviewed, :id => 1 }

    sym_login 5
    assert_raises(AccessDenied) { get :alert_reviewed, :id => 1 }

    sym_login 1
    get :alert_reviewed, :id => 1
    assert_response :success
  end

  test "sle_assigntome_all_combinations" do
    # TODO faltan tests
    @f = Faction.find(1)
    @bd = BazarDistrict.find(1)
    @editor_scope = 1 * Alert::EDITOR_SCOPE_CONTENT_TYPE_ID_MASK + 1
    [
     [:test_sicario, :bazar_district_content_report, :@bd, :id, nil, nil],
     [:test_don, :bazar_district_content_report, :@bd, :id, nil, nil],
     [:test_bazar_manager, :bazar_district_content_report, :@bd, :id, nil, nil],

     [:test_moderator, :faction_comment_report, :@f, :id, 2, {:moderation_reason => Comment::MODERATION_REASONS_TO_SYM.keys.first}],
     [:test_boss, :faction_comment_report, :@f, :id, 2, {:moderation_reason => Comment::MODERATION_REASONS_TO_SYM.keys.first}],
     [:test_capo, :faction_comment_report, :@f, :id, 2, {:moderation_reason => Comment::MODERATION_REASONS_TO_SYM.keys.first}],


     [:test_editor, :faction_content_report, :@editor_scope, :to_i, nil, nil],
     [:test_boss, :faction_comment_report, :@f, :id, 2, {:moderation_reason => Comment::MODERATION_REASONS.keys.first}],
     [:test_capo, :faction_content_report, :@editor_scope, :to_i, nil, nil],
    ].each do |t, type_id_sym, obj, meth, entity_id, data|
      User.db_query("DELETE FROM users_skills")
      User.db_query("UPDATE users SET cache_is_faction_leader = 'f'")
      self.send t
      # @f.reload
      sle = Alert.create({
          :type_id => Alert::TYPES[type_id_sym],
          :headline => 'foo',
          :data => data,
          :entity_id => entity_id,
          :scope => instance_variable_get(obj).send(meth)
      })
      get :alert_assigntome, :id => sle.id
      assert_response :success

      get :alert_reviewed, :id => sle.id
      assert_response :success
    end
  end
end
