# -*- encoding : utf-8 -*-
class Cuenta::BlogController < ApplicationController
  before_filter :require_auth_users

  #verify :method => (:post,
  #                   :only) => [:update,
  #                              :destroy], :redirect_to => '/cuenta/blog'

  def index
    navpath2<< ['Preferencias', '/cuenta']
  end

  def new
    @title = "Nueva entrada de blog"
    @blogentry = Blogentry.new
    navpath2<< ['Preferencias', '/cuenta']
  end

  def create
    be = @user.blogentries.create(params[:blogentry].merge(
                                                  { :state => Cms::PUBLISHED }))
    if be
      Users.add_to_tracker(@user, be.unique_content)
      flash[:notice] = 'Entrada creada correctamente'
      redirect_to :action => 'index'
    else
      flash[:error] = 'Error al crear la entrada'
      render :action => 'new'
    end
  end

  def edit
    navpath2<< ['Preferencias', '/cuenta']
    @blogentry = Blogentry.find_or_404(:first,
                                       :conditions => ['id = ?', params[:id]])
    raise AccessDenied unless (@user.has_admin_permission?(:capo) ||
                               @user.id == @blogentry.user_id)
    @title = "Editar entrada de blog \"#{@blogentry.title}\""
  end

  def update
    @blogentry = Blogentry.find(params[:id])
    raise ActiveRecord::RecordNotFound unless (user_is_authed and
                                               Cms::user_can_edit_content?(
                                                    @user,
                                                    @blogentry))

    if @blogentry.update_attributes(params[:blogentry].pass_sym(:title, :main))
      flash[:notice] = 'Entrada actualizada correctamente'
    else
      flash[:error] = 'Error al actualizar la entrada'
    end

    redirect_to :action => 'edit', :id => @blogentry.id
  end

  def destroy
    @blogentry = Blogentry.find(params[:id])
    raise ActiveRecord::RecordNotFound unless (user_is_authed and
                                               Cms::user_can_edit_content?(
                                                    @user,
                                                    @blogentry))
    @blogentry.change_state(Cms::DELETED, @user)
    flash[:notice] = 'Entrada borrada correctamente'
    redirect_to :action => 'index'
  end
end
