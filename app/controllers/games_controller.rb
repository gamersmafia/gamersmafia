# -*- encoding : utf-8 -*-
class GamesController < ApplicationController

  def submenu
    "Juegos"
  end

  def submenu_items
    platforms = GamingPlatform.find(:all).sort_by{|platform|
      platform.name.downcase
    }.collect{|platform| [platform.name, "/juegos/p/#{platform.slug}"]}
  end

  def index
    platform = GamingPlatform.find_by_slug(params[:platform_code] || 'pc')

    @games = Game.paginate(
        :conditions => ["gaming_platform_id = ?", platform.id],
        :order => 'LOWER(name)',
        :page => params[:page],
        :per_page => 50)
    @title = "Juegos de #{platform.name}"
  end

  def new
    require_authorization(:can_create_entities?)
    @game = Game.new
  end

  def create
    require_authorization(:can_create_entities?)
    params[:game][:user_id] = @user.id
    @game = Game.new(params[:game])
    if @game.valid?
      decision = Decision.create({
        :decision_type_class => "CreateGame",
        :context => {
          :initiating_user_id => @user.id,
          :game => params[:game],
        },
      })

      flash[:notice] = (
          "Solicitud para crear el juego <strong>#{@game.name}</strong> creada
          correctamente.")
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def create_gaming_platform
    require_authorization(:can_create_entities?)
    params[:gaming_platform][:user_id] = @user.id
    @gaming_platform = GamingPlatform.new(params[:gaming_platform])
    if @gaming_platform.valid?
      decision = Decision.create({
        :decision_type_class => "CreateGamingPlatform",
        :context => {
          :initiating_user_id => @user.id,
          :gaming_platform => params[:gaming_platform],
        },
      })

      flash[:notice] = (
          "Solicitud para crear la plataforma
          <strong>#{@gaming_platform.name}</strong> creada correctamente.")
      redirect_to :action => 'index'
    else
      render :action => 'nueva_plataforma'
    end
  end

  # TODO remove this from here
  def create_games_version
    require_authorization(:can_create_entities?)
    gm = GamesVersion.new(params[:games_version])
    if gm.save
      flash[:notice] = 'Versión de juego creada correctamente.'
    else
      flash[:error] = "Error al crear la versión: "+
                      "#{gm.errors.full_messages_html}"
    end

    redirect_to "/juegos/#{gm.game_id}/edit"
  end

  def create_games_mode
    require_authorization(:can_create_entities?)
    gm = GamesMode.new(params[:games_mode])
    if gm.save
      flash[:notice] = 'Modo de juego creado correctamente.'
    else
      flash[:error] = "Error al crear el modo de juego: "+
                      "#{gm.errors.full_messages_html}"
    end

    redirect_to "/juegos/#{gm.game_id}/edit"
  end

  def destroy_games_version
    require_authorization(:can_create_entities?)
    gv = GamesVersion.find(params[:id])
    if gv
      gv.destroy
      flash[:notice] = "Version #{gv.version} borrada correctamente"
    else
      flash[:error] = "Error al borrar la versión: "+
                      "#{gv.errors.full_messages_html}"
    end
    redirect_to "/juegos/#{gv.game_id}/edit"
  end

  def destroy_games_mode
    require_authorization(:can_create_entities?)
    gv = GamesMode.find(params[:id])
    if gv
      gv.destroy
      flash[:notice] = "Modo de juego #{gv.name} borrada correctamente"
    else
      flash[:error] = "Error al borrar el modo de juego: "+
                      "#{gv.errors.full_messages_html}"
    end
    redirect_to "/juegos/#{gv.game_id}/edit"
  end

  def edit
    # TODO(slnc): temporal until we make sure changes to games can't screw up
    # factions.
    require_authorization(:can_edit_games?)
    @game = Game.find(params[:id])
  end

  def show
    @game = Game.find(params[:id])
    @title = @game.name
    @game_term = Term.game_term(@game)
  end

  def update
    # TODO(slnc): temporal until we make sure changes to games can't screw up
    # factions.
    require_authorization(:can_edit_games?)
    @game = Game.find(params[:id])
    if @game.update_attributes(params[:game])
      flash[:notice] = 'Juego actualizado correctamente.'
      redirect_to :action => 'edit', :id => @game
    else
      flash[:error] = "Error al actualizar el juego: "+
                      "#{@game.errors.full_messages_html}"
      render :action => 'edit'
    end
  end

  def nueva_plataforma
    @title = "Nueva plataforma"
    @gaming_platform = GamingPlatform.new
  end
end
