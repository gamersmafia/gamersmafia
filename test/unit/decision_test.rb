require 'test_helper'

class DecisionTest < ActiveSupport::TestCase

  test "constants match" do
    self.assert_equal(
        Decision::DECISION_TYPE_CLASS_SKILLS.keys.sort,
        Decision::DECISION_TYPE_CHOICES.keys.sort)
  end

  test "choice_type_name" do
    Decision.first.choice_type_name
  end

  test "decision_description" do
    Decision.first.decision_description
  end

  test "completion_ratio" do
    assert_equal 1, Decision.first.completion_ratio
  end

  test "decision_binary" do
    Decision.first.binary?
  end

  test "try_to_make_decision" do
    decision = Decision.find(6)
    assert_difference("Term.count") do
      decision.try_to_make_decision
    end
    assert_equal Decision::DECIDED, decision.state
    assert_equal 7, decision.final_decision_choice_id
  end

  test "update_pending_decisions_indicators" do
    User.db_query("DELETE FROM decision_user_choices")
    u2 = User.find(2)
    give_skill(u2, "CreateEntity")
    u5 = User.find(5)

    Decision.update_pending_decisions_indicators

    # No because no skill
    assert !User.find(61).pending_decisions
    # No because he is the initiating_user_id
    assert !User.find(5).pending_decisions
    # Yes because skill and not the initiating_user_id
    u2.reload
    assert u2.pending_decisions
  end

  test "has_pending_decisions when no choices left" do
    u2 = User.find(2)
    give_skill(u2, "CreateEntity")
    assert !Decision.has_pending_decisions(u2)
  end

  test "has_pending_decisions when choices left" do
    u2 = User.find(2)
    User.db_query("DELETE from decision_user_choices")
    u2.decision_user_choices.destroy
    give_skill(u2, "CreateEntity")
    assert Decision.has_pending_decisions(u2)
  end

  test "pending_decisions_indicators when already decided" do
    u2 = User.find(2)
    User.db_query("DELETE from decision_user_choices")
    u2.decision_user_choices.destroy
    give_skill(u2, "CreateEntity")
    d1 = Decision.first
    d1.update_attribute(:state, Decision::DECIDED)
    assert !d1.pending_decisions_indicators.fetch(u2.id)
  end

  test "update_pending_decisions_indicators for decision" do
    User.db_query("DELETE FROM decision_user_choices")
    u2 = User.find(2)
    u2.users_skills.create(:role => "CreateEntity")
    d6 = Decision.find(6)

    d6.update_pending_decisions_indicators

    u2.reload

    # No because no skill
    assert !User.find(61).pending_decisions
    # No because he is the initiating_user_id
    assert !User.find(5).pending_decisions
    # Yes because skill and not the initiating_user_id
    assert u2.pending_decisions

    a_choice = d6.decision_choices.first
    assert_difference("DecisionUserChoice.count") do
      d6.decision_user_choices.create({
        :decision_choice_id => a_choice.id,
        :user_id => u2.id,
      })
    end
    u2.reload
    assert !u2.pending_decisions
  end

  test "has_pending_decisions when initiating" do
    assert !Decision.has_pending_decisions(User.find(5))
  end
end
