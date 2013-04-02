# -*- encoding : utf-8 -*-
require 'cache'
require 'clans'
require 'users'
require 'routing'

class AccessDenied < StandardError; end
class DomainNotFound < StandardError; end

class ApplicationController < ActionController::Base
  VERSIONING_EREG = /^\/(.*\.)[a-z0-9.]+\.(css|js|gif|png|jpg)$/

  include Clans::Authentication
  include Users::Authentication
  include Routing

  helper :account, :miembros, :competiciones, :calendar
  before_filter :ident, :resolve_portal_mode, :check_referer,
                :populate_navpath2, :parse_params_page, :init_xab

  attr_accessor :competition, :global_vars, :portal, :third_menu, :_xad, :smodel_id

  cattr_accessor :navpath2
  around_filter :gm_process
  before_filter :init_start_time

  layout :set_layout

  def init_start_time
    @start_time = Time.now
  end

  private
  def set_layout
    @suicidal = false
    # raise "header: #{request.headers['X-PJAX'].to_s}"
    if request.headers['X-PJAX']
      @suicidal = true
      false
    elsif user_is_authed && @user.pref_suicidal == 1
      @suicidal = true
      "suicidal"
    else
      "default"
    end
  end

  public
  def self.audit(*args)
    after_filter :sys_audit, :only => args
  end

  def self.allowed_portals(class_names)
    before_filter { |c| c.check_portal_access_mode(class_names) }
  end

  def self.require_skill(mode)
    before_filter { |c| c.send(:require_skill, mode) }
  end

  def init_xab
    params['_xab'] = {} unless params['_xab']
    params['_xab'] = ActiveSupport::JSON.decode(CGI::unescape(params['_xab'])) if params['_xab'].kind_of?(String)
    params['_xab_new_treated_visitors'] = {}

    self._xad = [] unless self._xad
    self._xad = params[:_xad] if params[:_xad]
    self._xad = ActiveSupport::JSON.decode(CGI::unescape(self._xad)) if self._xad.kind_of?(String)

    self.smodel_id = params[:id] if self.smodel_id.nil? && params[:id]
  end

  def no_ads
    not App.show_ads
  end

  def save_or_error(model, success_dst, error_render_action)
    @name_action_participe = model.id.nil? ? 'creado' : 'actualizado'
    @name_action_infinitive = model.id.nil? ? 'crear' : 'actualizar'
    if model.save
      flash[:notice] = "#{model.class.name} #{@name_action_participe}" +
                       " correctamente."
      if success_dst.kind_of?(String)
        redirect_to(success_dst.gsub(
          "@#{ActiveSupport::Inflector::underscore(model.class.name)}.id",
        model.id.to_s))
      else
        redirect_to(success_dst)
      end
    else
      flash[:error] = "Error al #{@name_action_infinitive} el" +
                      " #{model.class.name}: #{model.errors.full_messages_html}"
      render :action => error_render_action
    end
  end

  def update_attributes_or_error(model, success_dst, error_render_action)
    if model.update_attributes(
        params[ActiveSupport::Inflector::underscore(model.class.name)])
      flash[:notice] = "#{model.class.name} actualizado correctamente."
      if success_dst.kind_of?(String)
        destination = success_dst.gsub(
          "@#{ActiveSupport::Inflector::underscore(model.class.name)}.id",
        model.id.to_s)
      else
        destination = success_dst
      end

      redirect_to destination
    else
      flash[:error] = "Error al actualizar el #{model.class.name}:" +
                      " #{model.errors.full_messages_html}"
      render :action => error_render_action
    end
  end

  def confirmar_nueva_cuenta(u)
    u.confirm_tasks
    session[:user] = u.id
  end

  def parse_params_page
    params[:page] = params[:page].to_i if params[:page]
  end

  def redirto_or(alt)
    redirect_to(params[:redirto] ? params[:redirto] : alt)
  end

  def current_default_portal
    user_is_authed ? @user.default_portal : cookies[:defportalpref]
  end

  def can_set_as_default_home
    controller_name == 'home' && current_default_portal != action_name
  end

  def sys_audit
    params_copy = request.parameters.clone
    %w(password password_confirmation k vk).each do |sensible_key|
      params_copy[sensible_key] =  "*****" if params_copy.has_key?(sensible_key)
    end

    id_prefix = ''
    %w(login email).each do |id_keyword|
      if params_copy.has_key?(id_keyword)
        id_prefix = " [#{id_keyword}=#{params_copy[id_keyword]}]"
        break
      end
    end

    headline = "[#{controller_path}] [#{action_name}]"
    headline<< " [id=#{params[:id]}]" if params[:id]
    headline<< id_prefix
    headline<< " [sess_user_id=#{@user.id}]" if user_is_authed

    info = """-------------------------------
Request information:
-------------------------------
* URL: #{request.protocol}#{request.host}#{request.fullpath}
* Remote IP: #{self.remote_ip}
* Parameters: #{params_copy.inspect}</code>"""
    Alert.create({:type_id => Alert::TYPES[:info],
                      :headline => headline, :info => info,
                      :reviewer_user_id => User.find_by_login('MrAchmed').id,
                      :completed_on => Time.now})
  end

  public
  def remote_ip
    @remote_ip ||= begin
      http_headers = []
      if env.include?("HTTP_X_FORWARDED_FOR")
        http_headers.append('HTTP_X_FORWARDED_FOR')
      end
      http_headers.append('REMOTE_ADDR')

      remote_ips = []
      http_headers.each do |http_header|
        ips = env[http_header]
        next unless ips
        ips.gsub!(',', ' ')
        remote_ips.concat(ips.split(' '))
      end

      remote_ips = remote_ips.uniq.reject do |ip|
        (ip =~ /^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i ||
         ip == 'unknown' ||
         ip == '127.0.0.1' ||
         ip.strip == '')
      end

      remote_ips.append('127.0.0.1')
      remote_ips.first
    end
  end

  def check_referer
    if params[:rusid].to_i > 0
      Stats.delay.register_referer(
          params[:rusid].to_i, self.remote_ip, request.env["HTTP_REFERER"])
    elsif params[:rusid]
      Rails.logger.warn("No user found with id '#{params[:rusid]}'")
    end
  end

  def submenu
    nil
  end

  def url_for_content(object, text)
    self.class.url_for_content(object, text)
  end

  def url_for_content_onlyurl(object)
    Routing.url_for_content_onlyurl(object)
  end

  # DEPRECATED Use Routing.url_for
  def gmurl(object, opts={})
    Routing.gmurl(object, opts)
  end


  # Used to be able to leave out the action
  def gm_process
    GlobalVars.flush_cache
    params[:page] = 1 if params.has_key?(:page) && params[:page].to_i < 1
    @madness = true
    @_track_done = false
    seconds = Benchmark.realtime do
      catch(:abort) do
        yield
      end
    end

    track_404_errors if response.status == 404
    response.headers['X-UserId'] = @user ? @user.id.to_s : '-'
    response.headers['X-Controller'] = controller_name
    response.headers['X-Action'] = action_name
    response.headers['X-ModelId'] = params[:id] ? "#{params[:id]}" : '-'
    response.headers['X-PortalId'] = portal ? portal.id.to_s : '-'
    response.headers['X-SessionId'] = request.session_options ? request.session_options[:id].to_s : '-'
    response.headers['X-VisitorId'] = params['_xnvi'] ? params['_xnvi'].to_s : '-'
    response.headers['X-AbTreatment'] = params['_xab'] ? params['_xab'].to_json : '-'
    response.headers['X-AdsShown'] = self._xad ? self._xad.join(',') : '-'

    begin
      Stats.pageloadtime(self, seconds, response, controller_name, action_name,
                         portal)
    rescue
      raise unless Rails.env == 'test'
    end
  end

  public
  def skin
    if self.portal.nil?
      Rails.logger.warn("portal is nil. Using GmPortal")
      self.portal = GmPortal.new
    end

    if user_is_authed && @user.pref_skin
      begin
        Skin.find(@user.pref_skin.to_i)
      rescue ActiveRecord::RecordNotFound
        @user.preferences.find_by_name('skin').destroy
        Skin.find_by_hid('default')
      end
    elsif params['skin']
      Skin.find(params['skin'].to_i) || Skin.find_by_hid('default')
    elsif portal.skin_id != nil
      Skin.find(portal.skin_id) || Skin.find_by_hid('default')
    else
      portal.skin # Skin.find_by_hid(portal)
    end
  end

  def check_portal_access_mode(allowed_portals)
    portal_sym = ActiveSupport::Inflector::singularize(
        ActiveSupport::Inflector::underscore(
            @portal.class.name.gsub('Portal', ''))
    ).to_sym
    if defined?(allowed_portals) and not allowed_portals.include?(portal_sym)
      raise ActiveRecord::RecordNotFound
    end
  end

  def portal_code
    @portal.code if @portal
  end

  def is_crawler?
    @_is_crawler ||= (/bot|mediapartners|slurp/i =~ request.user_agent)
  end

  def track_500_errors
    day = Time.now.strftime("%Y%m%d")
    Keystore.incr("http.global.errors.500.#{day}")
  end

  def track_404_errors
    day = Time.now.strftime("%Y%m%d")
    if (request.env["HTTP_REFERER"] || "").index('gamersmafia').nil?
      Keystore.incr("http.global.errors.external_404.#{day}")
    else
      Keystore.incr("http.global.errors.internal_404.#{day}")
      # uri = "http://#{request.env['HTTP_X_FORWARDED_HOST']}#{request.fullpath}"
      # SystemNotifier.deliver_notification404_notification(
      #     request.fullpath, request.env['HTTP_REFERER'], request)
    end
  end

  def http_404
    # solo capturamos estas URLs cuando ejecutamos en desarrollo
    if App.port != 80
      res = request.fullpath.match(VERSIONING_EREG)
      if res
        if %w(gif png jpg).include?(res[2])
          base = 'image'
        else
          base = 'text'
        end
        if res[2] == 'js'
          ext = 'javascript'
        else
          ext = res[2]
        end
        response.headers["Content-Type"] = "#{base}/#{ext}"
        if %w(css js).include?(res[2])
          render :file => "#{Rails.root}/public/#{res[1]}#{res[2]}"
        else
          send_file "#{Rails.root}/public/#{res[1]}#{res[2]}"
        end
      else
        @title = "Página no encontrada (Error 404)"
        render :file => "#{Rails.root}/app/views/application/http_404.html.erb", :status => 404
      end
    else
      @title = "Página no encontrada (Error 404)"
      render :file => "#{Rails.root}/app/views/application/http_404.html.erb", :status => 404
    end
  end

  def handle_http_401
    @title = "Acceso Denegado (Error 401)"
    render :file => "#{Rails.root}/app/views/application/http_401.html.erb", :status => 401
  end

  def rescuiing
    @rescuiing || false
  end

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, :with => :render_error
  end

  def render_error(exception)
    @rescuiing = true
    case exception
      when ActiveRecord::RecordNotFound
      http_404

      when ActionController::UnknownHttpMethod
      handle_http_401

      when DomainNotFound
      redirect_to("http://#{App.domain}", :status => 301)

      when ContentLocked
      render :template => 'application/content_locked', :status => 403

      when AccessDenied
      handle_http_401

      when ::AbstractController::ActionNotFound, ::ActionController::RoutingError
      if request.path.index('www.') != nil then
        redirect_to("http://#{request.path[request.path.index('www.')..-1]}",
                    :status => 301)
      else
        http_404
      end
    else
      track_500_errors
      ExceptionNotifier::Notifier.exception_notification(
        request.env, exception).deliver
      begin
        render :template => 'application/http_500', :status => 500
      rescue
        render(:file => "#{Rails.root}/public/500.html", :status => 500)
      end
    end
    @rescuiing = false  # para tests
  end


  # Saves information about the current page being served.
  def track(opts={})
    # Tracks
    opts = { :redirecting => false, :cookiereq => true }.merge(opts)
    user_id = user_is_authed ? @user.id : 'NULL'
    user_agent = request.user_agent.to_s != '' ? request.user_agent : ''
    cka = cookies['__stma']

    return if @_track_done # no entiendo por qué está pasando pero se llama dos veces desde redirect_to

    return if !cka && opts[:cookiereq] # no trackeamos lo que no podemos cookear

    if opts[:redirecting]
      params['_xvi'] = cka.split('.')[1]
      params['_xsi'] = cka.split('.')[3]
      params['_xmi'] = params[:id]
      params['_xc'] = controller_name
      params['_xa'] = action_name
      url = request.fullpath
    else
      url = params['_xu']
    end
    @_track_done = true

    # si el user_id tiene un visitor_id ya asignado en users usamos ese
    if user_is_authed
      if @user.visitor_id.to_s != ''
        cookies['__stma'] = { :domain => COOKIEDOMAIN, :expires => 2.years.since,
                              :value => cookies['__stma'].gsub(params['_xvi'],
          @user.visitor_id) }
        params['_xvi'] = @user.visitor_id
      else
        if User.find_by_visitor_id(params['_xvi']) # otro usuario se ha conectado desde ese pc
          new_visitor_id = (Kernel.rand * 2147483647).to_i.to_s # TODO no debería repetirse
          @user.visitor_id = new_visitor_id
          cookies['__stma'] = { :domain => COOKIEDOMAIN, :expires => 2.years.since,
                                :value => cookies['__stma'].gsub(params['_xvi'],
            @user.visitor_id) }
          params['_xvi'] = @user.visitor_id
        else # primer visitor_id del usuario
          @user.update_attribute(:visitor_id, params['_xvi'])
        end
      end
    end

    if params['_xab'].to_s != '' then # check que lo hayamos añadido a treated_visitors
      # TODO debemos modificar el _xab enviado de forma que no lo puedan adulterar para manipular los tests
      # TODO esto debe ir en AbTest
      params['_xab'].each do |test_id, treatment_id|
        test_id = test_id.to_i
        treatment_id = treatment_id.to_i

        #if user_is_authed
        # tu = TreatedUser.find(:first, :conditions => [:ab_test_id => test_id.to_i, visitor_id => params['_xvi'].to_s])
        #end
        if user_is_authed
          dbu = User.db_query("SELECT *
                               FROM treated_visitors
                              WHERE ab_test_id = #{test_id.to_i}
                                AND (visitor_id = #{User.connection.quote(params['_xvi'].to_s)}
                                 OR user_id = #{@user.id})
                            ORDER BY id")
        else
          dbu = User.db_query("SELECT *
                               FROM treated_visitors
                              WHERE ab_test_id = #{test_id.to_i}
                                AND visitor_id = #{User.connection.quote(params['_xvi'].to_s)}")
        end

        if dbu.size == 0
          if user_is_authed
            User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment, user_id) VALUES(#{test_id}, #{User.connection.quote(params['_xvi'].to_s)}, #{treatment_id}, #{@user.id});")
          else
            User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment) VALUES(#{test_id}, #{User.connection.quote(params['_xvi'].to_s)}, #{treatment_id});")
          end
        else

          if dbu.size == 1 and user_is_authed && treatment_id.to_i != dbu[0]['treatment'].to_i
            if dbu[0]['user_id'].to_i != @user.id # dos users usan el mismo pc
              new_visitor_id = (Kernel.rand * 2147483647).to_i.to_s
              cookies['__stma'] = { :value => cookies['__stma'].gsub(params['_xvi'], new_visitor_id), :domain => COOKIEDOMAIN, :expires => 2.years.since}
              params['_xvi'] = new_visitor_id # order is important
              User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment, user_id) VALUES(#{test_id}, #{User.connection.quote(params['_xvi'].to_s)}, #{treatment_id}, #{@user.id});")
            elsif dbu.size == 1 && dbu[0]['visitor_id'] != params['_xvi'] # mismo user desde 2 pcs distintos
              cookies['__stma'] = { :value => cookies['__stma'].gsub(params['_xvi'], dbu[0]['visitor_id']), :domain => COOKIEDOMAIN, :expires => 2.years.since}
              params['_xvi'] = dbu[0]['visitor_id']
              User.db_query("UPDATE treated_visitors SET treatment = #{treatment_id.to_i}, user_id = #{@user.id} WHERE id = #{dbu[0]['id']};")
            else
              User.db_query("UPDATE treated_visitors SET treatment = #{treatment_id.to_i}, user_id = #{@user.id} WHERE id = #{dbu[0]['id']};")
            end

            # TODO analizar hits pasados y actualizarlos correspondiente aunque no es tan grave ya que como ahora ya no figura en tabla treated_visitors esos hits/conversiones se ignorarán hasta el punto en que el usuario se autentificó
            # En caso de que dos usuarios usen el mismo pc ahora mismo se asigna un nuevo visitor_id
            # al nuevo usuario de forma que no se machaque. Cuando el nuevo user haga login en otro pc
            # el sistema cogerá el tratamiento adecuado
            # si un user_id, test ya se encuentra en treated_visitors para un visitor_id que ahora se identifica como otro user hay que crear un nuevo visitor_id
          end
        end
      end
      params['_xab'] = params['_xab'].to_json
    end

    referer = params['_xr'] ? params['_xr'] :  (request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : '-')

    medium = params['_xm'] ? params['_xm'] : 'default'
    campaign = params['_xca'] ? params['_xca'] : '-'
    ip = self.remote_ip
    # TODO PERF guardar informacion del visitante en tabla aparte
    user_agent = user_agent.bare if user_agent
    if self.portal.nil? || self.portal.id.nil?
      self.portal = GmPortal.new
      Rails.logger.warn("portal is nil. Using GmPortal")
    end
    # flash_error = #{User.connection.quote(params['_xe'])}
    User.db_query("INSERT INTO stats.pageviews(referer,
                                               user_id,
                                               ip,
                                               url,
                                               campaign,
                                               flash_error,
                                               abtest_treatment,
                                               ads_shown,
                                               source,
                                               medium,
                                               user_agent,
                                               portal_id,
                                               visitor_id,
                                               session_id,
                                               model_id,
                                               controller,
                                               action)
                                   VALUES (#{User.connection.quote(referer)},
                                            #{user_id},
                                            '#{ip}',
                                            #{User.connection.quote(url)},
                                            #{User.connection.quote(campaign)},
                                            '',
                                            #{User.connection.quote(params['_xab'])},
                                            #{User.connection.quote(self._xad)},
                                            #{User.connection.quote(params['_xs'])},
                                            #{User.connection.quote(medium)},
                                            #{User.connection.quote(user_agent)},
                                            #{self.portal.id},
                                            #{User.connection.quote(params['_xvi'])},
                                            #{User.connection.quote(params['_xsi'])},
                                            #{User.connection.quote(params['_xmi'])},
                                            #{User.connection.quote(params['_xc'])},
                                            #{User.connection.quote(params['_xa'])}
                  )")
  end

  def redirect_to(*args)
    track(:redirecting => true)
    super
  end


  protected
  def track_item(obj)
    if user_is_authed
      tracker_item = TrackerItem.find(:first, :conditions => ["user_id = ? and content_id = ? and lastseen_on is not null", @user.id, obj.unique_content.id])
      if (tracker_item && tracker_item.lastseen_on)
        @object_lastseen_on =  tracker_item.lastseen_on
        @first_time_content = false
      else
        @first_time_content = true
      end
    end

    user_is_authed ? obj.hit_reg(@user) : obj.hit_anon
  end


  # TODO: move to helpers
  def populate_navpath2
    self.class.navpath2 = []
    self.class.navpath2<< [controller_name.titleize, "/#{self.class.controller_path}"] unless action_name == 'index'
  end

  public
  def navpath2
    self.class.navpath2
  end

  def title
    @title ||= begin
      if (@title.to_s != '')
        @title
      else
        if action_name == 'index'
          controller_name.humanize
        else
          action_name.humanize
        end
      end
    end
  end

  def get_category_address(category, taxonomy)
    paths = []
    navpath = []
    return [] unless category
    paths << category.name

    href = Cms::translate_content_name(Cms.extract_content_name_from_taxonomy(taxonomy))
    href2 = href.normalize

    navpath << [category.name, "/#{href2}/#{category.id}"]

    while category.parent
      category = category.parent
      paths << category.name
      navpath << [category.name, "/#{href2}/#{category.id}"]
    end

    paths = paths.reverse
    navpath = [[ActiveSupport::Inflector::titleize(href), "/#{href2}"], ] + navpath.reverse

    return paths, navpath
  end

  def admin_menu_items
    return [] unless user_is_authed

    items = []
    if Authorization.can_edit_ads_directly?(@user)
      items<< ['Ads', '/admin/ads']
      items<< ['Ads Slots', '/admin/ads_slots']
    end

    if Authorization.can_access_experiments?(@user)
      items<< ['Hipótesis', '/admin/hipotesis']
    end

    if Authorization.can_admin_all_items?(@user)
      items<< ['Avatares', '/avatares']
      items<< ['Clanes', '/admin/clanes']
      items<< ['Competiciones', '/admin/competiciones']
      items<< ['Facciones', '/admin/facciones']
      items<< ['Juegos', '/admin/juegos']
      items<< ['IP Bans', '/admin/ip_bans']
      items<< ['IPs Duplicadas', '/admin/usuarios/ipsduplicadas']
      items<< ['Mapas', '/admin/mapas_juegos']
      items<< ['Portales', '/admin/portales']
      items<< ['Tags', '/admin/tags']
      items<< ['Users', '/admin/usuarios']
      items<< ['Tienda', '/admin/tienda']
      items<< ['Violaciones Netiqueta', '/comments/violaciones_netiqueta']
    end

    if Authorization.can_admin_toplevel_terms?(@user)
      items<< ['Cat Contenidos', '/admin/categorias']
    end

    if Authorization.can_edit_faq?(@user)
      items<< ['Entradas FAQ', '/admin/entradasfaq']
      items<< ['Cat FAQ', '/admin/categoriasfaq']
    end

    if Authorization.can_admin_bazar_districts?(@user)
      items<< ['Distritos bazar', '/admin/bazar_districts']
    end

    # ordenamos las entradas
    items2 = {}
    items.each { |i| items2[i[0]] = i[1] }
    items3 = []
    items2.keys.sort.each { |k| items3<< [k, items2[k]]}

    items3
  end

  def clanes_menu_items
    l = []

    if @user.last_clan_id then
      l<<['Portada', '/cuenta/clanes']

      if @clan.user_is_clanleader(@user.id) then
        l<<['Configuración', '/cuenta/clanes/configuracion']
        l<<['Miembros', '/cuenta/clanes/miembros']
        l<<['Clanes amigos', '/cuenta/clanes/amigos']
        l<<['Sponsors', '/cuenta/clanes/sponsors']
        l<<['Banco', '/cuenta/clanes/banco']
        if @portal.kind_of?(ClansPortal)
          l<<['Categorías de contenidos', "/admin/categorias"]
          l<<['Skin', "/cuenta/skins/edit/#{@portal.skin_id}"]
        end
      end
    end

    l
  end
end
