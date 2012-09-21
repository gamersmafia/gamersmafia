# -*- encoding : utf-8 -*-
class Admin::IpBansController < ApplicationController
  require_admin_permission :capo

  def index
    @ip_ban = IpBan.new({:expires_on => 7.days.since})
  end

  def create
    @ip_ban = IpBan.new(params[:ip_ban].merge(:user_id => @user.id))
    if @ip_ban.save
      flash[:notice] = 'Ban creado correctamente.'
      redirect_to :action => 'index'
    else
      flash[:error] = "Error al crear el ban: "+
                      "#{@ip_ban.errors.full_messages_html}"
      render :action => 'index'
    end
  end

  def destroy
    ban = IpBan.find(params[:id])
    ban.destroy
    @js_response = "$j('#ipban#{ban.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end
