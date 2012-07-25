# -*- encoding : utf-8 -*-
class Admin::EntradasfaqController < ApplicationController
  require_admin_permission :faq

  def submenu
    'faq'
  end

  def submenu_items
    [['Entradas', '/admin/entradasfaq'],
    ['Categorías', '/admin/categoriasfaq']]
  end

  def index
    @faq_entries = FaqEntry.paginate(
                    :page => params[:page], :per_page => 50,
                    :order => '(select position from faq_categories where id = faq_category_id),
                               position')
  end

  def new
    @faq_entry = FaqEntry.new
  end

  def create
    @faq_entry = FaqEntry.new(params[:faq_entry])
    if @faq_entry.save
      flash[:notice] = 'Entrada FAQ creada correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @faq_entry = FaqEntry.find(params[:id])
    @title = "Editar entrada de FAQ: #{@faq_entry.question}"
  end

  def update
    @faq_entry = FaqEntry.find(params[:id])
    if @faq_entry.update_attributes(params[:faq_entry])
      flash[:notice] = 'Entrada FAQ actualizada correctamente.'
      redirect_to :action => 'edit', :id => @faq_entry
    else
      render :action => 'edit'
    end
  end

  def destroy
    if FaqEntry.find(params[:id]).destroy
      flash[:notice] = "Entrada de FAQ eliminada correctamente."
    else
      flash[:error] = "Error al borrar entrada de FAQ"
    end
    redirect_to :action => 'index'
  end

  def moveup
    @faq_entry = FaqEntry.find(params[:id])
    @prev = @faq_entry.faq_category.faq_entries.find(
                       :first,
                       :conditions => ['position < ?', @faq_entry.position],
                       :order => 'position DESC',
                       :limit => 1)
    if @prev
      tmp = @prev.position
      @prev.position = @faq_entry.position
      @faq_entry.position = tmp
      @prev.save
      @faq_entry.save
      flash[:notice] = 'Entrada FAQ actualizada correctamente.'
    else
      flash[:error] = 'Error al mover la entrada'
    end
    redirect_to :action => 'index'
  end

  def movedown
    @faq_entry = FaqEntry.find(params[:id])
    @prev = @faq_entry.faq_category.faq_entries.find(
                                     :first,
                                     :conditions => ['position > ?',
                                     @faq_entry.position],
                                     :order => 'position ASC',
                                     :limit => 1)
    if @prev
      tmp = @prev.position
      @prev.position = @faq_entry.position
      @faq_entry.position = tmp
      @prev.save
      @faq_entry.save
      flash[:notice] = 'Entrada FAQ actualizada correctamente.'
    else
      flash[:error] = 'Error al mover la entrada'
    end
    redirect_to :action => 'index'
  end
end
