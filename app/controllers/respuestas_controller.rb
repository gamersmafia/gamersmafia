# -*- encoding : utf-8 -*-
class RespuestasController < InformacionController
  acts_as_content_browser :questions
  allowed_portals [:gm, :faction, :bazar, :bazar_district]

  def index
    # TODO(slnc): temporalmente deshabilita índice por horribles problemas de
    # carga. https://github.com/gamersmafia/gamersmafia/issues/473
    raise ActiveRecord::RecordNotFound
    @categories = portal.categories(Question)
    if @categories.size == 1
      @category = @categories[0]
      categoria
    end
  end

  def categoria
    @category = Term.single_toplevel(:id => params[:id])
    raise ActiveRecord::RecordNotFound unless @category
    params[:category] = @category

    @title = "Preguntas y respuestas de #{@category.name}"
    render :action => 'index'
  end

  def abiertas
    if params[:id]
      @category = Term.single_toplevel(:id => params[:id]) unless @category
      raise ActiveRecord::RecordNotFound unless @category
      params[:category] = @category
      @title = "Preguntas abiertas de #{@category.name}"
    else
      @title = "Preguntas abiertas"
    end
  end

  def cerradas
    if params[:id]
      @category = Term.single_toplevel(:id => params[:id]) unless @category
      raise ActiveRecord::RecordNotFound unless @category
      params[:category] = @category
      @title = "Preguntas cerradas de #{@category.name}"
    else
      @title = "Preguntas cerradas"
    end
  end

  def mejor_respuesta
    require_auth_users
    @comment = Comment.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @comment && !@comment.deleted?
    @question = @comment.content.real_content
    # raise ActiveRecord
    # TODO loguear quién ha puesto una respuesta
    raise AccessDenied unless Authorization.can_set_best_answer(@user, @question)

    if @question.set_best_answer(@comment.id, @user)
      flash[:notice] = "Mejor respuesta guardada correctamente."
    else

      flash[:error] = "Ocurrió un error al guardar la mejor respuesta: #{@question.errors.full_messages_html}"
    end
    redirect_to gmurl(@question)
  end

  def sin_respuesta
    require_auth_users
    @question = Question.find(params[:id])
    raise AccessDenied unless @question.user_can_set_no_question?(@user)
    if @question.set_no_best_answer(@user)
      flash[:notice] = "Pregunta guardada completada sin respuesta correctamente."
    else
      flash[:error] = "Ocurrió un error al guardar la pregunta: #{@question.errors.full_messages_html}"
    end
    redirect_to gmurl(@question)
  end


  def revert_mejor_respuesta
    require_auth_users
    @question = Question.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @question

    # raise ActiveRecord
    # TODO loguear quién ha puesto una respuesta
    raise AccessDenied unless Authorization.can_edit_content?(@user, @question)

    if @question.revert_set_best_answer(@user)
      flash[:notice] = "Mejor respuesta quitada correctamente."
    else
      flash[:error] = "Ocurrió un error al quitar la mejor respuesta: #{@question.errors.full_messages_html}"
    end
    redirect_to gmurl(@question)
  end

  def _before_create
    require_auth_users
    if params[:question][:ammount] && params[:question][:ammount].to_s != ''
      @ammount = params[:question][:ammount].to_f
    else
      @ammount = 0.0
    end
    params[:question].delete(:ammount) if params[:question].keys.include?(:ammount)
    params[:question][:ammount] = nil
  end

  def _after_create
    params[:question][:ammount] = @ammount
    if !@question.new_record?
      _update_ammount
    end
  end


  def _before_update
    require_auth_users
    @question = Question.find(params[:id])
    params[:question][:ammount] = params[:question][:ammount].to_f if params[:question][:ammount]
    # params[:question][:ammount] = nil unless @user.id == @question.user_id
    _update_ammount
  end

  def update_ammount
    require_auth_users
    @question = Question.find(params[:id])
    raise AccessDenied unless @user.id == @question.user_id
    _update_ammount
    redirect_to gmurl(@question)
  end

  private
  def _update_ammount
    begin
      @question.update_ammount(params[:question][:ammount].to_f) if @user.id == @question.user_id
    rescue TooLateToLower then
      flash[:error] = "La cantidad indicada es demasiado pequeña. El mínimo son #{Question::MIN_AMMOUNT}GMF y solo se puede subir la recompensa."
    rescue InsufficientCash then
      flash[:error] = "No tienes tanto dinero"
    rescue Unpublished then
      flash[:error] = "La pregunta no está publicada"
    end
  end
end
