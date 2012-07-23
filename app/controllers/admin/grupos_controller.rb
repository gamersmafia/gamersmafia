# -*- encoding : utf-8 -*-
class Admin::GruposController < AdministrationController

  def index
  end

  def edit
    @group = Group.find(params[:id])
  end

  def create
    g = Group.new(params[:group])
    save_or_error(g, "/admin/grupos", "/admin/grupos")
  end

  def update
    @group = Group.find(params[:id])
    update_attributes_or_error(@group,
                               "/admin/grupos/edit/#{@group.id}",
                               "/admin/grupos/edit/#{@group.id}")
  end

  def add_user_to_group
    @group = Group.find(params[:id])
    if @group.add_user_to_group(User.find_by_login(params[:login]))
      flash[:notice] = "Usuario añadido correctamente"
    else
      flash[:error] = "Error al añadir al usuario."
    end
    render :nothing => true
  end

  def remove_user_from_group
    @group = Group.find(params[:id])
    @group.remove_user_from_group(User.find(params[:user_id]))
    @js_response = "$j('#gm#{params[:user_id]}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end
end
