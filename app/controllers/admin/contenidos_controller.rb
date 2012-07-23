# -*- encoding : utf-8 -*-
class Admin::ContenidosController < ApplicationController
  before_filter :require_auth_users, :except => [ :show ]

  def submenu
    'Contenidos'
  end

  def submenu_items
    if @user.is_bigboss? then
      return [['Hotmap', '/admin/contenidos/hotmap'],
              ['Pendientes', '/admin/contenidos'],
              ['Huérfanos', '/admin/contenidos/huerfanos'],
              ['Últimas decisiones', '/admin/contenidos/ultimas_decisiones'],
              ['Papelera', '/admin/contenidos/papelera'], ]
    elsif @user.is_editor? then
      return [['Pendientes', '/admin/contenidos'],
              ['Huérfanos', '/admin/contenidos/huerfanos'],
              ['Papelera', '/admin/contenidos/papelera'], ]
    else
      return [['Pendientes', '/admin/contenidos'], ]
    end
  end

  def index
    @title = 'Contenidos pendientes de moderar'
    @contents = []

    for c in Cms::contents_classes_publishable
      controller = Cms::translate_content_name(c.name)
      @contents<< [Cms::translate_content_name(c.name).capitalize,
                   c.pending,
                   controller]
    end
  end

  def huerfanos
    require_user_is_staff
  end

  def papelera
    require_user_is_staff
    params[:portal] = self.portal.code if (params[:portal].nil? &&
                                           self.portal.id != -1 &&
                                           self.portal.type == 'FactionsPortal')

    if params[:portal].to_s != '' then
      b = FactionsPortal.find_by_code(params[:portal])
    else
      b = GmPortal.new
    end
    @title = 'Contenidos en la papelera'
    @contents = []
    for c in Cms::contents_classes_publishable + [Topic]
      @contents<< [Cms::translate_content_name(c.name).capitalize,
       b.send(ActiveSupport::Inflector::underscore(c.name)).find(:deleted,
              :conditions => 'contents.updated_on > now() - \'1 month\'::interval'),
       Cms::translate_content_name(c.name)]
    end
  end

  def ultimas_decisiones
    @title = 'Últimas decisiones'
    require_user_is_staff
  end

  def hotmap
    @title = 'Hotmap'
    require_user_is_staff
  end

  def recover
    obj = Content.find(params[:id]).real_content
    require_user_can_edit(obj)
    obj.recover(@user)
    @js_response = (
        "$j('#content#{obj.unique_content_id}').fadeOut('normal');")
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def change_authorship
    obj = Content.find(params[:content_id]).real_content
    require_user_can_edit(obj)
    new_author = User.find_by_login(params[:login])
    if new_author
      obj.change_authorship(new_author, @user)
      flash[:notice] = 'Autoría cambiada correctamente'
    else
      flash[:error] = "No se ha encontrado al usuario '#{params[:login]}'"
    end
    redirect_to (params[:redirto] || '/')
  end

  def mass_moderate
    if params[:items] then
      params[:deny_reason] = params[:deny_reason_other] if params[:deny_reason] == 'Otra'
      for k in params[:items]
        content = Content.find(k.to_i)
        obj = content.real_content
        require_user_can_edit(obj)

        # TODO borrar caches de portada
        if params[:mass_action] == 'publish' then
          Cms::publish_content(obj, @user)
        elsif params[:mass_action] == 'deny' then
          Cms::deny_content(obj, @user, params[:deny_reason])
        end
      end
    end

    redirect_to '/admin/contenidos'
  end

  def switch_decision
    # TODO this is not a switch, it-s one way
    pd = PublishingDecision.find(params[:id], :include => :content)
    require_user_can_edit pd.content.real_content
    Cms::publish_content(pd.content.real_content, pd.user)
    redirect_to Routing.url_for_content_onlyurl(pd.content.real_content).gsub(
                                                                         'show',
                                                                         'edit')
  end

  def publish_content
    Cms::publish_content(Content.find(params[:id]).real_content,
                         @user, params[:accept_comment])
    flash[:notice] = 'Tu voto se ha contabilizado correctamente. Gracias'
    redirect_to '/admin/contenidos'
  end

  def deny_content
    params[:deny_reason] = params[:deny_reason_other] if params[:deny_reason] == 'Otra'
    if params[:deny_reason].to_s == ''
      flash[:error] = 'Debes especificar una razón para denegar el contenido'
    else
      Cms::deny_content(Content.find(params[:id]).real_content,
                        @user,
                        params[:deny_reason])
      flash[:notice] = 'Tu voto se ha contabilizado correctamente. Gracias'
    end
    redirect_to '/admin/contenidos'
  end

  def report
    @content = Content.find(params[:id])
    raise AccessDenied unless @user.is_hq?

    ttype, scope = SlogEntry.fill_ttype_and_scope_for_content_report(@content)
    sl = SlogEntry.create({:scope => scope,
                           :type_id => ttype,
                           :reporter_user_id => @user.id,
         :headline => "#{Cms.faction_favicon(@content.real_content)}"+
         "<strong><a href=\"#{Routing.url_for_content_onlyurl(
                              @content.real_content)}\">"+
         "#{@content.id}</a></strong> reportado (#{params[:reason]})"+
         " por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>"})
    if sl.new_record?
      flash[:error] = "Error al reportar el contenido:<br />"+
                      "#{sl.errors.full_messages_html}"
    else
      flash[:notice] = "Contenido reportado correctamente"
    end
    render :partial => '/shared/ajax_facebox_feedback', :layout => false
  end

  def close
    params[:reason] = nil if params[:reason] && params[:reason] == 'Razón...'
    @content = Content.find(params[:id]).real_content
    return if @content.closed
    require_user_can_edit(@content)
    if params[:reason].to_s.strip == ''
      flash[:error] = "Debes indicar una razón para cerrar este contenido"
    else
      if @content.close(@user, params[:reason])
        flash[:notice] = "Contenido '#{@content}' cerrado a comentarios."
      else
        flash[:error] = "Error al cerrar contenido:"+
                        " #{@content.errors.full_messages_html}."
      end
    end

    redirect_to gmurl(@content)
  end

  def tag_content
    @content = Content.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @content
    UsersContentsTag.tag_content(@content,
                                 @user,
                                 params[:tags],
                                 delete_missing=false)
    # TODO(slnc): crear los tags por ajax en lugar de redirigir
    redirect_to gmurl(@content)
  end

  def remove_user_tag
    @uct = UsersContentsTag.find(
        :first,
        :conditions => ['user_id = ? AND id = ?', @user.id, params[:id]])
    raise ActiveRecord::RecordNotFound unless @uct
    @content = @uct.content
    @uct.destroy
    @js_response = "$j('#one-of-my-tags#{@uct.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end
