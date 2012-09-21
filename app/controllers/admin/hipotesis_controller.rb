# -*- encoding : utf-8 -*-
class Admin::HipotesisController < AdministrationController
  def index
    @navpath = [['Hipotesis', '/admin/hipotesis'], ]
    @title = "Hipotesis"
  end

  def end_experiment
    @ab_test = AbTest.find(params[:id])
    if @ab_test.end_experiment
      flash[:notice] = "Experimento finalizado correctamente."
    end
    redirect_to :action => 'editar', :id => @ab_test
  end

  def nueva
    @navpath = [
        ['Hipotesis', '/admin/hipotesis'],
        ['Nuevo', '/admin/hipotesis/nueva']]
    @title = 'Nueva hipótesis'
    @ab_test = AbTest.new
  end

  def create
    @ab_test = AbTest.new(params[:ab_test])
    if @ab_test.save
      flash[:notice] = 'Hipótesis creada correctamente.'
      redirect_to :action => 'index'
    else
      flash[:error] = "Error al crear la hipótesis: "+
                      "#{@ab_test.errors.full_messages_html}"
      render :action => 'nueva'
    end
  end

  def editar
    @ab_test = AbTest.find(params[:id])
    @title = "Editar #{@ab_test.name}"
    @navpath = [
        ['Hipotesis', '/admin/hipotesis'],
        ["Editar #{@ab_test.name}", "/admin/hipotesis/editar/#{@ab_test.id}"]]
  end

  def update
    @ab_test = AbTest.find(params[:id])
    if @ab_test.update_attributes(params[:ab_test])
      flash[:notice] = 'Hipótesis actualizado correctamente.'
      redirect_to :action => 'editar', :id => @ab_test
    else
      flash[:error] = "Error al actualizar la hipótesis: "+
                      "#{@ab_test.errors.full_messages_html}"
      render :action => 'editar'
    end
  end

  def destroy
    AbTest.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
end
