# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
  NEWS_PER_PAGE = 20
  VALID_DEFAULT_PORTALS = %w(index comunidad facciones bazar hq anunciante)

  attr_reader :cur_faction

  def index_suicidal
    render :action => 'index_suicidal' #, :layout => 'suicidal'
  end

  def set_tetris
    if user_is_authed
      @user.pref_homepage_mode = "tetris"
    else
      cookies[:homepage_mode] = "tetris"
    end
    redirect_to "/"
  end

  def set_stream
    if user_is_authed
      @user.pref_homepage_mode = "stream"
    else
      cookies[:homepage_mode] = "stream"
    end
    redirect_to "/"
  end

  def tetris
    @home_mode = "tetris"
    Rails.logger.warn("Tetris home requested but temporarily disabled.")
    # render :action => "tetris"
    render :action => "stream"
  end

  def stream
    @home_mode = "stream"
    render :action => "stream"
  end

  def index
    @title = "Gamersmafia"
    if user_is_authed && @user.pref_suicidal == 1
      index_suicidal
      return
    end

    if ((user_is_authed && @user.pref_homepage_mode == 'stream') ||
        (!user_is_authed && cookies[:homepage_mode] == "stream"))
      stream
      return
    else
      tetris
      return
    end

    raise "Deprecated: this shouldn't happen!"
  end

  def anunciante
    require_auth_users
    require_authorization(:is_advertiser?)
    @advertisers = @user.users_skills.find(:all, :conditions => "role = 'Advertiser'")
    @advertisers_ids = [0] + @advertisers.collect { |adv| adv.role_data.to_i }
  end
end
