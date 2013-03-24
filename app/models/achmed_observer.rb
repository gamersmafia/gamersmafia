# -*- encoding : utf-8 -*-
class AchmedObserver < ActiveRecord::Observer
  CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD = 5000

  observe CashMovement, Alert

  def after_create(object)
    case object.class.name

     when 'CashMovement' then
       if object.ammount >= CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD
         Alert.create(:headline => object.to_s,
                          :type_id => Alert::TYPES[:security])
       end
      when 'Alert'
        self.handle_alert(object)
    end
  end

  def handle_alert(alert)
    reporter = alert.reporter
    case alert.type_id
      when Alert::TYPES[:general_comment_report]
        if reporter.has_skill_cached?("Capo")
          self.moderate_comment(reporter, alert)
        end

      when Alert::TYPES[:faction_comment_report]
        comment = Comment.find(alert.entity_id)
        if comment.content.my_faction.user_is_moderator(reporter)
          self.moderate_comment(reporter, alert)
        end

      when Alert::TYPES[:bazar_district_comment_report]
        comment = Comment.find(alert.entity_id)
        if comment.content.bazar_district.user_is_moderator(reporter)
          self.moderate_comment(reporter, alert)
        end
    end
  end

  def moderate_comment(user, alert)
    comment = Comment.find(alert.entity_id)
    comment.moderate(user, alert.data[:moderation_reason])
    alert.mark_as_resolved(Ias.MrAchmed.id)
  end
end
