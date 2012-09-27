# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::CuentaControllerTest < ActionController::TestCase

  YOUTUBE_EMBED_HTML = <<-END
<object width="425" height="350">
  <param name="movie" value="http://www.youtube.com/v/2Iw1uEVaQpA"></param>
  <param name="wmode" value="transparent"></param>
  <embed src="http://www.youtube.com/v/2Iw1uEVaQpA"
    type="application/x-shockwave-flash" wmode="transparent" width="425"
    height="350"></embed>
</object>'
  END

  VALID_CREATE_ARGS = {
      :accept_terms => "1",
      :user => {
          :login => "chindasvinto",
          :password => "marauja",
          :password_confirmation => "marauja",
          :email => "tupmuamad@jaja.com",
      },
  }  # .deep_freeze

  def setup
    default_user = User.find_by_login(VALID_CREATE_ARGS[:user][:login])
    User.db_query("UPDATE users SET ipaddr = '127.0.0.2'")
    if default_user
      default_user.destroy
      Rails.logger.error(
          "Default test user '#{default_user.login}' found during test setup")
    end
  end

  test "mis_permisos_should_work" do
    sym_login 2
    %w(
       Don
       ManoDerecha
       Boss
       Underboss
       Sicario
       Moderator
       Advertiser
       GroupMember
       GroupAdministrator
       CompetitionAdmin
       CompetitionSupervisor
      ).each do |r|
      @ur = UsersSkill.new(:user_id => 2, :role => r, :role_data => '1')
      assert @ur.save
    end

    @ur = UsersSkill.new(
        :user_id => 2,
        :role => 'Editor',
        :role_data => {
            :content_type_id => 1,
            :faction_id => 1
        }.to_yaml)
    assert @ur.save

    get :mis_permisos
    assert_response :success
  end

  test "del_role_should_work" do
    test_mis_permisos_should_work
    assert_count_decreases(UsersSkill) do
      post :del_role, :id => @ur.id
    end
    assert_response :success
  end

  test "del_role_other_shouldnt_work" do
    test_mis_permisos_should_work
    sym_login 1
    assert_raises(ActiveRecord::RecordNotFound) do
      post :del_role, :id => @ur.id
    end
  end

  test "add_quicklink" do
    sym_login 2
    u2 = User.find(2)
    post :add_quicklink, :code => 'ut', :link => 'http://ut.gamersmafia.com/'
    assert_response :success
    qlinks = u2.pref_quicklinks
    assert qlinks[0][:code] == 'ut'
  end

  test "del_quicklink" do
    sym_login 2
    u2 = User.find(2)
    orig_qlinks = u2.pref_quicklinks.size
    test_add_quicklink
    post :del_quicklink, :code => 'ut'
    assert_response :success
    u2.reload
    assert_equal orig_qlinks, u2.pref_quicklinks.size
  end

  test "add_user_forum" do
    sym_login 2
    u2 = User.find(2)
    post :add_user_forum, :id => '1'
    assert_response :success
    ufs = u2.pref_user_forums
    assert_equal 1, ufs[0][0]
  end

  test "del_user_forum" do
    sym_login 2
    u2 = User.find(2)
    test_add_user_forum
    post :del_user_forum, :id => 1
    assert_response :success
    ufs = u2.pref_user_forums
    assert_equal 0, ufs[0].size
    assert_equal 0, ufs[1].size
  end

  test "update_user_forums_order" do
    sym_login 2
    u2 = User.find(2)
    post :update_user_forums_order,
         :user_id => 1, :buckets1 => ['1'], :buckets2 => ['2', '3']
    assert_response :success
    ufs = u2.pref_user_forums
    assert_equal 3, ufs.size
    assert_equal 1, ufs[0][0]
    assert_equal 2, ufs[1][0]
    assert_equal 3, ufs[1][1]
  end

  test "should_resurrect_resurrectable_user" do
    u2 = User.find(2)
    u2.lastseen_on = 4.months.ago
    u2.state = User::ST_ZOMBIE
    u2.save
    post :resurrect, {:login => 'panzer'}, {:user => 1}
    assert_response :success
    assert_template 'resurrect'
    u2.reload
    assert_equal 1, u2.resurrected_by_user_id
  end

  test "should_login_valid_user" do
    u1 = User.find(1)
    one_month_ago = 1.month.ago
    u1.lastseen_on = one_month_ago
    u1.save
    post :do_login, :login => 'superadmin', :password => 'lalala'
    assert_redirected_to '/'
    assert_not_nil(session[:user])
    assert_equal session[:user], User.find_by_login('superadmin').id
    u1.reload
    assert_equal one_month_ago.to_i, u1.lastseen_on.to_i
  end

  test "should_not_login_user_in_nonlogin_state" do
    u1 = User.find(1)
     (User::HSTATES - User::STATES_CAN_LOGIN).each do |invalid_state|
      u1.state = invalid_state
      assert_equal true, u1.save
      post :do_login, :login => 'superadmin', :password => 'lalala'
      assert_response :success
      assert_nil(session[:user])
    end
  end

  test "should_not_ping_in_nonlogin_state" do
    u1 = User.find(1)
    User::STATES_CANNOT_LOGIN.each do |invalid_state|
      u1.state = invalid_state
      assert_equal true, u1.save
      get :index, {}, {:user => u1.id}
      assert_redirected_to '/cuenta/login'
      assert_nil session[:user]
    end
  end

  test "should_not_login_with_unconfirmed_user" do
    post :do_login, :login => 'unconfirmed_user', :password => 'lelele'
    assert_response :success
    assert_template 'login'
    assert_nil session[:user]
  end

  test "should_not_login_with_banned_account" do
    post :do_login, :login => 'banned_user', :password => 'lelele'
    assert_response :success
    assert_template 'login'
    assert_nil session[:user]
  end

  test "should_not_login_with_disabled_account" do
    post :do_login, :login => 'disabled_user', :password => 'lelele'
    assert_response :success
    assert_template 'login'
    assert_nil session[:user]
  end

  test "should_redirect_if_login_without_form" do
    post :do_login
    assert_redirected_to '/cuenta/login'
    assert_nil(session[:user])
  end

  test "should_redirect_if_create_without_form" do
    post :create
    assert_template 'alta'
    assert_nil(session[:user])
  end

  test "should_not_create_user_if_login_is_invalid" do
    post :create, :accept_terms => 1, :user => { :login => '' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])

    post :create, :accept_terms => 1, :user => { :login => '")!="dmk1ionloº¡L-_:*^,' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_not_create_user_if_passwords_dont_match" do
    post :create,
        :accept_terms => 1,
        :user => {
           :login => 'chindasvinto',
           :password => 'jauja',
           :password_confirmation=> 'marauja'
        }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_not_create_user_if_password_length_is_too_short" do
    post :create,
        :accept_terms => 1,
        :user => {
            :login => 'chindasvinto',
            :password => 'jau',
            :password_confirmation=> 'jau'
        }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_not_create_if_login_is_duplicated_ignoring_case" do
    post :create,
        :accept_terms => 1,
        :user => {
            :login => 'superadmin',
            :password => 'marauja',
            :password_confirmation => 'marauja',
            :email => 'lala@lala.com'
        }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_not_create_if_email_is_duplicated_ignoring_case" do
    post :create,
        :accept_terms => 1,
        :user => {
            :login => 'superadmin',
            :password => 'marauja',
            :password_confirmation => 'marauja',
            :email => 'superadmin@GAMERSMAFIA.com'
        }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_not_create_if_email_is_invalid" do
    post :create,
        :accept_terms => 1,
        :user => {
            :login => 'chindasvinto',
            :password => 'marauja',
            :password_confirmation => 'marauja',
            :email => 'tupmuamad@jaja.ñ!jeje'
    }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_not_create_if_email_domain_is_banned" do
    dom = User::BANNED_DOMAINS[0]
    post :create,
         :accept_terms => 1,
         :user => {
            :login => 'chindasvinto',
            :password => 'marauja',
            :password_confirmation => 'marauja',
            :email => "tupmuamad@#{dom}"
         }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end

  test "should_create_user_if_everything_is_valid" do
    post :create, VALID_CREATE_ARGS

    assert_redirected_to "/cuenta"
    @u = User.find_by_login(VALID_CREATE_ARGS[:user][:login])
    assert_not_nil @u
    assert_equal User::ST_SHADOW, @u.state
    assert_equal(Digest::MD5.hexdigest(VALID_CREATE_ARGS[:user][:password]),
                 @u.password)
  end

  test "should_create_second_account_from_same_ip" do
    post :create, VALID_CREATE_ARGS

    session.clear

    params = {
      :accept_terms => "1",
      :user => {
        :login => "chindasvinto2",
        :password => "marauja",
        :password_confirmation => "marauja",
        :email => "lolailo@example.com",
      },
    }

    assert_count_increases(SlogEntry) do
      post :create, params
    end

    assert_redirected_to "/cuenta/confirmar?em=#{params[:user][:email]}"
    @u2 = User.find_by_login('chindasvinto2')
    assert_not_nil @u2
    assert_equal 'chindasvinto2', @u2.login
    assert_equal Digest::MD5.hexdigest('marauja'), @u2.password
    assert_equal User::ST_UNCONFIRMED, @u2.state
  end

  test "should_not_create_user_if_ip_banned" do
    assert_count_increases(IpBan) do
      IpBan.create({:ip => '127.0.0.1', :user_id => 1})
    end

    post :create, VALID_CREATE_ARGS
    # Para un usuario con ip baneada no le decimos que está baneado, que se
    # quede esperando el email
    assert_redirected_to '/cuenta/confirmar'
    @u = User.find_by_login('chindasvinto')
    assert_nil @u
  end

  test "should_properly_acknowledge_referer" do
    panzer = User.find_by_login('panzer')
    fp = panzer.faith_points
    mails_sent = ActionMailer::Base.deliveries.size
    post :create, {:referer => 'panzer'}.update(VALID_CREATE_ARGS)

    panzer.reload
    u = User.find_by_login('chindasvinto')
    assert u
    assert_equal panzer.id, u.referer_user_id
    assert_equal mails_sent + 2, ActionMailer::Base.deliveries.size # el email de bienvenida y el de referido
    assert_equal u.email, ActionMailer::Base.deliveries.at(-1).to[0]
    assert_equal Faith::FPS_ACTIONS['registration'] + fp, panzer.faith_points
  end

  test "should_send_confirmation_email_after_creating_account" do
    num_deliveries = ActionMailer::Base.deliveries.size
    post :create, VALID_CREATE_ARGS
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "should_send_welcome_email_after_confirming_account" do
    post :create, VALID_CREATE_ARGS
    @u = User.find_by_login(VALID_CREATE_ARGS[:user][:login])
    assert_not_nil @u
    num_deliveries = ActionMailer::Base.deliveries.size
    @u.update_attributes(:state => User::ST_UNCONFIRMED)
    post :do_confirmar, {:k => @u.validkey, :email => @u.email}, {}
    assert_redirected_to '/cuenta'
    assert_equal User::ST_SHADOW, User.find_by_validkey(@u.validkey).state
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
  end

  # TODO test que solo pasen los params que deben pasar
  # TODO añadir tests para cambio de settings, baja de una cuenta y logout

  def logout
    get :logout, {}, {:user => 1}
    assert_redirected_to '/'
    # TODO necesitamos integration testing para confirmar que logout funciona
  end

  # TODO test método GET
  test "should_not_autologin_if_invalid_client_cookie" do
    @request.cookies['ak'] = 'foobar'
    get :login
    assert_response :success
    assert_nil session[:user]
  end

  test "should_not_autologin_if_client_cookie_non_existant_in_db" do
    akey = AutologinKey.find_by_key('05e3ab2d90b022d7bf1b3782dc0fd2e2aa7cc926')
    akey.destroy if akey
    @request.cookies['ak'] = '05e3ab2d90b022d7bf1b3782dc0fd2e2aa7cc926'
    get :login
    assert_response :success
    assert_nil session[:user]
  end

  #test "should_not_autologin_if_client_cookie_has_expired" do
  #end

  test "should_autologin_and_redirect_if_sending_validkey_as_param" do
    get :login, { :vk => User.find(1).validkey }
    assert_response :redirect
    # assert !(/\?vk=([a-f0-9]{32})/ =~ @response.redirected_to)
    assert_not_nil session[:user]
    assert_equal 1, session[:user]
  end

  test "should_redirect_if_authed_and_sending_validkey_as_param" do
    sym_login 1
    test_should_autologin_and_redirect_if_sending_validkey_as_param
  end

  test "should_autologin_if_client_cookie_is_set_and_exists_in_db" do
    k = '05e3ab2d90b022d7bf1b3782dc0fd2e2aa7cc926'
    akey = AutologinKey.find_by_key(k)
    akey = AutologinKey.create({:key => k, :user_id => 1, :lastused_on => Time.now}) if akey.nil?
    @request.cookies['ak'] = k
    get :login
    assert_response :redirect
    assert_not_nil session[:user]
    assert_equal 1, session[:user]
  end

  test "should_not_autologin_with_unconfirmed_user" do
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_UNCONFIRMED
    u.save
    get :login
    assert_redirected_to '/cuenta/login'
    assert_nil session[:user]
  end

  test "should_not_autologin_with_banned_user" do
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_BANNED
    assert_equal true, u.save, u.errors.full_messages_html
    get :index
    assert_redirected_to '/cuenta/login'
    assert_nil session[:user]
  end

  test "should_not_autologin_with_disabled_user" do
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_DISABLED
    u.save
    get :index
    assert_redirected_to '/cuenta/login'
    assert_nil session[:user]
  end

  test "should_logout_active_user_if_just_banned" do
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_BANNED
    u.save
    get :index, {}, {:user => 1}
    assert_redirected_to'/cuenta/login'
    assert_nil session[:user]
  end

  test "should_touch_if_autologged_in" do
    u = User.find(1)
    u.lastseen_on = 1.day.ago
    assert_equal true, u.save
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u.reload
    assert u.lastseen_on.to_i > 5.seconds.ago.to_i # hacemos esto porque suele
    # haber discrepancias de algunos segundos entre tiempo postgres y tiempo ruby
    # (probablemente por redondeos)
    # nota: pasamos a i porque hay discrepancia de milisegundos entre los tiempos de postgresql y los tiempos de ruby
  end

  test "should_confirm_new_account_if_valid_confirm_key" do
    test_should_create_user_if_everything_is_valid

    @u.change_internal_state('unconfirmed')

    post :do_confirmar, {:k => @u.validkey, :email => @u.email}, {}
    assert_redirected_to '/cuenta'
    assert_equal User::ST_SHADOW, User.find_by_validkey(@u.validkey).state
  end

  test "should_confirm_new_account_if_valid_confirm_key_but_with_extra_spaces" do
    test_should_create_user_if_everything_is_valid
    post :do_confirmar, {:k => " #{@u.validkey} ", :email => @u.email}, {}
    assert_redirected_to '/cuenta'
    assert_equal User::ST_SHADOW, User.find_by_validkey(@u.validkey).state
  end

  test "should_not_confirm_new_account_if_invalid_confirm_key" do
    post :create, VALID_CREATE_ARGS
    @u = User.find_by_login(VALID_CREATE_ARGS[:user][:login])
    assert @u
    @u.update_attributes(:state => User::ST_UNCONFIRMED)
    post :do_confirmar, {:k => 'bailar_el_chachacha', :email => @u.email}, {}
    assert_response :success
    assert_template 'cuenta/cuenta/confirmar'
    u = User.find_by_login('chindasvinto')
    assert_not_nil u
    assert_equal User::ST_UNCONFIRMED, u.state
  end

  test "should_send_reset_email_if_valid_login_or_email" do
    num_deliveries = ActionMailer::Base.deliveries.size
    post :do_olvide_clave, {:login => 'superadmin'}
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
    assert_template 'cuenta/cuenta/do_olvide_clave'

    post :do_olvide_clave, {:email => 'superadmin@gamersmafia.com'}
    assert_equal num_deliveries + 2, ActionMailer::Base.deliveries.size
    assert_template 'cuenta/cuenta/do_olvide_clave'

    post :do_olvide_clave, {:email => 'SUPERADMIN@GAMERSMAFIA.COM'}
    assert_equal num_deliveries + 3, ActionMailer::Base.deliveries.size
    assert_template 'cuenta/cuenta/do_olvide_clave'
  end

  test "should_not_send_reset_email_if_invalid_login_or_email" do
    num_deliveries = ActionMailer::Base.deliveries.size

    post :do_olvide_clave, {:login => 'superadminaaa'}
    assert_redirected_to :action => :olvide_clave
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size

    post :do_olvide_clave, {:email => 'superadminaaaa@gamersmafia.com'}
    assert_redirected_to :action => :olvide_clave
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
    # assert_template 'cuenta/cuenta/olvide_clave'
  end

  test "should_not_send_reset_email_after_three_times_in_5_mins" do
    num_deliveries = ActionMailer::Base.deliveries.size
    test_should_send_reset_email_if_valid_login_or_email
    assert_equal num_deliveries + 3, ActionMailer::Base.deliveries.size

    num_deliveries = ActionMailer::Base.deliveries.size
    post :do_olvide_clave, {:email => 'superadmin@gamersmafia.com'}
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
    assert_redirected_to :action => :olvide_clave
  end

  test "should_send_reset_email_after_two_times_and_more_than_5_mins" do
    num_deliveries = ActionMailer::Base.deliveries.size
    test_should_send_reset_email_if_valid_login_or_email
    assert_equal num_deliveries + 3, ActionMailer::Base.deliveries.size
    User.db_query("UPDATE ip_passwords_resets_requests SET created_on = now() - '1 year'::interval")
    test_should_send_reset_email_if_valid_login_or_email
  end

  test "should_allow_to_reset_if_valid_reset_key" do
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    get :reset, {:k => u.validkey, :login => u.login}
    assert_response :success
    assert_template 'cuenta/cuenta/reset'
  end

  test "should_reset_if_valid_key" do
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    post :do_reset, {:k => u.validkey, :login => u.login, :password => 'brahman', :password_confirmation => 'brahman'}
    assert_redirected_to '/cuenta'
    u = User.find_by_login('superadmin')
    assert_equal Digest::MD5.hexdigest('brahman'), u.password
  end

  test "should_not_reset_if_valid_key_but_invalid_passwords" do
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    post :do_reset, {:k => u.validkey, :login => u.login, :password => 'brahman', :password_confirmation => 'brahmanBAD'}
    assert_response :success
    assert_template 'cuenta/cuenta/reset'
    u = User.find_by_login('superadmin')
    assert(Digest::MD5.hexdigest('brahman') != u.password)
  end

  test "should_not_reset_if_invalid_key" do
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    post :do_reset, {:k => 'aaaa', :login => u.login, :password => 'brahman', :password_confirmation => 'brahman'}
    assert_response :success
    assert_template 'cuenta/cuenta/olvide_clave'
    u = User.find_by_login('superadmin')
    assert(Digest::MD5.hexdigest('brahman') != u.password)
  end

  test "should_update_newemail_if_given" do
    u = User.find(1)
    sym_login 1
    post :update_configuration, {:user => { :newemail => 'superadmin2@example.com' } }
    assert_response :redirect
    u.reload
    assert_equal 'superadmin2@example.com', u.newemail
  end


  test "should_show_mis_borradores" do
    sym_login 1
    get :mis_borradores
    assert_response :success
  end

  test "should_show_estadisticas" do
    sym_login 1
    get :estadisticas
    assert_response :success
  end

  test "should_show_estadisticas_and_not_reset" do
    u = User.find(1)
    faith_points = u.faith_points
    sym_login 1
    get :estadisticas
    assert_response :success
    u.reload
    assert_equal faith_points, u.faith_points
  end

  test "should_show_estadisticas_hits" do
    sym_login 1
    get :estadisticas_hits
    assert_response :success
  end

  test "should_show_estadisticas_registros" do
    sym_login 1
    get :estadisticas_registros
    assert_response :success
  end

  test "should_update_profile_with_youtube_in_description" do
    sym_login 1
    u = User.find(1)
    last = u.profile_last_updated_on
    assert_nil last
    post :update_profile, {
        :post => {:description => YOUTUBE_EMBED_HTML},
        :user => {},
    }
    assert_response :redirect
    u.reload
    assert u.profile_last_updated_on >= 1.minute.ago
    # We can't test for a specific description because tidylib doesn't seem to
    # be cleaning strings in a deterministic way.
    assert u.description.include?("<object")
  end

  test "update_profile_should_work_with_prefs" do
    sym_login 1
    u = User.find(1)
    last = u.profile_last_updated_on
    assert_nil last
    pref_options = {
            :pref_contact_origin => "origin",
            :pref_contact_psn_id => "psn_id",
            :pref_contact_steam => "steam",
            :pref_hw_case => "case",
            :pref_hw_heatsink => "heatsink",
            :pref_hw_keyboard => "keyboard",
            :pref_hw_mousepad => "mousepad",
            :pref_hw_powersupply => "powersupply",
            :pref_hw_speakers => "speakers",
            :pref_hw_ssd => "ssd",

    }

    post :update_profile, {
        :post => pref_options,
        :user => {},
    }
    assert_response :redirect
    u.reload
    assert u.profile_last_updated_on >= 1.minute.ago
    pref_options.each do |key, value|
      assert_equal value, u.send(key)
    end
  end

  test "should_save_tracker_config" do
    sym_login 1
    u = User.find(1)
    u.comment_adds_to_tracker_enabled = false
    u.tracker_autodelete_old_contents = false
    u.save
    post :save_tracker_config, { :user => { :comment_adds_to_tracker_enabled => '1', :tracker_autodelete_old_contents => '1' } }
    assert_response :redirect
    assert_redirected_to '/cuenta/cuenta/tracker'
    u.reload
    assert_equal true, u.comment_adds_to_tracker_enabled
    assert_equal true, u.tracker_autodelete_old_contents
  end

  test "should_save_notifications_options_without_newprofile_signatures" do
    sym_login 1
    u = User.find(1)
    u.notifications_global = false
    u.notifications_newmessages = false
    u.notifications_newregistrations = false
    u.notifications_trackerupdates = false
    u.save
    post :update_notifications, { :user => { :notifications_global => '1', :notifications_newmessages => '1', :notifications_newregistrations => 1, :notifications_trackerupdates => 1} }
    assert_response :redirect
    u.reload
    assert_equal true, u.notifications_global
    assert_equal true, u.notifications_newmessages
    assert_equal true, u.notifications_newregistrations
    assert_equal true, u.notifications_trackerupdates
  end

  test "tracker_should_work" do
    sym_login 1
    get :tracker
    assert_response :success
  end

  test "configuracion_should_work" do
    sym_login 1
    get :configuracion
    assert_response :success
  end

  test "confirmar_should_work" do
    get :confirmar
    assert_response :success
  end

  test "resendnewmail_should_work" do
    sym_login 1
    assert_count_increases(ActionMailer::Base.deliveries) do
      post :resendnewemail
      assert_redirected_to '/cuenta'
    end
  end

  test "perfil_should_work" do
    sym_login 1
    get :perfil
    assert_response :success
  end

  test "notificaciones_should_work" do
    sym_login 1
    get :notificaciones
    assert_response :success
  end

  test "imagenes_should_work" do
    sym_login 1
    get :imagenes
    assert_response :success
  end

  test "subir_imagen_should_work" do
    sym_login 1
    @u1 = User.find(1)
    f_count = @u1.get_my_files.size
    post :subir_imagen, { :file => fixture_file_upload('files/buddha.jpg', 'image/jpeg') }
    assert_equal f_count + 1, @u1.get_my_files.size
    assert_response :redirect
  end

  test "subir_imagen_shouldnt_throw_except_if_no_image" do
    sym_login 1
    @u1 = User.find(1)
    f_count = @u1.get_my_files.size
    [nil, ''].each do |t|
      post :subir_imagen, { :file =>  t}
      assert_equal f_count, @u1.get_my_files.size
      assert_response :redirect
    end
  end

  test "borrar_imagen_should_work" do
    test_subir_imagen_should_work
    f_count = @u1.get_my_files.size
    post :borrar_imagen, { :filename => 'buddha.jpg' }
    assert_response :success
    assert_equal f_count - 1, @u1.get_my_files.size
  end

  test "save_avatar_should_work" do

    @u1 = User.find(1)
    @u1.change_avatar
    assert_nil @u1.avatar_id
    Factions.user_joins_faction(@u1, 1)
    sym_login 1
    post :save_avatar, { :new_avatar_id => 1 }
    assert_response :redirect
    @u1.reload
    assert_equal 1, @u1.avatar_id
    post :save_avatar, { :new_avatar_id => '' }
    assert_response :redirect
    assert_not_nil flash[:error]
    @u1.reload
    assert_equal 1, @u1.avatar_id
  end

  test "should_update_custom_avatar" do
    sym_login 1
    u1 = User.find(1)
    av = u1.avatars.create({:name => 'fumancu', :submitter_user_id => 1})
    assert !av.new_record?
    post :custom_avatars_set, {:custom_avatars => { av.id.to_s => fixture_file_upload('files/buddha.jpg', 'file/jpeg') } }
    assert_redirected_to :action => 'avatar'
    av.reload
    assert av.path.include?('buddha.jpg')
  end

  test "avatar_should_work" do
    sym_login 1
    get :avatar
    assert_response :success
  end

  test "do_change_email_should_work" do
    @u1 = User.find(1)
    @u1.newemail = 'fulanoides@dadad.com'
    assert @u1.save
    post :do_change_email, { :k => @u1.validkey, :email => @u1.newemail}
    assert_redirected_to '/cuenta'
    @u1.reload
    assert_equal 'fulanoides@dadad.com', @u1.email
  end

  test "resendsignup_should_work" do
    u = User.find_by_login('unconfirmed_user')
    assert_not_nil u
    assert_count_increases(ActionMailer::Base.deliveries) do
      post :resendsignup, {:post => { :email => u.email }}
    end
  end

  test "set_default_portal" do
    assert_raises(AccessDenied) { get :set_default_portal }
    sym_login 1
    post :set_default_portal, :new_portal => 'arena'
    assert_response :success
    u1 = User.find(1)
    assert_equal 'arena', u1.default_portal
  end

  test "shouldnt delete if invalid password" do
    sym_login 1
    post :borrar
    assert_response :success
    assert_not_equal User::ST_DELETED, User.find(1).state

    post :borrar, :password => 'dadsdasd'
    assert_response :success
    assert_not_equal User::ST_DELETED, User.find(1).state
  end

  test "should delete if valid password" do
    sym_login 1
    post :borrar, :password => 'lalala'
    assert_response :redirect
    assert_equal User::ST_DELETED, User.find(1).state
  end
end
