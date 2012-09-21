# -*- encoding : utf-8 -*-
class Admin::JuegosController < AdministrationController

  def index
    @games = Game.paginate(
        :order => 'LOWER(name)',
        :page => params[:page],
        :per_page => 50)
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(params[:game])
    if @game.save
      flash[:notice] = 'Juego creado correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  # TODO remove this from here
  def create_games_version
    gm = GamesVersion.new(params[:games_version])
    if gm.save
      flash[:notice] = 'Versión de juego creada correctamente.'
    else
      flash[:error] = "Error al crear la versión: "+
                      "#{gm.errors.full_messages_html}"
    end

    redirect_to "/admin/juegos/edit/#{gm.game_id}"
  end

  def create_games_mode
    gm = GamesMode.new(params[:games_mode])
    if gm.save
      flash[:notice] = 'Modo de juego creado correctamente.'
    else
      flash[:error] = "Error al crear el modo de juego: "+
                      "#{gm.errors.full_messages_html}"
    end

    redirect_to "/admin/juegos/edit/#{gm.game_id}"
  end

  def destroy_games_version
    gv = GamesVersion.find(params[:id])
    if gv
      gv.destroy
      flash[:notice] = "Version #{gv.version} borrada correctamente"
    else
      flash[:error] = "Error al borrar la versión: "+
                      "#{gv.errors.full_messages_html}"
    end
    redirect_to "/admin/juegos/edit/#{gv.game_id}"
  end

  def destroy_games_mode
    gv = GamesMode.find(params[:id])
    if gv
      gv.destroy
      flash[:notice] = "Modo de juego #{gv.name} borrada correctamente"
    else
      flash[:error] = "Error al borrar el modo de juego: "+
                      "#{gv.errors.full_messages_html}"
    end
    redirect_to "/admin/juegos/edit/#{gv.game_id}"
  end

  def edit
    @game = Game.find(params[:id])
  end

  def update
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

  def destroy
    Game.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
end
