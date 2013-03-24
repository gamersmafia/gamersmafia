# -*- encoding : utf-8 -*-
module Users
  def self.add_to_tracker(user, content)
    obj = TrackerItem.find(:first, :conditions => ['content_id = ? and user_id = ? ', content.id, user.id])

    if not obj then
      obj = TrackerItem.new(:user_id => user.id, :content_id => content.id)
      obj.lastseen_on = Time.now
    end

    obj.is_tracked = true
    obj.save

    if not user.using_tracker then
      user.using_tracker = true
      user.save
    end
  end

  def self.remove_from_tracker(user, content)
    obj = TrackerItem.find(:first, :conditions => ['content_id = ? and user_id = ? ', content.id, user.id])
    obj.is_tracked = false
    obj.save

    if user.tracker_empty? then
      user.using_tracker = false
      user.save
    end
  end


  module Authentication # to be used in a controller
    attr_accessor :user

    public
    def user_is_authed
      !user.nil?
    end

    protected
    def require_skill(skill_name)
      # TODO(slnc): migrate these calls to lib/authorization.rb
      @no_ads = true
      raise AccessDenied if !(user_is_authed && (@user.has_skill_cached?(skill_name)))
    end

    def require_authorization(permission)
      raise AccessDenied if !user_is_authed
      raise AccessDenied if !Authorization.send(permission, @user)
    end

    def require_authorization_for_object(permission, object)
      raise AccessDenied if !user_is_authed
      if !Authorization.send(permission, @user, object)
        raise AccessDenied
      end
    end

    def require_user_is_staff
      raise AccessDenied unless user_is_authed && @user.is_bigboss?
    end

    def require_auth_clanleader
      raise AccessDenied unless user_is_authed && @portal.clan.user_is_clanleader(@user.id)
    end

    def require_user_can_edit(item)
      raise AccessDenied unless user_is_authed && Authorization.can_edit_content?(@user, item)
    end

    def require_auth_users
      raise AccessDenied unless user
    end

    def require_auth_admins
      raise AccessDenied unless (@user && @user.has_skill_cached?("Webmaster"))
    end

    def logout_forcibly
      session[:user] = nil
      cookies[:ak] = {:value => '', :expires => 1.second.ago, :domain => COOKIEDOMAIN}
      redirect_to '/cuenta/login'
    end

    # Autologin, session maintenance
    def ident
      clean_url = "#{request.fullpath}"
      redirect_to_clean = !params[:vk].nil?
      clean_url.gsub!(/(\?vk=([a-z0-9]{32}))/, '?fromvk=1') if /\?vk=([a-z0-9]{32})/ =~ clean_url

      if session[:user]
        @user =	User.find_by_id(session[:user])
        if @user.nil?
          Rails.logger.warn(
              "User #{session[:user]} dissappeared from db. Logging him out..")
          self.logout_forcibly and return false
        end

        if not user_can_login(@user)
            cookies[:adn3] = {
              :domain => COOKIEDOMAIN,
              :expires => 7.days.since,
              :value => @user.id,
            } if @user.state == User::ST_BANNED
          self.logout_forcibly and return false
        else
          if not cookies[:ak] then
            cookies[:ak] = {:value => @user.get_new_autologin_key, :expires => 1.year.from_now, :domain => COOKIEDOMAIN}
            redirect_to clean_url and return false if redirect_to_clean
          end
        end
      elsif cookies[:ak].to_s != '' or params[:vk].to_s != '' then
        if cookies[:ak].to_s != ''
          @user = User.find_by_autologin_key(cookies[:ak])
        else
          @user = User.find_by_validkey(params[:vk])
          if @user.nil?
            # TODO loguear esto
          end
        end

        if @user && user_can_login(@user) then
          session[:user] = @user.id
          redirect_to clean_url and return false if redirect_to_clean
        else
          cookies[:ak] = {:value => '', :expires => 1.second.ago, :domain => COOKIEDOMAIN}
           (redirect_to '/cuenta/login' and return false) if @user
        end
      end

      redirect_to clean_url and return false if redirect_to_clean
      true # !!! Leave that true !!!
    end

    private
    def user_can_login(u)
      User::STATES_CAN_LOGIN.include?(u.state)
    end
  end
end
