class DecisionUserReputation < ActiveRecord::Base
  belongs_to :user

  MIN_CHOICES_FOR_100 = 10

  def self.recalculate_all_user_reputations
    Decision::DECISION_TYPE_CLASS_SKILLS.keys.each do |decision_type|
      # DO NOT SUBMIT
      User.find(
          :all,
          :conditions => "id IN
            (SELECT distinct(user_id)
              FROM decision_user_choices a
              JOIN decisions b on a.decision_id = b.id
              WHERE b.decision_type_class = '#{decision_type}')").each do |u|
        self.get_user_probability_for(u, decision_type, true)
      end
    end
  end

  def self.get_user_probability_for(
      user, decision_type_class, force_recompute=false)
    reputation = user.decision_user_reputations.find_by_decision_type_class(
        decision_type_class)
    if reputation.nil?
      reputation = DecisionUserReputation.create({
        :user_id => user.id,
        :decision_type_class => decision_type_class,
        :probability_right => 0,
      })
    elsif reputation.updated_on <= 1.week.ago || force_recompute
      reputation.update_probability_right
    end
    # DO NOT SUBMIT fix this
    reputation.probability_right < 0 ? 0 : reputation.probability_right
  end

  def update_probability_right
    total_choices = self.user.decision_user_choices.recent.count(
        :conditions => [
          "decisions.decision_type_class = ?
           AND decisions.state = #{Decision::DECIDED}",
          self.decision_type_class], :include => :decision)

    right_choices = self.user.decision_user_choices.recent.count(
        :conditions => [
          "decisions.decision_type_class = ?
           AND decision_choice_id IN (
             SELECT final_decision_choice_id
             FROM decisions
             WHERE created_on >= now() - '6 months'::interval)
             AND decisions.state = #{Decision::DECIDED}",
          self.decision_type_class],
        :include => :decision)

    # The weight of a user's decision is a weighted probability that the user is
    # right. However instead of just counting good/bad decisions we give more
    # weight to failures than to successes. For every mistake the user has to do
    # 3 right choices before regaining his original weight.
    num_good = right_choices
    num_bad = total_choices - right_choices
    w_good = 1.0
    w_bad = 3.0
    prob_g = (num_good * w_good) / [num_good * w_good + num_bad * w_bad, 1].max

    # We now have a probability of a user being right given the weighted ratio
    # of good and bad. However for users with too few choices we still don't
    # have enough info and therefore we put an artificial burden on the ratio.
    if total_choices < MIN_CHOICES_FOR_100
      prob_g *= (total_choices.to_f / MIN_CHOICES_FOR_100)
    end

    # We give the webmaster and capos 100% probability of being right to seed
    # the system.
    prob_g = 1.0 if user.has_any_skill?(%w(Capo Webmaster))

    self.update_attribute(:probability_right, prob_g)
    self.update_attribute(:all_time_right_choices,
                          self.get_all_time_right_choices)
  end

  def get_all_time_right_choices
    right_choices = self.user.decision_user_choices.count(
        :conditions => [
          "decisions.decision_type_class = ?
           AND decision_choice_id IN (
             SELECT final_decision_choice_id
             FROM decisions)
           AND decisions.state = #{Decision::DECIDED}",
          self.decision_type_class],
        :include => :decision)
  end
end
