require 'test_helper'

class DecisionsControllerTest < ActionController::TestCase
  test "index logged in" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "index not logged in" do
    get :index
    assert_response :success
  end

  test "show" do
    sym_login 1
    get :show, :id => Decision.first.id
    assert_response :success
  end

  test "make_decision if initiating_user_id" do
    User.db_query("DELETE FROM decision_user_choices")

    d6 = Decision.find(6)
    winner = d6.decision_choices.last
    d6.update_pending_decisions_indicators

    u5 = User.find(5)
    assert !u5.pending_decisions

    sym_login u5.id
    assert_raises(AccessDenied) do
      post :make_decision, {
        :id => Decision.first.id,
        :final_decision_choice => winner.id,
      }
    end
  end

  test "make_decision" do
    User.db_query("DELETE FROM decision_user_choices")
    give_skill(2, "CreateEntity")
    d6 = Decision.find(6)
    d6.update_pending_decisions_indicators

    u2 = User.find(2)
    assert u2.pending_decisions

    sym_login u2.id
    winner = d6.decision_choices.last
    post :make_decision, {
      :id => Decision.first.id,
      :final_decision_choice => winner.id,
    }
    assert_response :success
    u2.reload
    assert_equal(
        winner.id,
        u2.decision_user_choices.find_by_decision_id(d6.id).decision_choice_id)
    assert !u2.pending_decisions
  end

  test "ranking nonexisting" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :ranking, :id => "foo"
    end
  end

  test "ranking existing" do
    get :ranking, :id => Decision.first.decision_type_class
    assert_response :success
  end
end
