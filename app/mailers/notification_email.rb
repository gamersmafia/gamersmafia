# -*- encoding : utf-8 -*-
require 'net/imap'

class NotificationEmail < ActionMailer::Base
  default :from => "nagato@gamersmafia.com"

  def self.check_system_emails
    if App.system_mail_host.index('gmail')
      @imap = Net::IMAP.new(App.system_mail_host, '993', true)
      @imap.login(App.system_mail_user, App.system_mail_password)
    else
      @imap = Net::IMAP.new(App.system_mail_host)
      @imap.authenticate('LOGIN', App.system_mail_user, App.system_mail_password)
    end

    @imap.select('INBOX')

    max = 500
    i = 0
    @imap.search(["NOT", "DELETED"]).each do |message_id|
      break if i >= max
      if process_email_envelope(
          @imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"])
        mark_for_deletion(message_id)
      else
        mark_for_deletion(message_id)
      end
      i = i+1
    end

    @imap.expunge
  end

  def self.mark_for_deletion(message_id)
    @imap.store(message_id, "+FLAGS", [:Deleted])
  end

  def self.process_email_envelope(envelope)
    # puts "processing envelope.subject #{envelope.subject} (#{envelope.to[0]})"
    failed = [
      'Mail delivery failed: returning message to sender',
      'Undelivered Mail Returned to Sender',
      'Delivery Status NotificationEmail (Failure)',
      'Delivery NotificationEmail: Delivery has failed',
      'failure notice',
      'Undeliverable Message',
      'Message Delivery Failure',
      'Delivery status notification',
      'Delivery Status NotificationEmail',
    ]

    if failed.include?(envelope.subject) || (
        envelope.subject &&
        (envelope.subject.downcase.include?('delivery') ||
         envelope.subject.downcase.include?('returned mail')))
      m = /-([0-9a-zA-Z]+)$/.match(envelope.to[0].mailbox)

      if envelope.to[0].host == App.system_mail_domain.gsub('mail.', '') && !m.nil?
        message_key = m[1]
        se = SentEmail.find_by_message_key(message_key)
        if se
          u = User.find_by_login(se.recipient.split(' ')[0])
          u.disable_all_email_notifications if u
        end
        true
      else
        # puts "not deleting message because envelope host is #{envelope.to[0].host}"
        false
      end
    else
      false
    end
  end

  def self.process_email_body(envelope)
    false
  end

  def self.controller_path
    ''
  end

  # keys: new_member
  def yourebanned(user, vars)
    vars.merge!({
        :actions => [],
        :title => "Tu cuenta ha sido baneada"})
    setup(user, vars)
  end

  # keys:
  def new_factions_banned_user(user, vars)
    vars.merge!({
        :actions => [["Ir a la ficha de #{vars[:factions_ban].user.login}",
                      "#{gmurl(vars[:factions_ban].user)}"],
                     ['Editar usuario en admin',
                      "/admin/usuarios/edit/#{vars[:factions_ban].user_id}"]],
        :title => ("Usuario #{vars[:factions_ban].user.login} baneado de" +
                   " #{vars[:factions_ban].faction.name}")
    })
    setup(user, vars)
  end

  # keys: faction
  def faction_summary(user, vars)
    vars.merge!({
        :actions => [
            ["Ir a la portada de mi facción", "#{gmurl(vars[:faction])}"],
            ["Ir a la admin de facciones", "/cuenta/faccion"]],
        :title => ("Informe semanal sobre #{vars[:faction].code.upcase} -" +
                   "#{Time.now.strftime('%d %b, %Y')}")
    })
    setup(user, vars)
  end

  # keys: message
  def newmessage(user, vars)
    vars.merge!({
        :actions => [['Ir a tu buzón de mensajes', '/cuenta/mensajes']],
        :title => vars[:message].title
    })
    setup(user, vars)
  end

  # keys: signer
  def newprofilesignature(user, vars)
    actions = [
        ['Enviarle un mensaje', "/cuenta/mensajes#{sl(user)}"],
        ['Ir a mi libro de firmas', "#{gmurl(user)}/firmas"]
    ]

    if vars[:signer].enable_profile_signatures?
      actions << ['Firmar en su libro', "#{gmurl(vars[:signer])}/firmas"]
    end

    vars.merge!({
        :actions => actions,
        :title => "Tienes una nueva firma en tu perfil"
    })
    setup(user, vars)
  end

  # keys: competition
  def competition_started(user, vars)
    competition_base_url = "/competiciones/show/#{vars[:competition].id}"
    vars.merge!({
        :actions => [
            ['Ir a la competición', "#{competition_base_url}#{sl(user)}"],
            ["Ir a mis partidas", "/cuenta/competiciones#{sl(user)}"],
            ["Resto de participantes",
             "#{competition_base_url}/participantes#{sl(user)}"]],
        :title => "Comienza la #{vars[:competition].name}"})
    setup(user, vars)
  end

  # no lo aplicamos a todos los links por seguridad
  def sl(u)
    u.kind_of?(User) ? "?vk=#{u.validkey}" : ''
  end

  def welcome(user, vars={})
    vars.merge!({
        :actions => [
            ['Personalizar tu perfil', "/cuenta/perfil#{sl(user)}"],
            ['Unirme a una facción', "/cuenta/faccion#{sl(user)}"],
            ['Publicar entradas en tu blog', "/cuenta/blog#{sl(user)}"],
            ['Ir a los foros', "/foros#{sl(user)}"],
            ['Crear un clan', "/cuenta/clanes#{sl(user)}"],
            ['Crear una competición', "/cuenta/competiciones#{sl(user)}"],
        ],
        :title => 'Bienvenido a gamersmafia'})
    setup(user, vars)
  end

  def forgot(user, vars={})
    vars.merge!({
        :actions => [
            ["Resetear contraseña",
             "/cuenta/reset/?k=#{user.validkey}&login=#{user.login}"]],
        :title => 'Resetear tu contraseña'})
    setup(user, vars)
  end


  def signup(user, vars={})
    confirm_url = "/cuenta/do_confirmar?k=#{user.validkey}&email=#{user.email}"

    vars.merge!({
        :actions => [['Confirmar tu nueva cuenta', confirm_url]],
        :title => "Confirma tu nueva cuenta #{user.login}",
        :confirm_url => confirm_url })
    setup(user, vars)
  end

  def emailchange (user)
    vars = ({
        :actions => [
            ['Confirmar cambio de contraseña',
             "/cuenta/do_change_email?k=#{user.validkey}&email=#{user.email}"]],
        :title => 'Confirma el cambio de dirección de email',
        :old_email => user.email})
    user.email = user.newemail
    setup(user, vars)
  end

  def newregistration(user, vars)
    actions = []
    if not vars[:refered].is_friend_of?(user)
      actions << [
          "Añadir a #{vars[:refered].login} a mi lista de amigos",
          "/cuenta/cuenta/add_refered#{sl(user)}&login=#{vars[:refered].login}"
      ]
    end
    actions << ["Ir a la ficha de #{vars[:refered].login}",
               "#{gmurl(vars[:refered])}#{sl(user)}"]
    actions << ['Ir a mis estadísticas de usuarios referidos',
               "/cuenta/estadisticas/registros#{sl(user)}"]

    vars.merge!({
        :actions => actions,
        :title => "Nuevo usuario referido: #{vars[:refered].login}"})
    setup(user, vars)
  end

  def resurrection(user, vars)
    vars.merge!({
        :actions => [
            ["Ir a la ficha de #{vars[:resurrected].login}",
             "#{gmurl(vars[:resurrected])}#{sl(user)}"],
            ['Ir a mis estadísticas de usuarios resucitados',
             "/cuenta/estadisticas/resurrecciones#{sl(user)}"]],
        :title => "Has resucitado a #{vars[:resurrected].login}"})
    setup(user, vars)
  end

  def unconfirmed_1w(user, vars={})
    vars.merge!({
        :actions => [
            ['Confirmar tu nueva cuenta',
             "/cuenta/do_confirmar?k=#{user.validkey}&email=#{user.email}"]],
        :title => "Tu cuenta aún no está confirmada"})
    setup(user, vars)
  end

  def unconfirmed_2w(user, vars={})
    vars.merge!({
        :actions => [
            ['Confirmar tu nueva cuenta',
             "/cuenta/do_confirmar?k=#{user.validkey}&email=#{user.email}"]],
        :title => "Tu cuenta aún no está confirmada"})
    setup(user, vars)
  end

  def trackerupdate(user, vars)
    vars.merge!({
        :actions => [
            [vars[:content].resolve_hid,
             Routing.url_for_content_onlyurl(vars[:content])],
            ['Ir a mi tracker', "/cuenta/cuenta/tracker#{sl(user)}"]],
        :title => "Nuevos comentarios en #{vars[:content].resolve_hid}"})
    setup(user, vars)
  end


  def rechallenge(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => "#{vars[:participant].name} te ha lanzado un contrarreto"})
    setup(user, vars)
  end


  def reto_recibido(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => "#{vars[:participant].name} te ha retado"})
    setup(user, vars)
  end

  def reto_pendiente_1w(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => ("El reto de #{vars[:participant].name} está esperando tu" +
                   " respuesta")})
    setup(user, vars)
  end

  def reto_pendiente_2w(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => "El reto de #{vars[:participant].name} se cancelará pronto."})
    setup(user, vars)
  end

  def reto_cancelado_sin_respuesta(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => ("El reto de #{vars[:participant].name} se ha cancelado" +
                   " automáticamente")})
    setup(user, vars)
  end

  def reto_aceptado(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => "Reto aceptado por #{vars[:participant].name}"})
    setup(user, vars)
  end

  def reto_rechazado(user, vars)
    vars.merge!({
        :actions => self.get_common_competitions_actions(user, vars),
        :title => "Reto rechazado por #{vars[:participant].name}"})
    setup(user, vars)
  end

  def invited_participant(user, vars)
    vars.merge!({
        :actions => [
            ['Ir a la competición',
             "/competiciones/show/#{vars[:competition].id}#{sl(user)}"]],
        :title => ("Has sido invitado a la competición" +
                   " #{vars[:competition].name}")})
    setup(user, vars)
  end

  def ad_report(advertiser, vars)
    raise 'undefined tstart' unless vars.has_key?(:tstart)
    raise 'undefined tend' unless vars.has_key?(:tend)
    @bcc = 'slnc@gamersmafia.com'

    vars.merge!({
        :actions => [],
        :advertiser => advertiser,
        :meine_output => ENV['REPORT_OUTPUT'],
        :title => (
          "Informe de visitas del #{vars[:tstart].strftime('%Y-%m-%d')} al" +
          " #{vars[:tend].strftime('%Y-%m-%d')}"),
    })
    setup(advertiser.email, vars)
  end

  def weekly_avg_page_render_time(vars)
    vars.merge!({
        :actions => [],
        :title => "Informe de tiempo de render de los últimos 7 días"})
    setup(App.weekly_internal_report_recipient, vars)
  end

  # keys: subject, user, email, message
  def newcontactar(vars)
    vars[:sender] = User.new(:login => vars[:email], :email => vars[:email])
    vars.merge!({ :actions => [], :title => vars[:subject].strip})
    setup(User.find(1), vars)
  end

  def new_friendship_request(user, vars)
    @name = user.kind_of?(User) ? user.login : user.gsub(/@(.+)/, '')
    actions = [
        ['Aceptar amistad',
         "/cuenta/amigos/aceptar_amistad/#{vars[:sender].login}#{sl(user)}"],
        ['Rechazar amistad',
         "/cuenta/amigos/cancelar_amistad/#{vars[:sender].login}#{sl(user)}"],
        ["Ir a la ficha de #{vars[:sender].login}",
         "#{gmurl(vars[:sender])}#{sl(user)}"]
    ]
    vars.merge!({
        :actions => actions,
        :title => "#{vars[:sender].login} quiere ser tu amigo"})
    setup(user, vars)
    @from = vars[:from] if vars[:from]
  end

  def new_friendship_request_external(user, vars)
    @invitation_key = vars[:invitation_key]
    @name = user.kind_of?(User) ? user.login : user.gsub(/@(.+)/, '')
    actions = [
        ['Aceptar amistad',
         "/cuenta/amigos/aceptar_amistad/?eik=#{@invitation_key}"],
        ['Rechazar amistad',
         "/cuenta/amigos/cancelar_amistad/?eik=#{@invitation_key}"],
        ["Ir a la ficha de #{vars[:sender].login}",
         "#{gmurl(vars[:sender])}#{sl(user)}"],
        ["No recibir más invitaciones",
         "/cuenta/amigos/colvidadme/?eik=#{@invitation_key}"]
      ]
    vars.merge!({
        :actions => actions,
        :title => "#{vars[:sender].login} quiere ser tu amigo"})
    setup(user, vars)
  end

  def new_friendship_accepted(user, vars)
    actions = [
        ['Invitar a más amigos', "/cuenta/amigos#{sl(user)}"],
        ["Ir a la ficha de #{vars[:receiver].login}",
         "#{gmurl(vars[:receiver])}#{sl(user)}"],
    ]
    vars.merge!({
        :actions => actions,
        :title => "#{vars[:receiver].login} ha aceptado tu amistad"})
    setup(user, vars)
  end

  def watchdog_alerts(user, vars)
    vars.merge!({
        :actions => [],
        :title => "Se han generado #{vars[:alerts].size} alertas"})

    setup(user, vars)
  end

  def too_many_delayed_jobs(user, vars)
    vars.merge!({
        :actions => [],
        :title => "Hay #{vars[:pending_jobs]} background jobs pendientes"})

    setup(user, vars)
  end

  protected
  def get_common_competitions_actions(user, vars)
    [["Ir a la ficha de #{vars[:participant].name}",
      "/competiciones/participante/#{vars[:participant].id}#{sl(user)}"],
     ['Ir a la competición',
      "/competiciones/show/#{vars[:participant].competition_id}#{sl(user)}"],
     ['Ir a mis partidas', "/cuenta/competiciones#{sl(user)}"]]
  end

  def gmurl(object)
    Routing.gmurl(object)
  end

  def setup(recipients, vars={})
    ActionView::Base.send :include, ApplicationHelper
    raise Exception unless vars.kind_of? Hash
    vars = {
        :available_actions => [],
        :base_url => "http://#{App.domain}",
    }.merge(vars)

    if recipients.kind_of?(Array)
      vars[:recipient] = recipients[0]
    else
      vars[:recipient] = recipients
    end

    if vars[:sender] && vars[:sender].class.name != 'User'
      raise "Sender is #{vars[:sender].class.name} but can only be User"
    elsif !vars[:sender]
      vars[:sender] = Ias.nagato
    end

    self.populate_email_vars(vars, recipients)

    mail(:to => @recipients, :from => @from, :subject => @subject)

    self.log_delivered_notification
  end

  def log_delivered_notification
    SentEmail.create(
        :message_key => @message_key,
        :recipient => @recipients,
        :recipient_user_id => @recipient_user_id,
        :sender => @from,
        :title => @subject
    )
  end

  def populate_email_vars(vars, recipients)
    vars.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
    # Order is important
    @subject = "[gm] #{vars[:title].to_s}"
    @body = vars
    self.populate_recipients(recipients, vars)
    @recipient_user_id = recipients.id if recipients.class.name == 'User'
    self.populate_message_key(recipients)

    email_username = App.system_mail_user.split('@')[0]
    @from = "#{vars[:sender].login} <#{email_username}@gamersmafia.com>"
    @sender = vars[:sender]
    @return_path ="#{email_username}-#{@message_key}@gamersmafia.com"
    self.headers({'gmmid' => @message_key, 'Return-Path' => @return_path})
    @sent_on = Time.now
    vars[:message_key] = @message_key
    vars[:sent_on] = @sent_on
  end

  def populate_recipients(recipients, vars)
    case recipients.class.name
    when 'Clan'
      @recipients = ""
      recipients.admins.each do |user|
        @recipients << "#{user.login} <#{user.email}>, "
      end
    when "Friend", "User"
      @recipients = "#{recipients.login} <#{recipients.email}>"
      vars[:sl] = sl(recipients)
      vars[:recipient] = recipients
    when 'String'
      @recipients = "<#{recipients}>"
    else
      raise "#{recipients.class.name} is not a valid recipient class"
    end
  end

  def populate_message_key(recipients)
    if recipients.class.name == 'User'
      recipients_substr = recipients.validkey
    else
      recipients_substr = @recipients.to_s
    end
    @message_key = Digest::MD5.hexdigest(
        Time.now.to_i.to_s + (recipients_substr+ @subject))
  end
end
