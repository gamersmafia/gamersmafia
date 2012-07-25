# -*- encoding : utf-8 -*-
class Admin::FaccionesController < ApplicationController
  helper :miembros
  audit :destroy

  require_admin_permission :capo

  def index
    @title = 'Facciones'
    @navpath = [['Admin', '/admin'], ['Facciones', '/admin/facciones'], ]
    @factions = Faction.find(:all, :order => 'lower(name) asc')
  end

  def edit
    @faction = Faction.find(params[:id])
    @title = "Editando #{@faction.name}"
    @navpath = [['Admin', '/admin'],
                ['Facciones', '/admin/facciones'],
                [@faction.name, "/admin/facciones/edit/#{@faction.id}"]]
  end

  def update
    @faction = Faction.find(params[:id])
    @title = "Editando #{@faction.name}"
    @navpath = [['Admin', '/admin'],
                ['Facciones', '/admin/facciones'],
                [@faction.name, "/admin/facciones/edit/#{@faction.id}"]]

    if params[:faction][:boss].to_s != '' then
      params[:faction][:boss] = User.find_by_login(params[:faction][:boss])
    else
      params[:faction][:boss] = nil
    end

    if params[:faction][:underboss].to_s != '' then
      params[:faction][:underboss] = User.find_by_login(
                                          params[:faction][:underboss])
    else
      params[:faction][:underboss] = nil
    end
    boss = params[:faction][:boss]
    underboss = params[:faction][:underboss]
    params[:faction].delete(:boss)
    params[:faction].delete(:underboss)
    if @faction.update_attributes(params[:faction])
      @faction.update_boss(boss)
      @faction.update_underboss(underboss)
      expire_fragment(:controller => 'home',
                      :action => 'index',
                      :part => 'factions')
      flash[:notice] = 'Facción actualizada correctamente.'
      redirect_to :action => 'edit', :id => @faction
    else
      render :action => 'edit'
    end
  end

  def destroy
    faction = Faction.find(params[:id])
    raise AccessDenied unless faction.created_on >= Faction::GRACE_DAYS.days.ago
    faction.destroy
    flash[:notice] = "Facción"+
                     " <strong>#{faction.name}(#{faction.code})</strong>"+
                     " borrada correctamente"
    redirect_to '/admin/facciones'
  end
end
