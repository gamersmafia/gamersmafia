# -*- encoding : utf-8 -*-
class DecisionsController < ApplicationController
  def index
    @title = "Decisiones"
  end

  def show
    @decision = Decision.find(params[:id])
    render :layout => false # !self.request.xhr?
  end

  # Do NOT use 'decide', as of Rails 3.2.10 it's a reserved keyword.
  def make_decision
    @decision = Decision.find(params[:id])
    decision_choice = DecisionChoice.find(params[:final_decision_choice].to_i)

    require_authorization_for_object(:can_vote_on_decision?, @decision)
    user_choice = DecisionUserChoice.find(
        :first,
        :conditions => ["decision_id = ? AND user_id = ?",
                        @decision.id, @user.id])

    if user_choice.nil?
      user_choice = @decision.decision_user_choices.new({
        :user_id => @user.id,
      })
    end

    if user_choice.update_attribute(:decision_choice_id, decision_choice.id)
      flash[:notice] = "Decisión guardada correctamente."
    else
      flash[:error] = (
          "Error al guardar tu decisión:
          #{user_choice.errors.full_messages_html}.")
    end
    render :partial => '/shared/ajax_facebox_feedback',
           :layout => false,
           :locals => {:custom_js => "$('#decision#{@decision.id}').fadeOut();"}
  end

  def ranking
    type_class = params[:id]
    if !Decision::DECISION_TYPE_CLASS_SKILLS.include?(type_class)
      raise ActiveRecord::RecordNotFound
    end
  end
end
