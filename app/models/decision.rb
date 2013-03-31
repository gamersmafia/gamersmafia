# -*- encoding : utf-8 -*-
# TODO(slnc): add system description here.
#
# Context by decision_type_class
# CreateTag
#   tag_name (string)
#   initial_contents (list of ints content_ids)
#   initiating_user_id (int with id of user who initiated the request)
#   tag_overlaps
#
# PublishNews
#   content_id
#   content_name
#   initiating_user_id
class Decision < ActiveRecord::Base
  # state
  PENDING = 0
  DECIDED = 1

  # choice_type_id
  BINARY = 0
  MULTIPLE_OPTIONS = 1

  CHOICE_TYPE_NAMES = {
    BINARY => "binary",
    MULTIPLE_OPTIONS => "multiple-options",
  }

  STATE_NAMES = {
    PENDING => 'Pending',
    DECIDED => 'Decided',
  }

  DECISION_TYPE_CLASS_SKILLS = {
    "CreateGame" => "CreateEntity",
    "CreateGamingPlatform" => "CreateEntity",
    "CreateTag" => "CreateEntity",
    "PublishBet" => "ContentModerationQueue",
    "PublishColumn" => "ContentModerationQueue",
    "PublishCoverage" => "ContentModerationQueue",
    "PublishDemo" => "ContentModerationQueue",
    "PublishDownload" => "ContentModerationQueue",
    "PublishEvent" => "ContentModerationQueue",
    "PublishFunthing" => "ContentModerationQueue",
    "PublishImage" => "ContentModerationQueue",
    "PublishInterview" => "ContentModerationQueue",
    "PublishNews" => "ContentModerationQueue",
    "PublishPoll" => "ContentModerationQueue",
    "PublishReview" => "ContentModerationQueue",
    "PublishTutorial" => "ContentModerationQueue",
  }

  DECISION_TYPE_CLASSES = DECISION_TYPE_CLASS_SKILLS.keys

  DECISION_TYPE_CHOICES = {
    "CreateGame" => BINARY,
    "CreateGamingPlatform" => BINARY,
    "CreateTag" => BINARY,
    "PublishBet" => BINARY,
    "PublishColumn" => BINARY,
    "PublishCoverage" => BINARY,
    "PublishDemo" => BINARY,
    "PublishDownload" => BINARY,
    "PublishEvent" => BINARY,
    "PublishFunthing" => BINARY,
    "PublishImage" => BINARY,
    "PublishInterview" => BINARY,
    "PublishNews" => BINARY,
    "PublishPoll" => BINARY,
    "PublishReview" => BINARY,
    "PublishTutorial" => BINARY,
  }

  MIN_USER_CHOICES = {
    "CreateGame" => 3,
    "CreateGamingPlatform" => 3,
    "CreateTag" => 3,
    "PublishBet" => 3,
    "PublishColumn" => 3,
    "PublishCoverage" => 3,
    "PublishDemo" => 3,
    "PublishDownload" => 3,
    "PublishEvent" => 3,
    "PublishFunthing" => 3,
    "PublishImage" => 3,
    "PublishInterview" => 3,
    "PublishNews" => 3,
    "PublishPoll" => 3,
    "PublishReview" => 3,
    "PublishTutorial" => 3,
  }

  MAX_USER_CHOICES = {
    "CreateGame" => 15,
    "CreateGamingPlatform" => 15,
    "CreateTag" => 15,
    "PublishBet" => 15,
    "PublishColumn" => 15,
    "PublishCoverage" => 15,
    "PublishDemo" => 15,
    "PublishDownload" => 15,
    "PublishEvent" => 15,
    "PublishFunthing" => 15,
    "PublishImage" => 15,
    "PublishInterview" => 15,
    "PublishNews" => 15,
    "PublishPoll" => 15,
    "PublishReview" => 15,
    "PublishTutorial" => 15,
  }

  # Don't change this without also changing the names in the bd
  BINARY_YES = "Sí"
  BINARY_NO = "No"

  has_many :decision_comments
  has_many :decision_choices
  belongs_to :final_decision_choice,
    :class_name => "DecisionChoice", :foreign_key => "final_decision_choice_id"
  has_many :decision_user_choices

  accepts_nested_attributes_for :decision_choices

  before_create :populate_decision_type_choices
  before_create :set_state
  before_save :check_decision_type_class
  after_save :schedule_update_pending_indicators
  validates_presence_of :decision_type_class, :context

  scope :pending, :conditions => "state = #{PENDING}"
  scope :decided, :conditions => "state = #{DECIDED}"
  scope :with_type_class, lambda {|thing|
    if thing.class.name != "Array"
      thing = [thing]
    end
    type_classes = thing.collect {|type_class| "'#{type_class}'"}
    type_classes = ["'None'"] if type_classes.size == 0

    {:conditions => "decision_type_class IN (#{type_classes.join(",")})"}
  }

  serialize :context

  # Updates pending decision indicators of everybody
  def self.update_pending_decisions_indicators
    User.db_query(
      "UPDATE users
      SET pending_decisions = 'f'
      WHERE lastseen_on >= NOW() - '2 days'::interval")
    users = {}
    Decision.pending.find(:all).each do |decision|
      decision.pending_decisions_indicators.each do |u_id, has_pending|
        if !users.include?(u_id)
          users[u_id] = has_pending
        elsif has_pending
          users[u_id] = has_pending
        end
      end
    end
    users.each do |u_id, status|
      User.find(u_id).update_column(:pending_decisions, status)
    end
  end

  def self.has_pending_decisions(u)
    type_classes = Authorization.decision_type_class_available_for_user(u)
    Decision.pending.with_type_class(type_classes).find(:all).each do |decision|
      next if decision.context && decision.context[:initiating_user_id] == u.id
      if !decision.has_vote_from(u)
        return true
      end
    end
    false
  end

  def has_vote_from(u)
    self.decision_user_choices.count(:conditions => ["user_id = ?", u.id]) > 0
  end

  def pending_decisions_indicators
    users = {}
    users_can_vote = self.users_who_can_vote.collect {|u| u.id}
    users_have_voted = self.users_who_voted.collect {|u| u.id}
    users_can_vote.each do |u_id|
      users[u_id] ||= ((self.state == PENDING) ? true : false)
    end

    return users if self.state != PENDING

    users_have_voted.each do |u_id|
      users[u_id] = false
    end
    users
  end

  def schedule_update_pending_indicators
    self.delay.update_pending_decisions_indicators
  end

  def update_pending_decisions_indicators
    self.pending_decisions_indicators.each do |u_id, has_pending|
      u = User.find(u_id)
      if !has_pending
        has_pending = Decision.has_pending_decisions(u)
      end
      u.update_column(:pending_decisions, has_pending)
    end
  end

  # Returns list of users who can vote on this decision
  def users_who_can_vote
    remove = []
    if self.context[:initiating_user_id]
      remove = [User.find(self.context[:initiating_user_id])]
    end
    Authorization.users_who_can_vote_on_decision(self) - remove
  end

  # Returns list of users who can vote on this decision
  def users_who_voted
    User.find(
        :all,
        :conditions => ["users.id = decision_user_choices.user_id
                        AND decision_user_choices.decision_id = ?", self.id],
        :include => :decision_user_choices)
  end

  def choice_type_name
    CHOICE_TYPE_NAMES[self.choice_type_id]
  end

  # One line unique description of this decision
  def decision_description
    case self.decision_type_class
    when "CreateTag"
      "<strong>#{self.context.fetch(:tag_name)}</strong>"

    when "CreateGame"
      "<strong>#{self.context.fetch(:game)[:name]}</strong>"

    when "CreateGamingPlatform"
      "<strong>#{self.context.fetch(:gaming_platform)[:name]}</strong>"

    when "PublishBet"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishColumn"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishCoverage"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishDemo"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishDownload"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishEvent"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishFunthing"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishImage"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishInterview"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishNews"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishPoll"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishReview"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    when "PublishTutorial"
      "<strong>#{self.context.fetch(:content_name)}</strong>"

    else
      raise ("Unable to generate description for decision of type" +
             " #{self.decision_type_class}")
    end
  end

  def binary?
    self.choice_type_id == BINARY
  end

  # We require the option with the most number of user votes to be at least
  # total_votes * 1/x
  def try_to_make_decision
    if self.state != PENDING
      Rails.logger.error(
          "Decision '#{self.id}' is not in pending state, can't try_to_make_decision.")
      return
    end

    total_votes = self.decision_user_choices.count
    return if total_votes < self.min_user_choices
    return if self.completion_ratio < 1.0

    winning_choice = User.db_query(
        "SELECT SUM(probability_right) as sum,
           decision_choice_id
         FROM decision_user_choices
         WHERE decision_id = #{self.id}
         GROUP BY decision_choice_id
         ORDER BY sum DESC LIMIT 1")

    self.update_attributes({
      :state => DECIDED,
      :final_decision_choice_id => winning_choice[0]['decision_choice_id'].to_i,
    })
    self.delay.update_voting_users
    callback_on_final_decision
  end

  def update_voting_users
    self.decision_user_choices.each do |choice|
      reputation = DecisionUserReputation.find(
          :first,
          :conditions => ["user_id = ? AND decision_type_class = ?",
                          choice.user_id, self.decision_type_class])
      reputation.update_probability_right
    end
  end

  def completion_ratio
    best_option_votes = User.db_query(
        "SELECT SUM(probability_right) as sum,
           decision_choice_id
         FROM decision_user_choices
         WHERE decision_id = #{self.id}
         GROUP BY decision_choice_id
         ORDER BY sum DESC LIMIT 1")
    return if best_option_votes.size == 0

    total_votes = self.decision_user_choices.sum(:probability_right)
    total_users = self.decision_user_choices.count
    choices = self.decision_choices.count

    # This formula ensures that the best option has at least more than 1/x votes
    # where x is the number of choices. That is, for 2 choices and 10 votes it
    # requires 7.5 (8 votes) in favor of the winning option. For 3 options and
    # 10 votes it requires 6.6 for the winning option and so on. It ensures that
    # there is a strong majority in favor of the winning option.
    min_votes = (((choices + 1).to_f / choices) * total_votes) / 2

    if total_users > MAX_USER_CHOICES.fetch(self.decision_type_class)
      Rails.logger.warn(
          "Reached an impass. #{total_users} voted over max of
          #{MAX_USER_CHOICES.fetch(self.decision_type_class)}. Defaulting to
          simple majority")
      return 1.0
    end

    [(total_users.to_f / self.min_user_choices),
     (best_option_votes[0]['sum'].to_f / [min_votes, 1].max)
    ].min
  end

  private
  def set_state
    self.state = PENDING
    self.min_user_choices = MIN_USER_CHOICES.fetch(self.decision_type_class)
  end

  def populate_decision_type_choices
    if self.choice_type_id.nil?
      self.choice_type_id = DECISION_TYPE_CHOICES.fetch(
          self.decision_type_class)
    end

    if self.choice_type_id == BINARY
      self.decision_choices= [
        DecisionChoice.new(:name => BINARY_YES),
        DecisionChoice.new(:name => BINARY_NO)]
    else
      if self.decision_choices.nil?
        self.errors[:base].add("No se ha especificado ninguna opción")
        return false
      end
    end
    true
  end

  def callback_on_final_decision
    case self.decision_type_class

    when "CreateTag"
      Term.final_decision_made(self)

    when "CreateGamingPlatform"
      GamingPlatform.final_decision_made(self)

    when "CreateGame"
      Game.final_decision_made(self)

    when "PublishBet"
      Content.final_decision_made(self)

    when "PublishColumn"
      Content.final_decision_made(self)

    when "PublishCoverage"
      Content.final_decision_made(self)

    when "PublishDemo"
      Content.final_decision_made(self)

    when "PublishDownload"
      Content.final_decision_made(self)

    when "PublishEvent"
      Content.final_decision_made(self)

    when "PublishFunthing"
      Content.final_decision_made(self)

    when "PublishImage"
      Content.final_decision_made(self)

    when "PublishInterview"
      Content.final_decision_made(self)

    when "PublishNews"
      Content.final_decision_made(self)

    when "PublishPoll"
      Content.final_decision_made(self)

    when "PublishReview"
      Content.final_decision_made(self)

    when "PublishTutorial"
      Content.final_decision_made(self)

    else
      raise "No callback_on_final_decision for #{self.decision_type_class}"
    end
  end

  def check_decision_type_class
    DECISION_TYPE_CLASS_SKILLS.include?(self.decision_type_class)
  end
end
