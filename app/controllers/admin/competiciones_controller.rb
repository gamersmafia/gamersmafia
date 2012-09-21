# -*- encoding : utf-8 -*-
class Admin::CompeticionesController < ApplicationController
  require_admin_permission :capo

  def index
    navpath2<< ['Admin', '/admin']
    @competitions = Competition.paginate(
      :order => 'state ASC, id ASC',
      :page => params[:page],
      :per_page => 50)
  end

  def info
    navpath2<< ['Admin', '/admin']
    @competition = Competition.find(params[:id])
    @title = "Editando #{@competition.name}"
  end

  def destroy
    @competition = Competition.find(params[:id])
    if @competition.can_be_deleted?
      @competition.destroy
      flash[:notice] = "Competición '#{@competition.name}' borrada correctamente"
    else
      flash[:notice] = "Imposible borrar la competición seleccionada"
    end
    redirect_to '/admin/competiciones'
  end
end
