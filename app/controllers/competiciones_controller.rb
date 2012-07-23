# -*- encoding : utf-8 -*-
class CompeticionesController < ArenaController
  allowed_portals [:gm, :arena, :faction, :competition]
  helper :calendar
  helper Cuenta::CompeticionesHelper

  #verify :method => :post, :only => [ :join ], :redirect_to => { :action => :index }

    def submenu
    if @action_name != 'index' && @action_name != 'index' then
      'Competicion'
    end
  end

  def submenu_items
    if @action_name != 'index' && @action_name != 'index' && @competition then
      items = [['Información', "/competiciones/show/#{@competition.id}"],]
      if !@competition.kind_of?(Tournament) and @competition.state >= 3 then
        items<< ['Ranking', "/competiciones/show/#{@competition.id}/ranking"]
      end
      if @competition.state >= 3
        items<< ['Partidas', "/competiciones/show/#{@competition.id}/partidas"]
      end

      items<< ['Participantes',
               "/competiciones/show/#{@competition.id}/participantes"]
      items<< ['Reglas', "/competiciones/show/#{@competition.id}/reglas"]
    end
  end

  def index
    @title = 'Competiciones'
    @navpath = [['Competiciones', '/competiciones'], ]
  end

  def mapa
    @games_map = GamesMap.find(params[:id])
    @title = @games_map.name
    render :layout => 'popup'
  end

  def show
    @competition = Competition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @competition.state > 0
    @title = @competition.name
    @navpath = [['Competiciones', '/competiciones'],
                [@title, "/competiciones/show/#{@competition.id}"]]
  end

  def noticias
    @competition = Competition.find(params[:id])
    @title = "Noticias sobre #{@competition.name}"
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Noticias', "/competiciones/show/#{@competition.id}/noticias"]]
  end

  def partidas
    @competition = Competition.find(params[:id])
    @title = "Partidas de #{@competition.name}"
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Partidas', "/competiciones/show/#{@competition.id}/partidas"]]
  end

  def ranking
    @competition = Competition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless (!@competition.kind_of?(Tournament) &&
                                                @competition.state >= 3)
    @title = "Partidas de #{@competition.name}"
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Ranking', "/competiciones/show/#{@competition.id}/ranking"]]
  end

  def participantes
    @competition = Competition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @competition.state > 0
    @title = "Participantes en #{@competition.name}"
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Participantes', "/competiciones/show/#{@competition.id}/participantes"]]
  end

  def reglas
    @competition = Competition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @competition.state > 0
    @title = "Reglas de #{@competition.name}"
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Reglas', "/competiciones/show/#{@competition.id}/reglas"]]
  end

  def leave
    require_auth_users
    @competition = Competition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless (@competition.state == 1 or
                                               (@competition.state == 3 and
                                                @competition.class.name == 'Ladder'))

    if @competition.user_is_participant(@user.id)
      participant = @competition.get_active_participant_for_user(@user)
      if @competition.fee?
        Bank.transfer(@competition, participant.the_real_thing, @competition.fee,
                      "Devolución de inscripción en #{@competition.name}")
      end
      participant.destroy
      flash[:notice] = 'Desinscripción realizada correctamente.'
    end

    redirect_to gmurl(@competition)
  end


  def join
    require_auth_users
    @competition = Competition.find(params[:id])

    raise ActiveRecord::RecordNotFound unless (@competition.state == 1 or
                                               (@competition.state == 3 and
                                                @competition.class.name == 'Ladder'))

    begin
      @competition.join(@user)
    rescue Exception
      flash[:error] = $!
    else
      flash[:notice] = 'Inscripción realizada correctamente.'
    end

    redirect_to gmurl(@competition)
  end

  alias :join_competition :join # TODO necesario hasta que se cierre #5903

  def borrar_upload
    require_auth_users
    @competitions_matches_upload = CompetitionsMatchesUpload.find(params[:id])
    @competition = @competitions_matches_upload.competitions_match.competition
    raise AccessDenied unless @competition.user_is_admin(@user.id)
    @competitions_matches_upload.destroy
    @element_id = "u#{@competitions_matches_upload.id}"
  end

  def nuevo_informe
    require_auth_users
    @competitions_match = CompetitionsMatch.find(params[:id])
    @competition = @competitions_match.competition
    @competitions_matches_report = CompetitionsMatchesReport.new
    raise AccessDenied unless @competitions_match.user_can_upload_attachment(@user)
    @title = "Nuevo informe para #{@competitions_match.participant1.name}"+
             " vs #{@competitions_match.participant2.name}"
    @navpath = [['Competiciones', '/competiciones'],
                ['Nuevo informe', request.fullpath]]
  end

  def editar_informe
    require_auth_users
    @competitions_matches_report = CompetitionsMatchesReport.find(params[:id])
    raise AccessDenied unless @competitions_matches_report.user_id == @user.id
    @competitions_match = @competitions_matches_report.competitions_match
    raise AccessDenied unless @competitions_match.user_can_upload_attachment(@user)
    @competition = @competitions_match.competition

    @title = "Editar informe para #{@competitions_match.participant1.name}"+
             " vs #{@competitions_match.participant2.name}"
    @navpath = [['Competiciones', '/competiciones'],
                ['Editar informe', request.fullpath]]
  end

  def update_report
    require_auth_users
    @competitions_matches_report = CompetitionsMatchesReport.find(params[:id])
    raise AccessDenied unless @competitions_matches_report.user_id == @user.id
    @competitions_match = @competitions_matches_report.competitions_match
    raise AccessDenied unless @competitions_match.user_can_upload_attachment(@user)
    @competition = @competitions_match.competition

    if @competitions_matches_report.update_attributes(params[:competitions_matches_report])
      flash[:notice] = 'Informe guardado correctamente.'
      redirect_to "/competiciones/informe/#{params[:id]}"
    else
      flash[:error] = 'Error al actualizar el informe'
      render :action => 'editar_informe'
    end
  end

  def create_report
    require_auth_users
    @competitions_match = CompetitionsMatch.find(params[:id])
    @competition = @competitions_match.competition
    raise AccessDenied unless @competitions_match.user_can_upload_attachment(@user)
    params[:competitions_matches_report][:user_id] = @user.id
    new_report = @competitions_match.competitions_matches_reports.create(
                 params[:competitions_matches_report])

    if new_report
      flash[:notice] = 'Informe creado correctamente.'
      redirect_to "/competiciones/partida/#{params[:id]}"
    else
      flash[:error] = 'Error al crear el informe'
      render :action => 'nuevo_informe'
    end
  end

  def informe
    @report = CompetitionsMatchesReport.find(params[:id], :include => 'user')
    @competitions_match = @report.competitions_match
    @competition = @competitions_match.competition
    @competitions_participant = @competition.get_active_participant_for_user(@report.user)
    @title = "Informe de #{@report.user.login}"
    @navpath = [['Competiciones', '/competiciones'],
                ["Informe de #{@report.user.login}",
                  "/competiciones/informe/#{@report.id}"]]
  end


  def upload_file
    require_auth_users
    @competitions_match = CompetitionsMatch.find(params[:id])
    @competition = @competitions_match.competition

    raise AccessDenied unless @competitions_match.user_can_upload_attachment(@user)

    params[:competitions_matches_upload][:competitions_match_id] = @competitions_match.id
    params[:competitions_matches_upload][:user_id] = @user.id
    @competitions_matches_upload = CompetitionsMatchesUpload.new(
                                   params[:competitions_matches_upload])

    if @competitions_matches_upload.save
      flash[:notice] = 'Archivo subido correctamente'
    else
      flash[:error] = 'Error al guardar el archivo'
    end

    redirect_to "/competiciones/partida/#{@competitions_match.id}"
  end

  def retar
    require_auth_users
    @competitions_participant = CompetitionsParticipant.find(params[:id])
    @competition = @competitions_participant.competition
    @competitions_match = CompetitionsMatch.new({:play_on => 1.week.since})
    @title = "Nuevo reto a #{@competitions_participant.name}"
    p = @competition.get_active_participant_for_user(@user)
  end

  def responder_reto
    require_auth_users
    @competitions_match = CompetitionsMatch.find(params[:id])
    @competition = @competitions_match.competition
    # TODO poner el title bien
    # TODO permisos
    @title = "Responder al reto de #{@competitions_match.participant1.name}"
    render :action => :retar
  end

  def do_retar
    require_auth_users
    @competitions_participant = CompetitionsParticipant.find(params[:id])
    @competition = @competitions_participant.competition
    p = @competition.get_active_participant_for_user(@user)
    params[:competitions_match][:play_on] = Time.parse_from_attributes(params[
                                            :competitions_match], 'play_on') if(
                                            params[:competitions_match]
                                                  ['play_on(1i)'.to_sym].to_s != '')
    params[:competitions_match][:play_maps] = params[:play_maps]
    begin
      cm = @competition.challenge(p, @competitions_participant,
                                  HashWithIndifferentAccess.new(
                                    params[:competitions_match]))
    rescue Exception
      flash[:error] = $!
      retar
      render :action => :retar
    else
      if cm.new_record?
        flash[:error] = "Error al crear el reto:<br />"+
                        " #{cm.errors.full_messages_html}"
        retar
        render :action => :retar
      else
        flash[:notice] = 'Reto creado correctamente.'
        redirect_to "/competiciones/participante/#{@competitions_participant.id}"
      end
    end
  end

  def do_responder_reto
    require_auth_users
    # Aquí solo llegamos cuando el usuario no ha rechazado el reto

    @competitions_match = CompetitionsMatch.find(params[:competitions_match_id])
    @competition = @competitions_match.competition
    p = @competition.get_active_participant_for_user(@user)
    raise AccessDenied unless (@competitions_match.participant1_id == p.id ||
                               @competitions_match.participant2_id == p.id)
    params[:competitions_match][:play_on] = Time.parse_from_attributes(
                                                 params[:competitions_match],
                                                        'play_on')
    params[:competitions_match][:play_maps] = params[:play_maps]
    if @competitions_match.equals_options(params[:competitions_match]) # TODO asegurarnos de que el que está aceptando es el que queda
      @competitions_match.accept_challenge
      flash[:notice] = 'Reto aceptado correctamente.'
      redirect_to "/cuenta/competiciones/mis_partidas"
    else # está rechallenging
      if @competitions_match.rechallenge(params[:competitions_match])
        flash[:notice] = 'Contrarreto creado correctamente.'
        redirect_to "/cuenta/competiciones/mis_partidas"
      else
        flash[:error] = "Error al contrarretar:<br />"+
                        " #{@competitions_match.errors.full_messages_html}"
        @title = "Contrarreto"
        render :action => :retar
      end
    end
  end

  def do_accept_challenge
    require_auth_users
    @competitions_match = CompetitionsMatch.find(params[:competitions_match_id])
    @competition = @competitions_match.competition
    p = @competition.get_active_participant_for_user(@user)
    raise AccessDenied unless @competitions_match.participant2_id == p.id
    @competitions_match.accept_challenge
    flash[:notice] = 'Reto aceptado correctamente.'
    redirect_to "/cuenta/competiciones/mis_partidas"
  end

  def do_deny_challenge
    require_auth_users
    @competitions_match = CompetitionsMatch.find(params[:competitions_match_id])
    @competition = @competitions_match.competition
    p = @competition.get_active_participant_for_user(@user)
    raise AccessDenied unless @competitions_match.participant2_id == p.id
    @competitions_match.reject_challenge
    flash[:notice] = 'Reto rechazado correctamente.'
    redirect_to "/cuenta/competiciones/mis_partidas"
  end


  def retos_a_mi
    require_auth_users
    # guarda aceptación/rechazo de retos
    p2 = CompetitionsParticipant.find(params[:id])
    @competition = p2.competition

    case @competition.competitions_participants_type_id
      when 1
      raise AccessDenied unless p2.participant_id == @user.id
      when 2
      c = Clan.find(p2.participant_id)
      raise AccessDenied unless c.user_is_clanleader(@user.id)
    else
      raise "unimplemented competitions participants_type_id (#{@competition.competitions_participants_type_id})"
    end

    if params[:retos]
      # Ya estamos seguros de que es quien dice ser
      for p1_id in params[:retos].keys
        p1 = @competition.competitions_participants.find(p1_id)
        cm = @competition.competitions_matches.find(
             :first,
             :conditions => ['participant1_id = ? and
                              participant2_id = ? and
                              accepted = \'f\'', p1_id, p2.id])
        if cm.nil? then
          flash[:error] = 'El reto elegido ya no está pendiente de confirmación.'
        else
          if params[:retos][p1_id] == 'accept' then
            cm.accept_challenge
            flash[:notice] = 'Reto aceptado correctamente.'
          else
            cm.reject_challenge
            flash[:notice] = 'Reto rechazado correctamente.'

          end
        end
      end
    end

    redirect_to '/cuenta/competiciones/mis_partidas'
  end

  def notify(thing, notification, vars)
    Notification.send(notification, thing, vars).deliver
  end


  def cancelar_reto
    require_auth_users
    # cancelar un reto propuesto por uno mismo
    # TODO copypasted de arriba, solo cambia p2 por p1
    # guarda aceptación/rechazo de retos
    p1 = CompetitionsParticipant.find(params[:participant1_id])
    @competition = p1.competition

    case @competition.competitions_participants_type_id
      when 1
      raise AccessDenied unless p1.participant_id == @user.id
      when 2
      c = Clan.find(p1.participant_id)
      raise AccessDenied unless c.user_is_clanleader(@user.id)
    else
      raise 'unimplemented'
    end
    # TODO end copypasted
    #
    p2 = @competition.competitions_participants.find(params[:participant2_id])
    cm = @competition.competitions_matches.find(
         :first,
         :conditions => ['participant1_id = ? and
                          participant2_id = ? and
                          accepted = \'f\'', p1.id, p2.id])
    cm.destroy
    @competition.log("#{p1.name} cancela su reto con #{p2.name}")
    redirect_to '/cuenta/competiciones/mis_partidas'
  end

  def partida
    @competitions_match = CompetitionsMatch.find(params[:id])
    @competition = @competitions_match.competition
    raise ActiveRecord::RecordNotFound unless @competition.state >= 3
    event = @competitions_match.event
    # TODO copypasted en varios sitios

    track_item(event)
    @title = "#{@competitions_match.participant1_id ?
                @competitions_match.participant1.name : ''} vs
              #{@competitions_match.participant2_id ?
                @competitions_match.participant2.name : ''}"
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Partidas', "/competiciones/show/#{@competition.id}/partidas"],
                [@title, "/competiciones/partida/#{@competitions_match.id}"]]
  end

  def participante
    @competitions_participant = CompetitionsParticipant.find(params[:id])
    @competition = @competitions_participant.competition
    @title = @competitions_participant.name
    @navpath = [['Competiciones', '/competiciones'],
                [@competition.name, "/competiciones/show/#{@competition.id}"],
                ['Participantes', "/competiciones/show/#{@competition.id}/participantes"],
                [@title, "/competiciones/participante/#{@competitions_participant.id}"]]
  end

  def confirmar_resultado
    require_auth_users
    m = CompetitionsMatch.find(params[:id])
    m.complete_match(@user, params)

    if not m.completed? then
      flash[:notice] = 'Resultado enviado correctamente.'+
                       ' El otro participante debe confirmar el resultado.'
    else
      flash[:notice] = 'Resultado confirmado correctamente.'+
                       ' La partida ya está completa.'
    end

    redirect_to "/competiciones/partida/#{m.id}"
  end

  def reset_match
    require_auth_users
    m = CompetitionsMatch.find(params[:id])
    if m.competition.reset_match(m)
      flash[:notice] = 'Resultado reseteado correctamente.'
    else
      flash[:error] = 'Error al resetear el resultado.'
    end
    redirect_to "/competiciones/partida/#{m.id}"
  end

  # protected se usa en algunas páginas
  def user_can_set_result
    # solo se puede especificar resultado si estamos en la fase adecuada, la
    # partida no está terminada y el usuario actual es o bien uno de los
    # participantes o bien un admin de liga
    user_is_authed && @competitions_match.can_set_result(@user)
  end
end
