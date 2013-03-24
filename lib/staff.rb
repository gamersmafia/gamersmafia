# -*- encoding : utf-8 -*-
module Staff
  def self.transition_positions
    StaffPosition.should_be_in_elections.find(:all).each do |position|
      position.open_candidacy_presentation
    end

    StaffPosition.candidacy_presentation.find(:all).each do |position|
      if position.candidacy_presentation_ends_on <= Time.now
        position.close_candidacy_presentation
      end
    end

    StaffPosition.voting.find(:all).each do |position|
      if position.voting_ends_on <= Time.now
        position.close_voting_period
      end
    end
  end

  def self.user_can_vote_staff_candidate(user, staff_candidate)
    user.id != staff_candidate.user_id
  end

  def self.can_edit_staff_candidate(user, staff_position, staff_candidate)
    ([StaffPosition::VOTING,
      StaffPosition::CANDIDACY_PRESENTATION].include?(staff_position.state) &&
     user.id == staff_candidate.user_id)
  end

  def self.can_deny_staff_candidate(user, staff_position, staff_candidate)
    staff_position.state == StaffPosition::ELECT && user.has_skill_cached?("Webmaster")
  end

  def self.can_confirm_staff_position_winners(user, staff_position)
    staff_position.state == StaffPosition::ELECT && user.has_skill_cached?("Webmaster")
  end
end
