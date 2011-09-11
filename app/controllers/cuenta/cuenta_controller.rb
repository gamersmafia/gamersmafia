class Cuenta::CuentaController < ApplicationController
  # TODO wtf?? o lo uno o lo otro
  before_filter :require_auth_users, :except => [:login, :do_login, :alta, :bienvenido, :create, :create2, :olvide_clave, :do_olvide_clave, :do_change_email, :reset, :do_reset, :confirmar, :do_confirmar, :resendsignup, :username_check, :email_check]
  before_filter :only_non_registered, :only => [:login, :do_login, :alta, :bienvenido, :create2, :create, :olvide_clave, :do_olvide_clave, :reset, :do_reset, :confirmar, :do_confirmar, :username_check, :email_check]
  audit :do_reset, :do_olvide_clave, :do_change_email
  
  def index
    @navpath = [['Cuenta', '/cuenta'],]
    @title = 'Cuenta'
  end
  
  def tracker
    @navpath = [['Cuenta', '/cuenta'], ['Tracker', '/cuenta/tracker']]
    @title = 'Tracker'
  end
  
  def alta
    @no_ads = true
  end
  
  def mis_permisos
    
  end
  
  def del_role
    @user.users_roles.find(params[:id]).destroy
    render :nothing => true
  end
  
  def add_quicklink
    Personalization.add_quicklink(@user, params[:code], params[:url])
    render :nothing => true
  end
  
  def del_quicklink
    Personalization.del_quicklink(@user, params[:code])
    render :nothing => true
  end
  
  def add_user_forum
    Personalization.add_user_forum(@user, params[:id], params[:url])
    render :nothing => true
  end
  
  def del_user_forum
    Personalization.del_user_forum(@user, params[:id])
    render :nothing => true
  end
  
  def update_user_forums_order
    Personalization.update_user_forums_order(@user, (params[:buckets1] || []), (params[:buckets2] || []), (params[:buckets3] || []))
    render :nothing => true
  end
  
  def save_tracker_config
    @user.update_attributes(params[:user].pass_sym(:tracker_autodelete_old_contents, :comment_adds_to_tracker_enabled))
    flash[:notice] = 'Opciones del tracker guardadas correctamente'
    redirect_to '/cuenta/cuenta/tracker'
  end
  
  def resurrect
    u = User.find_by_login(params[:login])
    if u
      if u.start_resurrection(@user) # TODO revisar que se haga bien
        @resurrected_user = u
        flash[:notice] = 'Conexión con el mundo de los muertos establecida, Resurrección iniciada correctamente.'
      else
        flash[:notice] = 'Error al intentar resucitar al usuario.'
      end
    else
      flash[:error] = "No se ha encontrado al usuario #{params[:login]}"
    end
  end
  
  def configuracion
    @navpath = [['Cuenta', '/cuenta'], ['Configuración', '/cuenta/configuracion']]
    @title = 'Configuración'
  end
  
  def login
    redirect_to '/cuenta' if user_is_authed
  end
  
  def create2
   (redirect_to '/cuenta' and return) if cookies[:adn3]
    if params[:user].nil?
      flash[:error] = 'Datos de usuario no encontrados'
      redirect_to '/cuenta/alta'
    else
      params[:user][:email_confirmation] = params[:user][:email]
      params[:user][:password_confirmation] = params[:user][:password]
      @mmode = :new
      create
    end
  end
  
  def create
   (redirect_to '/' and return) if cookies[:adn3]
   (redirect_to '/cuenta' and return) if user_is_authed && @user.state != User::ST_UNCONFIRMED
   (redirect_to '/cuenta/alta' and return) unless params.has_key?(:user) and not(params[:user][:email] =~ /trash-mail.de/)
    
     (redirect_to '/' and return) if cookies[:adn3]
     (redirect_to '/' and return) if User.count(:conditions => ['lastseen_on >= now() - \'1 day\'::interval AND ipaddr = ? AND state = ?', request.remote_ip, User::ST_BANNED]) >= 1
    
     (redirect_to '/' and return) if User.count(:conditions => ['lastseen_on >= now() - \'1 day\'::interval AND ipaddr = ?', request.remote_ip]) > 5
    
    params[:user] = params[:user].pass_sym(:login, :email, :email_confirmation, :image, :firstname, :lastname, :faction_id, :password, :password_confirmation, :email, :email_confirmation)
    params[:user][:state] = User::ST_UNCONFIRMED
    params[:user][:ipaddr] = request.remote_ip
    params[:user][:lastseen_on] = Time.now
    @newuser = User.new(params[:user])
    
    @mmode ||= :old
    
    if (not params[:referer].nil?) and params[:referer] != '' then
      referer = User.find_by_login(params[:referer])
      if referer
        @newuser.referer_user_id = referer.id
      else
        flash[:error] = 'El usuario referido especificado no se ha encontrado aunque no impedirá que se cree la cuenta.'
      end
    end
    ban = IpBan.find(:first, :conditions => ['ip = ? and (expires_on IS NULL or expires_on >= now())', request.remote_ip])
    if ban
      # Si está baneado le hacemos ver que todo va bien para que se quede esperando el mensaje de confirmación
      nagato = User.find_by_login('nagato')
      SlogEntry.create({:type_id => SlogEntry::TYPES[:security], :headline => "IP baneada #{request.remote_ip} (#{ban.comment}) ha intentado crearse una cuenta"})      
      flash[:notice] = "Te hemos enviado un mensaje a #{@newuser.email} con la clave de confirmación."
      redirect_to('/cuenta/confirmar') and return
    elsif Cms::EMAIL_REGEXP =~ @newuser.email && User::BANNED_DOMAINS.include?(@newuser.email.split('@')[1].downcase)
      flash[:error] = "El dominio #{@newuser.email.split('@')[1]} está baneado por abusos. Por favor, elige otra cuenta de correo."
      render :action => :alta
    elsif @newuser.save
      if User.count(:conditions => ['ipaddr = ?', request.remote_ip]) > 1
        prev = User.find(:first, :conditions => ['ipaddr = ? AND id <> ?', request.remote_ip, @newuser.id])
        nagato = User.find_by_login('nagato')
        SlogEntry.create({:type_id => SlogEntry::TYPES[:security], 
          :headline => "Registro desde IP existente <strong><a href=\"#{gmurl(@newuser)}\">#{@newuser.login}</a></strong> (#{request.remote_ip}): "<< (User.find(:all, :conditions => ['ipaddr = ? and id <> ?', request.remote_ip, @newuser.id]).collect {|u| "<a href=\"#{gmurl(u)}\">#{u.login}</a>"}).join(', ')})
        
        Notification.deliver_signup(@newuser, :mode => @mmode)
        flash[:notice] = "Te hemos enviado un mensaje a #{@newuser.email} con la clave de confirmación."
        redirect_to "/cuenta/confirmar?em=#{@newuser.email}" and return
      else # no parece un usuario sospechoso
        confirmar_nueva_cuenta(@newuser)
        flash[:notice] = "Cuenta confirmada correctamente. Te hemos enviado un email de bienvenida a <strong>#{@newuser.email}</strong> con instrucciones."
        redirect_to '/cuenta'
      end
      cookies[:email] = {:value => @newuser.email, :expires => 7.days.since, :domain => COOKIEDOMAIN}
    else
      flash[:error] ||= ''
      flash[:error] << '<br />' << @newuser.errors.full_messages.join('<br />')
      render :action => :alta
    end
  end
  
  def mis_borradores
    @title = "Mis borradores"
  end
  
  def do_login
   (redirect_to '/cuenta/login' and return) unless (params[:login] && params[:password] && cookies[:adn3].nil?)
    cookies[:login] = {:value => params[:login], :expires => 10.years.since, :domain => COOKIEDOMAIN}
    u = User.login(params[:login], params[:password])
    if u then
      if u.state == User::ST_UNCONFIRMED
        flash[:error] = "La cuenta \"#{u.login}\" está pendiente de confirmación."
        render :action => 'login'
      elsif u.state == User::ST_DISABLED
        flash[:error] = "La cuenta \"#{u.login}\" está deshabilitada."
        render :action => 'login'
      elsif u.state == User::ST_BANNED
        cookies[:adn3] = {:value => u.id.to_s, :expires => 7.days.since, :domain => COOKIEDOMAIN}
        flash[:error] = "La cuenta \"#{u.login}\" está baneada."
        render :action => 'login'
      else # todo bien
        session[:user] = u.id
        flash[:notice] = 'Inicio de sesión correcto'
        if params[:redirto] && params[:redirto] != '' && !(/login/ =~ params[:redirto])
          redirect_to params[:redirto]
        else
          redirect_to '/'
        end
      end
    else
      flash[:error] = 'Nombre de usuario o clave incorrectos'
      redirect_to '/cuenta/login'
    end
  end
  
  def update_configuration
    @navpath = [['Cuenta', '/cuenta'], ['Configuración', '/cuenta/configuracion']]
    @title = 'Configuración'
    
    notice = ''
    
    @user.update_attributes(params[:user].pass_sym(:password, :password_confirmation))
    @newuser = User.find(:first, :conditions => ["login = ? AND state <> #{User::ST_UNCONFIRMED}", @user.login])
    
    if @user.errors.size > 0
      flash[:error] = @user.errors.full_messages.join('<br />')
    elsif params[:user][:password_confirmation].to_s != ''
      flash[:notice] = 'Contraseña cambiada correctamente.'
    end
    
    
    sentemail = false
    if not params[:user][:newemail].empty? and params[:user][:newemail] != @user.email
      tmpuser = User.find(:first, :conditions => ["email = ?",params[:user][:newemail]])
      if User.find_by_email(params[:user][:newemail]).nil?
        @newuser.newemail = params[:user][:newemail]
        sentemail = true
        @newuser.generate_validkey
        
        Notification.deliver_emailchange(@newuser)
      else
        notice = "Ya hay una cuenta usando el email \"#{params[:user][:newemail]}\"."
      end
    end
    
    if not notice.empty?
      flash[:notice] = notice
    else
      if not @newuser.nil? and @newuser.save
        if sentemail == true
          flash[:notice] = 'Te hemos enviado un email para confirmar los cambios.'
        end
        @user.reload
      else
        flash[:notice] = 'Ha ocurrido un error al guardar la configuración.'
      end
    end
    redirect_to :action => 'configuracion'
  end
  
  def resendnewemail
   (redirect_to '/cuenta' and return) if cookies[:adn3]
    Notification.deliver_emailchange(@user)
    flash[:notice] = "Te hemos enviado un email a #{@user.newemail} para confirmar el cambio."
    redirect_to '/cuenta'
  end
  
  def perfil
    @navpath = [['Cuenta', '/cuenta'], ['Perfil', '/cuenta/perfil']]
    @title = 'Perfil'
  end
  
  def update_profile
    # TODO move this if we can optimize it
    @newuser = User.find(:first, :conditions => ["login = ? AND state <> #{User::ST_UNCONFIRMED}", @user.login])
    @newuser.lastname = strip_tags(params[:post][:lastname])
    @newuser.firstname= strip_tags(params[:post][:firstname])
    @newuser.birthday = Date.new(params[:post]['birthday(1i)'].to_i,params[:post]['birthday(2i)'].to_i, params[:post]['birthday(3i)'].to_i) if params[:post]['birthday(1i)']
    @newuser.msn = strip_tags(params[:post][:msn])
    @newuser.googletalk = strip_tags(params[:post][:googletalk])
    @newuser.yahoo_im = strip_tags(params[:post][:yahoo_im])
    @newuser.wii_code = strip_tags(params[:post][:wii_code].to_s.gsub(' ', '').gsub('-', ''))
    @newuser.gamertag = strip_tags(params[:post][:gamertag])
    @newuser.psnid = strip_tags(params[:post][:psnid])
    @newuser.xfire = strip_tags(params[:post][:xfire])
    @newuser.irc = strip_tags(params[:post][:irc])
    @newuser.steam = strip_tags(params[:post][:steam])
    @newuser.hw_mouse = strip_tags(params[:post][:hw_mouse])
    @newuser.hw_processor = strip_tags(params[:post][:hw_processor])
    @newuser.hw_motherboard = strip_tags(params[:post][:hw_motherboard])
    @newuser.hw_ram = strip_tags(params[:post][:hw_ram])
    @newuser.hw_hdd = strip_tags(params[:post][:hw_hdd])
    @newuser.hw_graphiccard = strip_tags(params[:post][:hw_graphiccard])
    @newuser.hw_monitor = strip_tags(params[:post][:hw_monitor])
    @newuser.hw_soundcard = strip_tags(params[:post][:hw_soundcard])
    @newuser.hw_headphones = strip_tags(params[:post][:hw_headphones])
    @newuser.hw_connection = strip_tags(params[:post][:hw_connection])
    @newuser.homepage = strip_tags(params[:post][:homepage])
    @newuser.description = strip_tags_allowed((params[:post][:description]), ['object', 'embed', 'param'] + ActionViewMixings::DEF_ALLOW_TAGS)
    @newuser.city = strip_tags(params[:post][:city])
    @newuser.ipaddr = request.remote_ip
    @newuser.country_id = params[:user][:country_id] # TODO hackk
    @newuser.photo = params[:user][:photo] if params[:user][:photo]
    @newuser.competition_roster = params[:user][:competition_roster]
    @newuser.profile_last_updated_on = Time.now
    
    if params[:sex].to_i == 0 then
      @newuser.sex = 0
    elsif params[:sex].to_i == 1
      @newuser.sex = 1
    end
    
    save_or_error(@newuser, '/cuenta/cuenta/perfil', :perfil)
    @user.reload
    #flash[:notice] = 'Perfil guardado correctamente.'
    #redirect_to :action => 'perfil'
  end
  
  def notificaciones
    @navpath = [['Cuenta', '/cuenta'], ['Notificaciones', '/cuenta/notificaciones']]
    @title = 'Notificaciones'
  end
  
  def amigos
    @navpath = [['Cuenta', '/cuenta'], ['Amigos', '/cuenta/amigos']]
    @title = 'Amigos'
  end
  
  def update_notifications
    newuser = User.find(@user.id)
    newuser.notifications_global = params[:user][:notifications_global]
    newuser.notifications_newmessages = params[:user][:notifications_newmessages]
    newuser.notifications_newregistrations = params[:user][:notifications_newregistrations]
    newuser.notifications_trackerupdates = params[:user][:notifications_trackerupdates]
    newuser.notifications_newprofilesignature = params[:user][:notifications_newprofilesignature] if params[:user][:notifications_newprofilesignature] && @user.enable_profile_signatures?
    newuser.save
    flash[:notice] = 'Preferencias de notificaciones guardadas correctamente.'
    redirect_to :action => 'notificaciones'
  end
  
  def estadisticas
    @navpath = [['Cuenta', '/cuenta'], ['Estadísticas', '/cuenta/estadisticas']]
    @title = 'Estadísticas'
  end
  
  def estadisticas_hits
    @navpath = [['Cuenta', '/cuenta'], ['Estadísticas', '/cuenta/estadisticas'], ['Hits', '/cuenta/estadisticas/hits']]
    @title = 'Estadísticas de visitas referidas'
  end
  
  def estadisticas_registros
    @navpath = [['Cuenta', '/cuenta'], ['Estadísticas', '/cuenta/estadisticas'], ['Registros', '/cuenta/estadisticas/registros']]
    @title = 'Estadísticas de registros'
  end
  
  def imagenes
    render :layout => 'popup'
  end
  
  def subir_imagen
    newfile = params[:file]
    if newfile.respond_to?(:original_filename) then
      if newfile.original_filename.match(Cms::IMAGE_FORMAT) then
        @user.upload_file(newfile)
      elsif newfile.original_filename.match(/\.zip$/i) then
        # creamos tmp dir
        tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
        # descomprimimos
        if not newfile.path then
          tmpfile = File.open("#{tmp_dir}.zip", 'w+') do |f|
            f.write(newfile.read())
          end
          path = "#{tmp_dir}.zip"
        else
          path = newfile.path
        end
        
        system ("unzip -q -j #{path} -d #{tmp_dir}")
        # añadimos imgs al dir del usuario
        for f in (Dir.entries(tmp_dir) - %w(.. .))
          ff = File.open("#{tmp_dir}/#{f}")
          @user.upload_file(ff)
          ff.close
        end
        
        # limpiamos
        system("rm -r #{tmp_dir}")
      end
    end
    
    redirect_to "/cuenta/imagenes?sEditorId=#{params[:sEditorId]}"
  end
  
  def borrar_imagen
    @user.del_my_file(params[:filename])
    # render :nothing => true TODO error javascript al intentar borrar: components is not defined
    render :nothing => true
  end
  
  
  def save_avatar
    # TODO validation checks!
    if params[:new_avatar_id].to_s.strip == ''  then
      params[:new_avatar_id] = nil
      flash[:error] = 'Debes elegir un avatar'
    else
      @user.change_avatar(params[:new_avatar_id])
      flash[:notice] = "Avatar cambiado correctamente"
    end
    
    redirect_to :action => 'avatar'
  end
  
  def custom_avatars_set
    @user.avatars.find(:all, :conditions => 'path is null or path = \'\'', :order => 'id ASC').each do |a|
      a.update_attributes({:path => params[:custom_avatars][a.id.to_s]}) if params[:custom_avatars][a.id.to_s].to_s != ''
    end
    redirect_to :action => 'avatar'
  end
  
  
  def avatar
    @title = 'Avatar'
    @navpath = [['Preferencias', '/cuenta'], ['Avatar', '/cuenta/avatar']]
    
    if @user.faction then
      faction = @user.faction
      @avatars = faction.avatars.find(:all, :order => 'level ASC')
    end
  end
  
  def olvide_clave
    @title = 'Olvidé mi contraseña'
    @navpath = [['Cuenta', '/cuenta'], ['Olvidé mi contraseña', request.request_uri]]
  end
  
  def do_olvide_clave
    
    if params[:email] && params[:email] != '' then
      u = User.find(:first, :conditions => ['lower(email) = lower(?)', params[:email]])
      if u.nil? then
        flash[:error] = "No se ha encontrado ninguna cuenta asociada a la dirección #{params[:email]}"
        redirect_to(:action => 'olvide_clave') and return
      end
    elsif params[:login] && params[:login] != '' then
      u = User.find(:first, :conditions => ['lower(login) = lower(?)', params[:login]])
      if u.nil? then
        flash[:error] = "No se ha encontrado ninguna cuenta con nombre de usuario #{params[:login]}"
        redirect_to(:action => 'olvide_clave') and return
      end
    end
    
    if u.nil? then
      flash[:error] = 'No ha especificado un nombre de usuario o una dirección de email válidos.'
      redirect_to :action => 'olvide_clave'
    end
    
    ipr = IpPasswordsResetsRequest.create({:ip => request.remote_ip})
    
    if IpPasswordsResetsRequest.count(:conditions => ['ip = ? AND created_on > now() - \'5 minutes\'::interval', request.remote_ip]) > 3 then
      flash[:error] = "Demasiadas peticiones de reseteo de contraseña. Debes esperar un poco antes de poder realizar una nueva petición."
      redirect_to :action => 'olvide_clave'
    else
      Notification.deliver_forgot(u)
      flash[:notice] = 'Notificación enviada correctamente.'
    end
  end
  
  def reset
    @title = 'Resetear mi contraseña'
    @navpath = [['Cuenta', '/account'], ['Resetear mi contraseña', request.request_uri]]
  end
  
  def do_change_email
    if params[:k] && params[:email]
      u = User.find_by_validkey(params[:k])
      if u && u.newemail.downcase == params[:email].downcase
        u.email = u.newemail
        u.newemail = nil
        u.save
        session[:user] = u.id
        flash[:notice] = 'Dirección de correo modificada correctamente.'
        redirect_to '/cuenta'
      else
        flash[:error] = 'Los datos de confirmación no son válidos.'
        confirmar
        render :action => 'configuracion'
      end
    else
      flash[:error] = 'Los datos de confirmación no son válidos.'
      confirmar
      render :action => 'configuracion'
    end
  end
  
  def resendsignup
    if cookies[:email] and not cookies[:email].nil?
      @email = cookies[:email]
    elsif request.post? and params[:post] and params[:post][:email].to_s != ''
      @email = params[:post][:email]
    else
      @email = nil
    end
    
    if @email
      user = User.find(:first, :conditions => ["email = ? and validkey != 'NULL' and state = #{User::ST_UNCONFIRMED}",@email])
      if user.nil?
        flash[:notice] = "¡No hay ninguna cuenta registrada con esa dirección de email! "
        flash[:notice] << "O tu cuenta no ha sido confirmada o necesitas crear una nueva cuenta."
      else
        Notification.deliver_signup(user)
        cookies[:email] = { :value => user.email, :expires => nil, :domain => COOKIEDOMAIN}
        flash[:notice] = "Hemos enviado un email a #{user.email}. "
        flash[:notice] << "Por favor, pega la clave de confirmación que recibirás en el email."
      end
    end
    redirect_to :action => 'confirmar'
  end
  
  
  def do_confirmar
    if params[:k] && params[:email]
      u = User.find_by_validkey(params[:k].strip)
      if u && u.email.downcase == params[:email].downcase
        confirmar_nueva_cuenta(u)
        flash[:notice] = 'Cuenta confirmada correctamente.'
        redirect_to '/cuenta'
      else
        flash[:error] = 'Los datos de confirmación no son válidos.'
        confirmar
        render :action => 'confirmar'
      end
    else
      flash[:error] = 'Los datos de confirmación no son válidos.'
      confirmar
      render :action => 'confirmar'
    end
  end
  
  def confirmar
    @title = 'Confirmar creación de cuenta'
    @navpath = [] # necesario para que no salga lo de Cuenta
  end
  
  def _logout_intern
    session[:user] = nil
    cookies[:ak] = {:value => '', :expires => 1.second.ago, :domain => COOKIEDOMAIN}
  end
  
  def logout
    _logout_intern
    phrases = [['Te echaremos de menos.', 'MrGod'],
    ['Vuelve pronto.', 'MrCheater'],
    ['En el fondo nos caes bien.', 'MrCheater'],
    ['Nosotros somos tus amigos de verdad, ¡no lo olvides!', 'MrCheater'],
    ['Al final todos vuelven..', 'MrGod'],
    ['Demasiado tarde, ya nos hemos introducido en tu subconsciente y controlamos tus hábitos de navegación.', 'MrGod'],
    ['¿Pero a dónde vas a ir hombre/mujer de dios?', 'MrGod'],
    ['Solo aquí estarás a salvo de la SGAE, recuérdalo.', 'MrGod'],
    ['Deja el mundo real para la gente aburrida!', 'MrCheater'],
    ['Sabemos desde donde conectas. Te estaremos vigilando.', 'MrGod'],
    ['Te he enseñado todo lo que sé. Ya estás listo para enfrentarte al mundo real joven padawan. Que la fuerza te acompañe.', 'MrCheater']]
    
    rnd = phrases[Kernel.rand(phrases.size-1)]
    flash[:notice] = "Sesión cerrada correctamente<br /><br />#{rnd[1]}: <strong>#{rnd[0]}</strong>"
    redirect_to '/'
  end
  
  def borrar
    if @user.clearpasswd(params[:password].to_s) == @user.password
      @user.update_attributes(:state => User::ST_DELETED)
      _logout_intern
      flash[:notice] = 'Cuenta borrada correctamente. Que te vaya bien en la vida.'
      redirect_to '/'
    else
      flash[:error] = 'La contraseña introducida es incorrecta. Debes introducir tu contraseña actual para poder borrar tu cuenta.'
      render :action => 'configuracion'
    end
    
  end
  
  def do_reset
    if params[:k] && params[:login] && params[:password] && params[:password_confirmation]
      u = User.find(:first, :conditions => ['lower(login) = lower(?) and validkey = ?', params[:login], params[:k]])
      if u
        if u.update_attributes(params.pass_sym(:password, :password_confirmation))
          IpPasswordsResetsRequest.find(:all, :conditions => ['ip = ?', request.remote_ip]).each do |ipr|
            ipr.destroy
          end
          session[:user] = u.id
          flash[:notice] = 'Contraseña reseteada correctamente.'
          redirect_to '/cuenta'
        else
          flash[:error] = 'Las dos contraseñas introducidas no coinciden.'
          reset
          render :action => 'reset'
        end
      else
        flash[:error] = 'La clave introducida no es válida. Vuelve a solicitar una nueva clave.'
        reset
        render :action => 'olvide_clave'
      end
    else
      reset
      render :action => 'olvide_clave'
    end
  end
  
  # TODO quitar esto
  def strip_tags(html)
    @hackview ||= ActionView::Base.new
    @hackview.strip_tags(html)
  end
  
  def strip_tags_allowed(html, allowed=CorereactorHelper::DEF_ALLOW_TAGS)
    @hackview ||= ActionView::Base.new
    @hackview.strip_tags_allowed(html, allowed)
  end
  
  def username_check
    if User.find_by_login(params[:login])
      @feedback = "500+=Nombre no disponible, debes elegir otro nombre"
    else
      @feedback = '111+=Nombre disponible'    
    end
    render :layout => false
  end
  
  
  def email_check
    if User.find(:first, :conditions => ['lower(email) = lower(?)', params[:email]])
      @feedback = '500+=El email introducido ya está asignado a otra persona'
    else
      @feedback = '111+=Email válido'
    end
    render :layout => false, :action => :username_check
  end
  
  def set_default_portal
    raise ActiveRecord::RecordNotFound unless params[:new_portal] && HomeController::VALID_DEFAULT_PORTALS.include?(params[:new_portal])
    @user.default_portal = params[:new_portal]
    @user.save
    render :nothing => true
  end
  private
  def only_non_registered
   (redirect_to '/' and return) if user_is_authed
  end
end
