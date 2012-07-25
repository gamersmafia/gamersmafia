# -*- encoding : utf-8 -*-
class Cuenta::AmigosController < ApplicationController
  before_filter :require_auth_users, :only => [ :index ]

  def invitar_email
    suc = []
    fail = []
     (1..5).each do |i|
      next unless params["email_invitation_eml#{i}"].to_s != ''
      next if SilencedEmail.find(:first,
                                 :conditions => ['lower(email) = lower(?)',
                                            params["email_invitation_eml#{i}"]])
      u = User.find(:first,
                    :conditions => ['lower(email) = lower(?)',
                                     params["email_invitation_eml#{i}"]])
      # user is local, add as a local friendship, not external
      if u
        # if there is already a friendship between them we do nothing
        next if Friendship.find_between(@user, u)
        f = Friendship.new(
            :sender_user_id => @user.id,
            :receiver_user_id => u.id,
            :invitation_text => params["email_invitation_msg#{i}"])
      else
        f = Friendship.new(
              {:sender_user_id => @user.id,
               :receiver_email => params["email_invitation_eml#{i}"],
               :invitation_text => params["email_invitation_msg#{i}"]})
      end

      if f.save
        suc<< params["email_invitation_eml#{i}"]
      else
        fail<< [params["email_invitation_eml#{i}"], f.errors.full_messages_html]
      end
    end
    flash[:notice] = "Invitaciones enviadas correctamente a"+
                     " #{suc.join('<br />')}"
    if fail.size > 0
      flash[:error] = "Error al enviar las invitaciones a #{fail.join(' ')}"
    end
    redirto_or "/cuenta/amigos"
  end

  def create_and_accept_friendship
    redirect_to "/cuenta" and return false if user_is_authed
    redirect_to "/cuenta/alta" if !cookies[:killbill].nil?
    freq = Friendship.find_by_external_invitation_key(params[:eik])
    @friendship = freq
    raise ActiveRecord::RecordNotFound unless freq
    # TODO copypaste de creat
    @suggested_login = params[:u][:login]
    params[:u][:password] ||= ''
    params[:u][:password_confirm] ||= ''
    params[:u][:email] = freq.receiver_email
    params[:u][:ipaddr] = self.remote_ip
    params[:u][:lastseen_on] = Time.now
    params[:u][:referer_user_id] = freq.sender_user_id
    @u = User.new(params[:u].pass_sym(:login,
                                      :password,
                                      :email,
                                      :ipaddr,
                                      :lastseen_on)) # TODO testear que solo se
                                                     # pasan estos atributos
    if params[:u] && params[:u][:password].to_s.empty? then
      flash[:error] = 'Debes introducir una contraseña'
      render :action => :external_user_aceptar_amistad
    elsif (params[:u] && params[:u][:password] !=
           params[:u][:password_confirm]) then
      flash[:error] = 'Las dos contraseñas introducidas no coinciden'
      render :action => :external_user_aceptar_amistad
    else
      params[:u].delete(:password_confirm)
      if @u.save then
        confirmar_nueva_cuenta(@u)
        session[:user] = @u.id
        flash[:notice] = 'Cuenta creada y confirmada correctamente.'+
                         ' Bienvenid@ a Gamersmafia.'
        redirect_to '/cuenta'
        # TODO send email to referrer
        freq.accept_external(@u)
      else
        flash[:error] = ('Error al crear la cuenta<br />' <<
                          @u.errors.full_messages.join('<br />'))
        render :action => :external_user_aceptar_amistad
      end
    end
  end

  def olvidadme
    f = Friendship.find_by_external_invitation_key(params[:eik])
    raise ActiveRecord::RecordNotFound unless f
    SilencedEmail.create({:email => f.receiver_email})
    flash[:notice] = "Email añadido a la lista negra."+
                     " No te enviaremos ninguna invitación más."
    redirect_to "/"
  end

  def colvidadme
    @title = "No deseo recibir más emails de LaFlecha"
  end


  def create_friendship_from_external_email(email, invite_text='')
    u = User.find(:first, :conditions => ['lower(email) = lower(?)', email])
    if u then # user is local, add as a local friendship, not external
      f = Friendship.find_between(@user, u)
      return f if f #if there is already a friendship between them we do nothing
      f = Friendship.new({:sender_user_id => @user.id,
                          :receiver_user_id => u.id,
                          :invitation_text => invite_text})
    else
      f = Friendship.new({:sender_user_id => @user.id,
                          :receiver_email => email,
                          :invitation_text => invite_text})
    end
    f.save
    f
  end

  def iniciar_amistad
    require_auth_users
    u = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless u
    f = Friendship.find_between(u, @user)
    if f.nil?
      f = Friendship.new({:sender_user_id => @user.id,
                          :receiver_user_id => u.id})
      if f.save
        flash[:notice] = (
          "Amistad iniciada correctamente."+
          " Debes esperar a que <b>#{u.login}</b> acepte tu amistad.")
      else
        flash[:error] = "Error al iniciar la amistad:"+
                        " #{f.errors.full_messages_html}"
      end
      redirto_or "/miembros/#{u.login}"
    else
      redirto_or "/cuenta/amigos/aceptar_amistad/#{u.login}"
    end
  end

  def aceptar_amistad
    if params[:login] then # authentified mode
      require_auth_users
      u = User.find_by_login(params[:login])
      raise ActiveRecord::RecordNotFound unless u
      f = Friendship.find_between(u, @user)
      if f.nil?
        redirect_to "/cuenta/amigos/iniciar_amistad/#{u.login}"
      else
        if f.receiver_user_id == @user.id
          f.accept
          flash[:notice] = "Amistad establecida correctamente."
        else
          flash[:notice] = "#{u.login} todavía no ha aceptado tu amistad."
        end
        if params[:aj]
          @js_response = "$j('#friendship#{f.id}').fadeOut('normal');"
          render :partial => '/shared/silent_ajax_feedback',
                 :locals => { :js_response => @js_response }
        else
          redirect_to("/cuenta/amigos")
        end
      end
    else # external user is coming
      @friendship = Friendship.find_by_external_invitation_key(params[:eik])
      @suggested_login = @friendship.receiver_email.split('@')[0]
      ok = false
      i = 0
      while not ok
        @suggested_login = @friendship.receiver_email.split('@')[0] + Kernel.rand(9999).to_s
        ok = User.find_by_login(@suggested_login).nil?
        i += 1
      end
      render :action => 'external_user_aceptar_amistad'
    end
  end

  def cancelar_amistad
    if params[:eid] then
      # cancel external mode
      f = Friendship.find_by_external_invitation_key(params[:eid])
      if f
        f.destroy
        flash[:notice] = ("Invitación a <strong>#{f.receiver_email}</strong>" +
            " cancelada correctamente.")
      else
        flash[:error] = "La invitación especificada no existe."
      end

      if user_is_authed
        if params[:aj]
          @js_response = "$j('#friendship#{f.id}').fadeOut('normal');"
          render :partial => '/shared/silent_ajax_feedback',
                 :locals => { :js_response => @js_response }
        else
          redirect_to("/cuenta/amigos")
        end
      else
        redirect_to "/cuenta/alta"
      end
    else
      require_auth_users

      if Cms::EMAIL_REGEXP =~ params[:login] then
        u = params[:login]
      else
        u = User.find_by_login(params[:login])
        raise ActiveRecord::RecordNotFound unless u
      end

      f = Friendship.find_between(@user, u)
      if f
        f.destroy
        flash[:notice] = "Amistad eliminada correctamente."
      else
        flash[:error] = "No existe amistad entre tu y #{params[:login]}."
      end

      if params[:aj]
        if f.sender_user_id == @user.id
          the_other = f.receiver_user_id
        else
          the_other = f.sender_user_id
        end
        @js_response = ("$j('#friendshipu#{the_other}').fadeOut('normal');"+
            "$j('#friendship#{f.id}').fadeOut('normal');")
        render :partial => '/shared/silent_ajax_feedback',
               :locals => { :js_response => @js_response }
      else
        redirect_to("/cuenta/amigos")
      end
    end
  end

  def mark_fr_good
    require_auth_users
    fr = @user.friends_recommendations.find_by_id(params[:id])
    fr.add_friend if fr
    render :nothing => true
  end

  def mark_fr_bad
    require_auth_users
    fr = @user.friends_recommendations.find_by_id(params[:id])
    fr.not_friend if fr
    render :nothing => true
  end
end
