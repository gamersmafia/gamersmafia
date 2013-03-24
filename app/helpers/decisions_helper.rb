# -*- encoding : utf-8 -*-
module DecisionsHelper
  def pending_decisions_for_user(user)
    decisions = []
    Decision.pending.find(:all, :order => 'created_on DESC').each do |decision|
      if Authorization.can_vote_on_decision?(user, decision) && !decision.has_vote_from(user)
        decisions.append(decision)
      end
    end
    decisions
  end

  def decision_title(decision)
    "#{gm_translate(decision.decision_type_class)} '#{decision.decision_description}'"
  end

  def current_decision_user_reputations(user)
    user.decision_user_reputations.find(:all).sort_by {|r|
      gm_translate(r.decision_type_class)
    }
  end

  def decision_context(decision)
    out = []
    case decision.decision_type_class
    when "CreateGame"
      out.append(self.render_create_game_context(decision))

    when "CreateGamingPlatform"
      out.append(self.render_create_gaming_platform_context(decision))

    when "CreateTag"
      out.append(self.render_create_tag_context(decision))

    when "PublishBet"
      out.append(self.render_content_from_decision(decision))

    when "PublishColumn"
      out.append(self.render_content_from_decision(decision))

    when "PublishCoverage"
      out.append(self.render_content_from_decision(decision))

    when "PublishDemo"
      out.append(self.render_content_from_decision(decision))

    when "PublishDownload"
      out.append(self.render_content_from_decision(decision))

    when "PublishEvent"
      out.append(self.render_content_from_decision(decision))

    when "PublishFunthing"
      out.append(self.render_content_from_decision(decision))

    when "PublishImage"
      out.append(self.render_content_from_decision(decision))

    when "PublishInterview"
      out.append(self.render_content_from_decision(decision))

    when "PublishNews"
      out.append(self.render_content_from_decision(decision))

    when "PublishPoll"
      out.append(self.render_content_from_decision(decision))

    when "PublishReview"
      out.append(self.render_content_from_decision(decision))

    when "PublishTutorial"
      out.append(self.render_content_from_decision(decision))

    else
      raise (
          "No context defined for decision_type_class" +
          " '#{decision.decision_type_class}'")
    end

    out.join("\n")
  end

  def render_content_from_decision(decision)
    content = Content.find(decision.context.fetch(:content_id))
    controller.send(
        :render_to_string,
        :partial => "/contents/#{content.content_type.name.downcase}",
        :locals => {:content => content}).force_encoding("utf-8")
  end

  def render_create_game_context(decision)
    controller.send(
        :render_to_string,
        :partial => "/games/decision_context",
        :locals => {:game => decision.context.fetch(:game)}).force_encoding("utf-8")
  end

  def render_create_gaming_platform_context(decision)
    controller.send(
        :render_to_string,
        :partial => "/games/gaming_platform_decision_context",
        :locals => {:gaming_platform => decision.context.fetch(:gaming_platform)}).force_encoding("utf-8")
  end

  def render_create_tag_context(decision)
    out = []
    out.append("Contenidos iniciales con este tag:<br /><ul>")

    decision.context[:initial_contents].each do |content_id|
      content = Content.find_by_id(content_id.to_i)
      if content.nil?
        out.append("<li>(Contenido inválido: #{content_id.to_i})</li>")
      else
        out.append("<li><a href=\"#{Routing.gmurl(content)}\">#{content.name}</a></li>")
      end
    end
    out.append("</ul>")

    if decision.context[:tag_overlaps].size > 0
      out.append("<table><tr><th class=\"w125\">Tag</th><th>Solapamiento</th></tr>")
      sorted_overlaps = decision.context[:tag_overlaps].sort_by{|term_id, overlap|
        Term.find(term_id.to_i).name
      }
      sorted_overlaps.each do |term_id, overlap|
        out.append(
            "<tr>
                 <td>#{Term.find(term_id.to_i).name}</td>
                 <td class=\"w125\">#{draw_pcent_bar(overlap.to_f)}</td>
               </tr>")
      end
      out.append("</table>")
    end

    out.append("</ul>")
    out.join("\n")
  end

  def decision_reputations_total_right_ranking(decision_type_class)
    DecisionUserReputation.find(
        :all,
        :conditions => ["decision_type_class = ? AND probability_right > 0",
                        decision_type_class],
        :order => "all_time_right_choices DESC, probability_right DESC",
        :limit => 25,
        :include => :user)
  end

  def decision_reputations_reputation_ranking(decision_type_class)
    DecisionUserReputation.find(
        :all,
        :conditions => ["decision_type_class = ? AND probability_right > 0",
                        decision_type_class],
        :order => "probability_right DESC, all_time_right_choices DESC",
        :limit => 25,
        :include => :user)
  end
end
