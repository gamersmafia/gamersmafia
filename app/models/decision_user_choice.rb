# -*- encoding : utf-8 -*-
class DecisionUserChoice < ActiveRecord::Base
  belongs_to :decision
  belongs_to :decision_choice
  belongs_to :user

  before_create :populate_probability_right
  after_save :touch_decision
  after_save :try_to_make_decision
  scope :recent,
        :conditions => "decision_user_choices.created_on >= now() - '6 months'::interval"

  validates_presence_of :decision_choice_id
  validates_presence_of :user_id
  validates_uniqueness_of :decision_choice_id, :scope => [:user_id, :decision_id]

  CANNED_REASONS = {
    0 => "Tipo de contenido incorrecto",
    1 => "Categoría incorrecta",
    2 => "Duplicado",
    3 => "Ilegible",
    4 => "Viola el código de conducta",
    5 => "No tiene suficiente calidad",
  }

  CANNED_REASONS_BY_DECISION_TYPE_CLASS = {
    "PublishNews" => [0, 1, 2, 3, 4, 5],
    "PublishBet" => [0, 1, 2, 3, 4, 5],
    "PublishColumn" => [0, 1, 2, 3, 4, 5],
    "PublishCoverage" => [0, 1, 2, 3, 4, 5],
    "PublishDemo" => [0, 1, 2, 3, 4, 5],
    "PublishDownload" => [0, 1, 2, 3, 4, 5],
    "PublishEvent" => [0, 1, 2, 3, 4, 5],
    "PublishFunthing" => [0, 1, 2, 3, 4, 5],
    "PublishImage" => [0, 1, 2, 3, 4, 5],
    "PublishInterview" => [0, 1, 2, 3, 4, 5],
    "PublishNews" => [0, 1, 2, 3, 4, 5],
    "PublishPoll" => [0, 1, 2, 3, 4, 5],
    "PublishReview" => [0, 1, 2, 3, 4, 5],
    "PublishTutorial" => [0, 1, 2, 3, 4, 5],
  }

  private
  def populate_probability_right
    self.probability_right = DecisionUserReputation.get_user_probability_for(
        self.user, self.decision.decision_type_class)
  end

  def try_to_make_decision
    self.decision.try_to_make_decision
  end

  def touch_decision
    self.decision.update_attribute(:updated_on, Time.now)
  end

  def reason
    if self.canned_reason_id
      CANNED_REASONS[self.canned_reason_id]
    else
      self.custom_reason
    end
  end
end
