# -*- encoding : utf-8 -*-
class Cuenta::SkinsController < ApplicationController
  before_filter :require_auth_users

  def index
    @title = "Mis skins"
  end

  def activate
	  if params[:skin] == '-1'
		  pref = @user.preferences.find(:first, :conditions => ["name = 'skin'"])
		  pref.destroy if pref
      @skin = Skin.find_by_hid('default')
	  else
      @skin = Skin.find(params[:skin])
      if !(@skin.is_public? || @skin.user_id == @user.id)
        raise ActiveRecord::RecordNotFound
      end
      @user.pref_skin = @skin.id
	  end

    flash[:notice] = "Skin #{@skin.name} activada correctamente"
    redirect_to params[:redirto] ? params[:redirto] : "/cuenta/skins"
  end

  def make_private
    change_visibility(false)
  end

  def make_public
    change_visibility(true)
  end

  def edit
    @skin = @user.skins.find(params[:id].to_i)
    @title = "Editar skin #{@skin.name}"
  end

  def create
    @skin = Skin.new(params[:skin].merge(:user_id => @user.id))
    if @skin.save
      flash[:notice] = "Skin #{@skin.name} creada correctamente."
    else
      flash[:error] = (
        "Ocurrió un error al crear la skin: #{@skin.errors.full_messages_html}")
    end
    redirect_to :action => :index
  end

  def update
    @skin = @user.skins.find(params[:id].to_i)
    skin_variables = {}
    params["skin"]["skin_variables"] ||= {}
    Skin::SKIN_COLORS.each do |color_name|
      skin_variables[color_name] = params["skin"]["skin_variables"][color_name]
    end
    @skin.update_attribute('skin_variables', skin_variables)
    @skin.update_attribute(:updated_on, Time.now)
    flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
    redirect_to "/cuenta/skins/edit/#{@skin.id}"
  end

  def destroy
    @skin = @user.skins.find(params[:id].to_i)
    @skin.destroy
    flash[:notice] = "Skin #{@skin.name} borrada correctamente."
    redirect_to :action => :index
  end

  def create_skins_file
    @skin = @user.skins.find(params[:skin_id].to_i)
    sfn = @skin.skins_files.create(params[:skins_file])
    if sfn.new_record?
      flash[:error] = "Error al guardar el archivo: #{sfn.errors.full_messages_html}"
    else
      flash[:notice] = "Archivo creado correctamente"
    end
    redirect_to "/cuenta/skins/edit/#{@skin.id}"
  end

  def delete_skins_file
    @skin = @user.skins.find(params[:skin_id].to_i)
    sfn = @skin.skins_files.find(params[:skins_file_id])
    if sfn.nil?
      flash[:error] = "No se ha encontrado el archivo"
    else
      sfn.destroy
      flash[:notice] = "Archivo eliminado correctamente"
    end
    redirect_to "/cuenta/skins/edit/#{@skin.id}"
  end

  private
  def change_visibility(is_public)
    @skin = @user.skins.find(params[:id].to_i)
    if @skin.update_attributes(:is_public => is_public)
      flash[:notice] = "Skin <strong>#{@skin.name}</strong> guardada correctamente"
    else
      flash[:error] = "Error al guardar skin: #{@skin.errors.full_messages_html}"
    end
    redirect_to params[:redirto] ? params[:redirto] : "/cuenta/skins"
  end
end
