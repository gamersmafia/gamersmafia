# -*- encoding : utf-8 -*-
class SiteController < ApplicationController
  helper :miembros
  CONTACT_MAGIC = 982579815691299191
  VALID_TOPIC = /^[0-9]+\/[a-z1-9&.=]+$/

  def banners
    @title = 'Banners de Gamersmafia'
  end

  def responsabilidades
  end

  def gmcity
    @title = 'Gamersmafia City (por 2_Face)'
  end

  def novedades
    @title = 'Novedades sobre la web'
  end

  def el_callejon
    raise AccessDenied unless user_is_authed
    @title = 'El callejón'
  end

  def portales

  end

  def banners_bottom
    render :layout => false
  end

  def get_banners_of_gallery
    raise ActiveRecord::RecordNotFound unless params[:gallery] && params[:gallery] =~ /[a-zA-Z0-9_-]+/
    @banners = (Dir.entries("#{Rails.root}/public/images/banners/#{params[:gallery]}") - %w(. ..)).sort
    render :layout => false
  end

  def banners_duke
    files = []
    for f in Dir.entries("#{Rails.root}/public/images/banners/duke_nukem")
      if not f.index('_88x31.gif').nil? then
        files<< f
      end # if
    end # for

    filename = files[Kernel.rand(files.length)]
    send_file "#{Rails.root}/public/images/banners/duke_nukem/#{filename}",
              :type => 'image/gif',
              :disposition => 'inline'
  end

  def banners_misc
    files = []
    for f in Dir.entries("#{Rails.root}/public/images/banners")
      if not f.index('misc_120x60_').nil? then
        files<< f
      end # if
    end # for

    filename = files[Kernel.rand(files.length)]
    send_file "#{Rails.root}/public/images/banners/#{filename}",
              :type => 'image/gif',
              :disposition => 'inline'
  end

  def faq
    # TODO cache
    @title = 'Ayuda - FAQ'
  end

  def raise404_if(condition)
    raise ActiveRecord::RecordNotFound if condition
  end

  def rate_content
    self.raise404_if(params[:content_rating].nil? ||
                     params[:content_rating][:rating].nil?)

    params[:content_rating][:ip] = self.remote_ip
    params[:content_rating][:user_id] = @user.id if user_is_authed
    rating = ContentRating.new(params[:content_rating])

    if user_is_authed && @user.can_rate?(rating.content.real_content) then
      rating.save
    elsif !user_is_authed && ContentRating.count(:conditions => ['user_id is null and content_id = ? and ip = ?', rating.content_id, rating.ip]) == 0
      rating.save
    end

    @obj = rating.content.real_content
    render :nothing => true
  end

  def clean_html
    require_auth_users
    if params[:raw_post_data]
      rpd = params[:raw_post_data]
      params[:editorId] = rpd.match('editorId=([a-zA-Z0-9\[\]]+)&')[1]
      params[:content] = rpd.match('editorId=[a-zA-Z0-9\[\]]+&content=(.*)$')[1]
    end
    @content = Cms::clean_html(CGI::unescape(params[:content]))
    response.headers["Content-Type"] = 'text/xml'
    render :layout => false
  end

  def index
    @title = 'Acerca de la web'
  end

  def acercade
    redirect_to '/site' # TODO eliminar en el futuro
  end

  def netiquette
    @title = 'Código de Conducta'
  end

  def chat
    @title = "Chat Gamersmafia"
    @online_users = User.can_login.online.find(
      :all, :order => 'lastseen_on desc', :limit => 100)
  end

  def update_chatlines
    mode = (cookies[:chatpref] == 'big') ? 'big' : 'mini'
    render :layout => false, :action => "update_chatlines_#{mode}"
  end

  def new_chatline
    require_auth_users

    if params[:line].kind_of?(String)
    # TODO copypasted
    chatline = Chatline.new
    chatline.line = params[:line][0..450].strip
    chatline.line = chatline.line.gsub(/</, '&lt;')
    chatline.line = chatline.line.gsub(/>/, '&gt;')
    chatline.user_id = @user.id

    if chatline.line != '' then
      chatline.save
    end

    @title = 'Usuarios Online'
    @user.lastseen_on = Time.now
    @user.save

    @clear_comment_line = true
    end

    if cookies[:chatpref] == 'big'
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_big'
    else
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'faction_id asc, lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_mini'
    end
  end

  def del_chatline
    chatline = Chatline.find(params[:id])
    require_user_can_edit(chatline)
    chatline.destroy
    @title = 'Usuarios Online'
    @clear_comment_line = true

    if cookies[:chatpref] == 'big'
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_big'
    else
      @online_users = User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => 'faction_id asc, lastseen_on desc', :limit => 100)
      render :layout => false, :action => 'update_chatlines_mini'
    end
  end

  def add_to_tracker
    require_auth_users
    content = Content.find(params[:id])
    Users.add_to_tracker(@user, content)
    redirect_to params[:redirto] || gmurl(content)
  end

  def del_from_tracker
    require_auth_users
    content = Content.find(params[:id])
    Users.remove_from_tracker(@user, content)
    redirect_to params[:redirto] || gmurl(content)
  end

  def get_non_updated_tracker_items
    response.headers["Cache-Control"] = "no-cache"
    render :layout => false
    response.headers["Cache-Control"] = "no-cache"
  end

  def trastornos
    @title = 'Trastornos psíquicos'
  end

  def ejemplos_guids
    @title = 'Ejemplos de GUIDs'
    render :layout => 'popup'
  end

  def http_401
    raise AccessDenied
  end

  def http_500
    raise Exception
  end

  def unserviceable_domain
    @title = 'Dominio fuera de servicio'
  end

  def maintain_lock
    require_auth_users
    lock = ContentsLock.find(:first, :conditions => ['id = ? and user_id = ?', params[:id], @user.id])
    raise ActiveRecord::RecordNotFound unless lock
    lock.save
    render :nothing => true
  end

  def macropoll_send
    user_id = user_is_authed ? @user.id : 'NULL'
    if user_is_authed and User.db_query("SELECT * FROM macropolls WHERE poll_id = 1 AND user_id = #{user_id}").size == 0 then
      Bank::transfer(:bank, @user, 10, "Agradecimiento por completar la encuesta global")
      flash[:notice] = "Te hemos ingresado 10GMF como muestra de nuestro agradecimiento. No, no la puedes rellenar más veces."
      User.db_query("INSERT INTO macropolls(poll_id, host, ipaddr, user_id, answers) VALUES(1, '#{request.host}', '#{self.remote_ip}', #{user_id}, '#{YAML::dump(params)}')")
    elsif !user_is_authed
      User.db_query("INSERT INTO macropolls(poll_id, host, ipaddr, user_id, answers) VALUES(1, '#{request.host}', '#{self.remote_ip}', #{user_id}, '#{YAML::dump(params)}')")
    end
    redirect_to :action => :macropoll_thanks
  end

  def macropoll_thanks
  end

  def te_buscamos
    # TODO controls
    @title = 'Te buscamos'
  end

  def cnta
    raise ActiveRecord::RecordNotFound unless params[:url]
    user_id = user_is_authed ? @user.id : 'NULL'
    element_id = (/([a-zA-Z0-9_-])/ =~ params[:element_id]) ? params[:element_id] : 'NULL'
    user_agent = (request.user_agent.to_s != '') ? request.user_agent : ''
    referer = request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : ''
    portal_id = @portal.id != -1 ? @portal.id : 'NULL'
    url = params[:url]
    ip = self.remote_ip
    cka = cookies['__stma']
    if cka
      params['_xvi'] = cka.split('.')[1]
      params['_xsi'] = cka.split('.')[3]
    else
      params['_xvi'] = nil
      params['_xsi'] = nil
    end

    User.db_query("INSERT INTO stats.ads (referer,
                                          user_id,
                                          ip,
                                          user_agent,
                                          portal_id,
                                          visitor_id,
                                          session_id,
                                          url,
                                          element_id)
                                   VALUES (#{User.connection.quote(referer)},
                                            #{user_id},
                                            '#{ip}',
                                            #{User.connection.quote(user_agent)},
                                            #{portal_id},
                                            #{User.connection.quote(params['_xvi'])},
                                            #{User.connection.quote(params['_xsi'])},
                                            #{User.connection.quote(url)},
                                            '#{element_id}')")
    head :created, :location => request.fullpath
  end

  def stats_hipotesis
    require_auth_admins
    @title = "Hipótesis activas"
  end

  def stats_hipotesis_archivo
    require_auth_admins
    @title = "Hipótesis completadas"
  end

  def x
    track
    response.headers["Cache-Control"] = "no-cache"

    # antiguo update_online_state
    # TODO refactorizar y usar stats.pageviews !!!
    # TODO mover a otro sitio
    if user_is_authed then
      #reg
      if @user.lastseen_on.to_i < Time.now.to_i - 60 then
        if @user.lastseen_on.to_i < (Time.now.to_i - 86400 * 90) and (not @user.resurrected_by_user_id.nil? and @user.resurrection_started_on > Time.now - 86400 * 7) then
          # resurrección ejecutada con éxito!
          @user.resurrect
        end

        @user.update_attributes(:lastseen_on => Time.now, :ipaddr => self.remote_ip)
      end
    end
    render :layout => false
  end

  def i
    track(:cookiereq => false)
    send_file "#{Rails.root}/public/images/dot.gif", :type => 'image/gif', :disposition => 'inline'
  end

  def smileys
    # TODO make it cacheable
    render :layout => false
  end

  def search
    params[:id] = params[:searchq]
    redirect_to "http://google.com/search?num=100&filter=0&safe=off&q=site%3Agamersmafia.com #{params[:searchq]}"
  end

  def webmasters
    # @title = "Webmasters"
  end

  def rss
    @title = "RSS"
  end

  def contactar
  end

  def privacidad
    @title = "Política de privacidad"
  end

  def logoe
    if params[:mid]
      se = SentEmail.find(:first, :conditions => ['message_key = ? AND first_read_on is null', params[:mid]])
      se.update_attribute(:first_read_on, Time.now) if se
    end
    send_file "#{Rails.root}/public/skins/default/images/notifications/logo.gif", :type => 'image/gif', :disposition => 'inline'
  end

  def do_contactar
    raise ActiveRecord::RecordNotFound unless params[:subject].to_s != '' && params[:message].to_s != ''
    forbidden = %w(justinmadridsssd@gmail.com seo.sales.traffic@gmail.com traffic.internet.marketing@gmail.com seo.sales.traffic@gamil.com justinmadridsssd@gmail.com)
    if params[:subject] == ''
	    flash[:error] = 'Por favor, elige una categor�a para tu mensaje'
    else
      flash[:notice] = "Mensaje recibido correctamente. Muchas gracias por tu tiempo."
      (redirect_to '/site/contactar' and return) if params[:subject] == 'seo' || (params[:email] && forbidden.include?(params[:email]))
    # TODO más protecciones
    if params[:fsckspmr] && params[:fsckspmr] == self.class.do_contactar_key
      if user_is_authed
        m = Message.create(
          :title => params[:subject],
          :message => params[:message],
          :user_id_from => @user.id,
          :user_id_to => App.webmaster_user_id)
      else
        NotificationEmail.newcontactar(params).deliver
      end
    end
    end

    redirect_to '/site/contactar'
  end

  def album
    @title = "Aquellos maravillosos años"
    @files = Dir.entries("#{Rails.root}/public/images/history").collect { |e| e if  /thumb\-/ =~ e }.compact.sort
  end

  def fusiones
  end

  def webs_de_clanes
    @title = "Webs para clanes gratis"
  end

  def logo
    @title = "Logo de Gamersmafia"
  end

  def sponsor
    raise ActiveRecord::RecordNotFound unless %w(fourfrags nls).include?(params[:sponsor])
    render :template => "site/sponsors_#{params[:sponsor]}"
  end

  def carcel
    @title = "Cárcel"
  end

  def ipinfo
    require_auth_users
    raise AccessDenied unless Authorization.can_edit_users?(@user)
    @ipinfo = Geolocation.ip_info(params[:ip])
    render :layout => false
  end

  def close_content_form
    require_auth_users
    render :layout => false
  end

  def report_content_form
    require_auth_users
    render :layout => false
  end

  def report_comment_form
    require_auth_users
    render :layout => false
  end

  def report_user_form
    require_auth_users
    render :layout => false
  end

  def self.do_contactar_key
    Digest::MD5.hexdigest((CONTACT_MAGIC + (Time.now.to_i / 3600)).to_s)
  end

  def root_term_children
    raise AccessDenied unless user_is_authed
    @term = Term.find(params[:id])
    render :layout => false
  end

  def stream_enable
    require_auth_users
    @user.pref_homepage_mode = "stream"
    redirect_to "/"
  end

  def stream_disable
    require_auth_users
    @user.pref_homepage_mode = ""
    redirect_to "/"
  end

  def suicidal_enable
    require_auth_users
    @user.pref_suicidal = 1
    redirect_to "/"
  end

  def suicidal_disable
    require_auth_users
    @user.pref_suicidal = 0
    redirect_to "/"
  end
end
