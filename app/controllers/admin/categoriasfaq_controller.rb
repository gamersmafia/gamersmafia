# -*- encoding : utf-8 -*-
class Admin::CategoriasfaqController < ApplicationController
  require_admin_permission :faq

  def index
    @faq_categories = FaqCategory.find(
        :all,
        :conditions => 'parent_id is null',
        :order => 'position, root_id, parent_id desc,' + 'lower(name)')
  end

  def new
    @title = "Nueva categoría de FAQ"
    @faq_category = FaqCategory.new
  end

  def create
    @faq_category = FaqCategory.new(params[:faq_category])
    if @faq_category.save
      flash[:notice] = 'Categoría FAQ creada correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @faq_category = FaqCategory.find(params[:id])
    @title = "Editar categoría de FAQ: #{@faq_category.name}"
  end

  def update
    @faq_category = FaqCategory.find(params[:id])
    if @faq_category.update_attributes(params[:faq_category])
      flash[:notice] = 'Categoría FAQ actualizada correctamente.'
      redirect_to :action => 'edit', :id => @faq_category
    else
      render :action => 'edit'
    end
  end

  def moveup
    FaqCategory.find(params[:id]).moveup
    flash[:notice] = 'Categoría FAQ actualizada correctamente.'
    redirect_to :action => 'index'
  end

  def movedown
    FaqCategory.find(params[:id]).movedown
    flash[:notice] = 'Categoría FAQ actualizada correctamente.'
    redirect_to :action => 'index'
  end

  def destroy
    if FaqCategory.find(params[:id]).destroy
      flash[:notice] = "Categoría de FAQ borrada correctamente."
    else
      flash[:error] = "Error al borrar categoría de FAQ."
    end
    redirect_to :action => 'index'
  end

  def submenu
    'faq'
  end

  def submenu_items
    [['Entradas', '/admin/entradasfaq'],
    ['Categorías', '/admin/categoriasfaq']]
  end
end
