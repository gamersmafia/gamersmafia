# -*- encoding : utf-8 -*-
class AlertasController < ApplicationController
  before_filter :require_auth_users

  def submenu
    'alertas'
  end

  def submenu_items
    its = []
    # TODO permisos
    its << ['Webmaster', '/alertas/webmaster'] if @user.has_skill_cached?("Webmaster")
    its << ['Capo', '/alertas/capo'] if @user.has_skill_cached?("Capo")
    its << ['Alcalde', '/alertas/bazar_manager'] if @user.has_skill_cached?("BazarManager")
    its << ['Gladiador', '/alertas/gladiador'] if @user.has_skill_cached?("Gladiator")
    its << ['Boss', '/alertas/faction_bigboss'] if @user.is_faction_leader?
    its << ['Don', '/alertas/bazar_district_bigboss'] if @user.is_district_leader?
    its << ['Moderador', '/alertas/moderator'] if @user.is_moderator?
    its << ['Editor', '/alertas/editor'] if @user.is_faction_editor?
    its << ['Sicario', '/alertas/sicario'] if @user.is_sicario?
    its << ['Admin comp', '/alertas/competition_admin'] if @user.is_competition_admin?
    its << ['Supervisor comp', '/alertas/competition_supervisor'] if @user.is_competition_supervisor?
    its
  end

  def index
    # por defecto mostramos la ficha de mayor rango
    if @user.has_skill_cached?("Webmaster")
      webmaster; render(:action => 'webmaster')
    elsif @user.has_skill_cached?("BazarManager")
      bazar_manager ; render(:action => 'bazar_manager')
    elsif @user.has_skill_cached?("Capo")
      capo ; render(:action => 'capo')
    elsif @user.has_skill_cached?("Gladiator")
      gladiador ; render(:action => 'gladiador')
    elsif @user.is_faction_leader?
      faction_bigboss ; render(:action => 'faction_bigboss')
    elsif @user.is_district_leader?
      bazar_district_bigboss ; render(:action => 'bazar_district_bigboss')
    elsif @user.is_faction_editor?
      editor ; render(:action => 'editor')
    elsif @user.is_moderator?
      moderator ; render(:action => 'moderator')
    elsif @user.is_sicario?
      sicario ; render(:action => 'sicario')
    elsif @user.is_competition_admin?
      competition_admin ; render(:action => 'competition_admin')
    elsif @user.is_competition_supervisor?
      competition_supervisor ; render(:action => 'competition_supervisor')
    end
  end

  def historial
    # por defecto mostramos la ficha de mayor rango
    case params[:domain].to_sym
    when :webmaster
      webmaster
    when :bazar_manager
      bazar_manager
    when :capo
      capo
    when :gladiador
      gladiador
    when :faction_bigboss
      faction_bigboss
    when :bazar_district_bigboss
      bazar_district_bigboss
    when :editor
      editor
    when :moderator
      moderator
    when :sicario
      sicario
    when :competition_admin
      competition_admin
    when :competition_supervisor
      competition_supervisor
    else
      raise "unknown domain #{params[:domain]}"
    end
  end

  def webmaster
    @title = 'Webmaster'
    @domain = :webmaster
    raise AccessDenied unless @user.has_skill_cached?("Webmaster")
  end

  def capo
    @title = 'Capo'
    @domain = :capo
    raise AccessDenied unless @user.has_skill_cached?("Capo")
  end

  def bazar_manager
    @title = 'Alcalde'
    @domain = :bazar_manager
    raise AccessDenied unless @user.has_skill_cached?("BazarManager")
  end

  def faction_bigboss
    @title = 'Boss/underboss'
    @domain = :faction_bigboss
    raise AccessDenied unless @user.is_faction_leader?
    process_scopes(:faction_bigboss)
  end

  def moderator
    @title = 'Moderador'
    raise AccessDenied unless @user.is_moderator?
    @domain = :moderator
    process_scopes(:moderator)
  end

  def editor
    @title = 'Editor'
    raise AccessDenied unless @user.is_faction_editor?
    @domain = :editor
    process_scopes(:editor)
  end

  def bazar_district_bigboss
    @title = 'Don/Mano Derecha'
    raise AccessDenied unless @user.is_district_leader?
    @domain = :bazar_district_bigboss
    process_scopes(:bazar_district_bigboss)
  end

  def sicario
    @title = 'Sicario'
    raise AccessDenied unless @user.is_sicario?
    @domain = :sicario
    process_scopes(:sicario)
  end

  def gladiador
    @title = 'Gladiador'
    @domain = :gladiador
    raise AccessDenied unless @user.has_skill_cached?("Gladiator")
  end

  def competition_admin
    @title = 'Admin de competición'
    raise AccessDenied unless @user.is_competition_admin?
    @domain = :competition_admin
    process_scopes(:competition_admin)
  end

  def competition_supervisor
    @title = 'Supervisor de competición'
    raise AccessDenied unless @user.is_competition_supervisor?
    @domain = :competition_supervisor
    process_scopes(:competition_supervisor)
  end

  def alert_reviewed
    sle = Alert.find(:first, :conditions => ['id = ? AND (reviewer_user_id IS NULL OR reviewer_user_id = ?)', params[:id], @user.id])
    require_can_edit_sle?(sle)
    if sle.nil?
      flash[:error] = "La entrada especificada ya ha sido resuelta, ha sido asignada a otro usuario o no existe."
    else
      sle.mark_as_resolved(@user.id)
    end

    @js_response = "$('#sle#{sle.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def alert_assigntome
    @sle = Alert.find_or_404(
        :first,
        :conditions => ['id = ? AND reviewer_user_id IS NULL', params[:id]])
    require_can_edit_sle?(@sle)
    if @sle.nil?
      flash[:error] = "La entrada especificada ya ha sido resuelta, ha sido asignada a otro usuario o no existe."
    else
      @sle.reviewer_user_id = @user.id
      @sle.save
    end
    render :partial => '/site/alertas_feedback', :layout => false
  end

  protected
  def process_scopes(domain)
    @available_scopes = Alert.scopes(domain, @user)
    valid_scopes = @available_scopes.collect { |s| s.id }
    if params[:scope]
      if domain != :editor && !valid_scopes.include?(params[:scope].to_i)
        raise AccessDenied
      elsif domain == :editor && !valid_scopes.include?(params[:scope].to_i) && !valid_scopes.include?((params[:scope].to_i / Alert::EDITOR_SCOPE_CONTENT_TYPE_ID_MASK) * Alert::EDITOR_SCOPE_CONTENT_TYPE_ID_MASK)
        # quitamos la mascara para ver si tiene poderes sobre todos los content types
        raise AccessDenied
      end
    end

    @scope = params[:scope] ? params[:scope].to_i : valid_scopes[0]
  end

  def require_can_edit_sle?(sle)
    case Alert.domain_from_type_id(sle.type_id)
      when :webmaster
      raise AccessDenied unless @user.has_skill_cached?("Webmaster")

      when :capo
      raise AccessDenied unless @user.has_skill_cached?("Capo")

      when :bazar_manager
      raise AccessDenied unless @user.has_skill_cached?("BazarManager")

      when :faction_bigboss
      raise AccessDenied unless Faction.find(sle.scope).is_bigboss?(@user)

      when :moderator
      raise AccessDenied unless Faction.find(sle.scope).is_moderator?(@user)

      when :editor
      faction_id, content_type_id = Alert.decode_editor_scope(sle.scope)
      raise AccessDenied unless Faction.find(faction_id).is_editor_of_content_type?(@user, ContentType.find(content_type_id))

      when :bazar_district_bigboss
      raise AccessDenied unless BazarDistrict.find(sle.scope).is_bigboss?(@user)

      when :sicario
      raise AccessDenied unless BazarDistrict.find(sle.scope).is_sicario?(@user)

      when :gladiador
      raise AccessDenied unless @user.has_skill_cached?("Gladiator")

      when :competition_admin
      raise AccessDenied unless Competition.find(sle.scope).is_admin?(@user)

      when :competition_supervisor
      raise AccessDenied unless Competition.find(sle.scope).is_supervisor?(@user)

    else
      raise "unknown domain"
    end
  end
end
