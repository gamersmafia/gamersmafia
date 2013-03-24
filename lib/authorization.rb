# This module determines what actions can different users or clans take.
module Authorization
  # TODO(slnc): migrar todas las llamadas restantes a .has_skill_cached? a que usen
  # este sistema.

  def self.can_access_bank?(user)
    user.has_skill_cached?("Bank")
  end

  def self.can_access_experiments?(user)
    user.has_skill_cached?("Webmaster")
  end

  def self.can_access_gmshop?(user)
    user.has_skill_cached?("GmShop")
  end

  def self.can_access_moderation_queue?(user)
    user.has_skill_cached?("ContentModerationQueue")
  end

  def self.can_admin_competition?(u, competition)
    competition.user_is_admin(u.id) || u.has_skill_cached?("Webmaster")
  end

  def self.can_admin_toplevel_terms?(u)
    u.has_any_skill?(%w(BazarManager Capo Webmaster))
  end

  def self.can_admin_non_root_terms?(user)
    user.has_any_skill?(%w(
        Boss
        Capo
        Don
        Editor
        ManoDerecha
        Sicario
        Underboss
        Webmaster
    ))
  end

  def self.can_admin_all_items?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_admin_bazar_districts?(user)
    user.has_skill_cached?("BazarManager")
  end

  def self.can_antiflood_users?(user)
    user.has_skill_cached?("Antiflood")
  end

  def self.can_admin_tags?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_bulk_upload?(u)
    u.has_skill_cached?("BulkUpload")
  end

  def self.can_bypass_publish_decision?(user, content)
    user.has_skill_cached?("EditContents")
  end

  def self.can_comment_on_decision?(user, decision)
    if user.id == decision.context[:initiating_user_id]
      true
    elsif user.has_skill?(Decision::DECISION_TYPE_CLASS_SKILLS.fetch(decision.decision_type_class))
      true
    else
      false
    end
  end

  def self.decision_type_class_available_for_user(user)
    Decision::DECISION_TYPE_CLASS_SKILLS.collect {|type_class, role|
      user.has_skill_cached?(role) ? type_class : nil
    }.compact
  end

  def self.users_who_can_vote_on_decision(decision)
    skill = Decision::DECISION_TYPE_CLASS_SKILLS.fetch(
        decision.decision_type_class)
    User.with_skill(skill).find(:all)
  end

  def self.can_vote_on_decision?(user, decision)
    if decision.context[:initiating_user_id]
      return false if user.id == decision.context[:initiating_user_id]
    end

    user.has_skill_cached?(
        Decision::DECISION_TYPE_CLASS_SKILLS.fetch(decision.decision_type_class))
  end

  def self.can_create_content?(user)
    User::STATES_CAN_LOGIN.include?(user.state) && user.antiflood_level < 5
  end

  def self.can_create_profile_signatures?(user)
    user.has_skill_cached?("ProfileSignatures")
  end

  def self.can_create_term?(u, term, taxonomy)
    self.can_edit_term?(u, term, taxonomy)
  end

  def self.can_delete_content?(user, content)
    return true if user.has_any_skill?(%w(Capo DeleteContents Webmaster))
    org = Organizations.find_by_content(content)
    if org
      return true if org.user_is_editor_of_content_type?(
          user, ContentType.find_by_name(content.class.name))
    end
    false
    # TODO(slnc): temporal, hack una vez que limpiemos user_can_edit_content?
    # tenemos que cambiar estas reglas para permitir ciertas combinaciones de
    # usuarios y tipos de contenido. Eg: a autores de entradas de blog borrar
    # sus entradas o a autores de anuncios de reclutamiento borrar sus anuncios.
  end

  def self.can_delete_contents?(user)
    user.has_skill_cached?("DeleteContents")
  end

  def self.can_edit_ad_slot?(user, ads_slot)
  (user.has_skill_cached?("Webmaster") ||
   user.users_skills.count(
       :conditions => "role = 'Advertiser' AND
                       role_data = '#{ads_slot.advertiser_id}'") > 0)
  end

  def self.can_edit_ads_directly?(user)
    user.has_skill_cached?("Webmaster")
  end

  # Can any of the user provided fields be modified? (title, summary, etc)
  # TODO(slnc): simplify this and remove any checks not strictly related to
  # editing user-contributed fields.
  def self.can_edit_content?(user, content)
    return false if user.nil?
    return true if user.has_any_skill?(%w(EditContents Capo Webmaster))
    return true if content.user_id == user.id && content.state == Cms::DRAFT

    content = content.real_content if content.class.name == "Content"

    org = Organizations.find_by_content(content)
    if org
      return true if org.user_is_editor_of_content_type?(
          user, ContentType.find_by_name(content.class.name))
      return false if org.user_is_banned?(content.user)
    end

    if (Cms::AUTHOR_CAN_EDIT_CONTENTS.include?(content.class.name) &&
        content.user_id == user.id)
      return true
    end

    if (content.state == Cms::PENDING && self.can_modify_pending_content?(user))
      return true
    end

    if (content.class.name == 'RecruitmentAd' &&
        (content.clan_id && content.clan.user_is_clanleader(user.id)))
      true
    elsif content.kind_of?(Coverage) && (c = content.event.competition)
      c.user_is_admin(user.id)
    elsif content.kind_of?(Coverage)
      Authorization.can_edit_content?(user, content.event)
    end

    false
  end

  # TODO(slnc): temp
  def self.can_edit_games?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_edit_entities?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_edit_faction?(user, faction)
    user.has_skill_cached?("Webmaster") || faction.is_bigboss?(user)
  end

  def self.can_edit_faq?(user)
    user.has_skill_cached?("EditFaq")
  end

  def self.can_edit_term?(u, term, taxonomy)
    return true if u.has_skill_cached?("Capo") || u.has_skill_cached?("Webmaster")
    return false if term.id == term.root_id

    if term.game_id
      f = Faction.find_by_code(term.game.slug)
      (f.is_bigboss?(u) ||
       f.user_is_editor_of_content_type?(
           u, ContentType.find_by_name(taxonomy)))
    elsif term.gaming_platform_id
      f = Faction.find_by_code(term.platform.slug)
      (f.is_bigboss?(u) ||
       f.user_is_editor_of_content_type?(
           u, ContentType.find_by_name(taxonomy)))
    elsif term.bazar_district_id
      f = term.bazar_district
      f.is_bigboss?(u) || f.is_sicario?(u)
    elsif term.clan_id
      c = term.clan
      c.user_is_clanleader(u)
    end
  end

  def self.can_edit_users?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_force_recalculate_user_attributes?(user)
    user.has_any_skill?(%w(Capo Webmaster))
  end

  def self.can_mass_moderate_contents?(user)
    user.has_any_skill?(%w(MassModerateContents Capo Webmaster))
  end

  def self.can_moderate_comment?(user, comment)
    user.has_skill_cached?("Capo")
  end

  def self.can_modify_pending_content?(user)
    user.has_skill_cached?("EditContents")
  end

  def self.can_rate_comments_down?(user)
    user.has_skill_cached?("RateCommentsDown")
  end

  def self.can_rate_comments_up?(user)
    user.has_skill_cached?("RateCommentsUp")
  end

  def self.can_recover_content?(user, content)
    user.has_skill_cached?("DeleteContents")
  end

  def self.can_report_comments?(user)
    user.has_skill_cached?("ReportComments")
  end

  def self.can_report_contents?(user)
    user.has_skill_cached?("ReportContents")
  end

  def self.can_report_users?(user)
    user.has_skill_cached?("ReportUsers")
  end

  def self.can_see_netiquette_violations?(user)
    user.has_skill_cached?("Capo")
  end

  def self.can_set_best_answer(user, content)
    return false if content.class.name != 'Question'
    user.id == content.user_id || self.can_edit_content?(user, content)
  end

  def self.can_tag_contents?(user)
    user.has_skill_cached?("TagContents")
  end

  def self.can_create_entities?(user)
    user.has_skill_cached?("CreateEntity")
  end

  def self.gets_less_ads?(user)
    user.has_skill_cached?("LessAds")
  end

  def self.is_advertiser?(user)
    user.has_skill_cached?("Advertiser")
  end

  def self.is_faction_staff?(u, faction)
    (faction.is_big_boss?(u) || faction.is_editor?(u) || u.has_skill_cached?("Capo"))
  end
end
