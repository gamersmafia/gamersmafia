# -*- encoding : utf-8 -*-
class Admin::MapasJuegosController < ApplicationController
  require_admin_permission :capo


  def index
    @title = 'Mapas de juegos'
    @navpath = [['Mapas de juegos', '/admin/mapas_juegos'],]
    @games_maps = GamesMap.paginate(:page => params[:page],
                                     :per_page => 50,
                                     :order => 'games_maps.game_id ASC,
                                                lower(games_maps.name) ASC',
                                     :include => :game)
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  #verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :index }

  def new
    @games_map = GamesMap.new
  end

  def create
    @games_map = GamesMap.new(params[:games_map])
    if (params[:games_map][:download_id].to_s != '' &&
        Download.find_by_id(params[:games_map][:download_id].to_i).nil?) then
      flash[:error] = 'La ID de descarga especificada no es válida.'
      render :action => 'new'
    else
      if @games_map.save
        flash[:notice] = 'Mapa de juego creado correctamente.'
        redirect_to :action => 'index'
      else
        flash[:error] = 'Error al crear la descarga'
        render :action => 'new'
      end
    end
  end

  def edit
    @games_map = GamesMap.find(params[:id])
    @title = "#{@games_map.game.code} #{@games_map.name}"
    @navpath = [['Mapas de juegos', '/admin/mapas_juegos'],
                [@title, "/admin/mapas_juegos/edit/#{@games_map.id}"]]
  end

  def update
    @games_map = GamesMap.find(params[:id])
    if (params[:games_map][:download_id].to_s != '' &&
        Download.find_by_id(params[:games_map][:download_id].to_i).nil?) then
      flash[:error] = 'La ID de descarga especificada no es válida.'
      render :action => 'edit'
    else
      if @games_map.update_attributes(params[:games_map])
        flash[:notice] = 'Mapa de juego actualizado correctamente.'
        redirect_to :action => 'edit', :id => @games_map
      else
        flash[:error] = 'Error al guardar los cambios'
        render :action => 'edit'
      end
    end
  end

  def destroy
    GamesMap.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
end
