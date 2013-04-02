# -*- encoding : utf-8 -*-
Gamersmafia::Application.routes.draw do
  resources :gaming_platforms, {
      :path => "plataformas",
      :path_names => {:new => "nueva", :edit => "editar"}} do
    member do
      post 'update'
    end
  end

  get "decision_user_choices/create"

  get "decision_comments/create"

  resources :decisions, :path => "decisiones" do
    member do
      post 'make_decision'
    end
    get "decisions/ranking/:id", :action => :ranking
    resources :decision_comments do
    end
  end


  resources :content2s

  get "notificaciones/index"

  resources :contents, :path => "contenidos" do
    member do
      get 'redir'
    end
    collection do
      get 'nuevo'
    end
  end

  resources :staff_positions, :path => "staff" do
    member do
      get 'move_to_candidacy_presentation'
      get 'confirm_winners'
    end

    resources :staff_candidates,
        :path => "candidatos",
        :path_names => { :new => "nuevo" } do
      member do
        get 'deny'
        get 'delete'
        get 'vote'
      end
    end
  end

  get "juegos/p/:platform_code", :controller => :games, :action => :index
  get "juegos/nueva_plataforma", :controller => :games, :action => :nueva_plataforma
  post "juegos/create_platform", :controller => :games, :action => :create_gaming_platform
  resources :games, {:path => "juegos" ,
                     :path_names => {:new => "nuevo", :edit => "editar"}} do
    member do
      post 'update'
    end
  end

  resources :tags, :path_names => { :new => "nuevo" } do
    collection do
      get 'autocomplete'
    end
    member do
      get 'edit'
      post 'update'
    end
  end

  namespace :admin do
      resources :tags
  end

  match 'home/stream' => 'home#set_stream'
  match 'home/tetris' => 'home#set_tetris'
  match 'account/messages' => 'account#messages'
  match 'account/messages/:id' => 'account#show_message'
  match 'admin/bazar_districts(/:action)(/:id)' => 'admin/bazar_districts'
  match 'admin/categorias/' => 'admin/categorias#index'
  match 'admin/clanes/(:action)(/:id)' => 'admin/clanes'
  match 'admin/facciones(/:action)' => 'admin/facciones'
  match 'admin/plataformas(/:action)' => 'admin/plataformas'
  match 'admin/juegos(/:action)' => 'admin/juegos'
  match 'admin/categorias/create' => 'admin/categorias#create'
  match 'admin/categorias/term/:id' => 'admin/categorias#root'
  match 'admin/categorias/term/:id/contenidos/:content_type' => 'admin/categorias#contenidos'
  match 'admin/categorias/term/:id/contenidos/:content_type/mass_move' => 'admin/categorias#mass_move'
  match 'admin/categorias/term/:id/destroy' => 'admin/categorias#destroy'
  match 'admin/categorias/term/:id/hijos/:content_type' => 'admin/categorias#hijos'
  match 'admin/categorias/term/:id/update' => 'admin/categorias#update'
  match 'admin/contenidos' => 'admin/contenidos#index'
  match 'admin/ip_bans(/:action)(/:id)' => 'admin/ip_bans'
  match 'admin/contenidos/:action' => 'admin/contenidos'
  match 'admin/tienda(/:action)' => 'admin/tienda'
  match 'admin/portales(/:action)' => 'admin/portales'
  match 'admin/mapas_juegos(/:action)' => 'admin/mapas_juegos'
  match 'admin/hipotesis(/:action)' => 'admin/hipotesis'
  match 'admin/grupos(/:action)' => 'admin/grupos'
  match 'admin/entradasfaq(/:action)' => 'admin/entradasfaq'
  match 'admin/competiciones(/:action)' => 'admin/competiciones'
  match 'admin/categoriasfaq(/:action)' => 'admin/categoriasfaq'
  match 'admin/canales(/:action)' => 'admin/canales'
  match 'admin/ads_slots(/:action)' => 'admin/ads_slots'
  match 'admin/ads(/:action)' => 'admin/ads'
  match 'admin/usuarios' => 'admin/usuarios#index'
  match 'admin/usuarios/:action' => 'admin/usuarios'
  match 'admin/contenidos/recover/:id' => 'admin/contenidos#recover'
  match 'alertas' => 'alertas#index'
  match 'alertas/:action(/:id)' => 'alertas'
  match 'blogs/:login' => 'blogs#blog', :login => /[^\/]+/
  match 'blogs/:login/:id' => 'blogs#blogentry', :login => /[^\/]+/, :constraints => { :id => /\d+/ }
  match 'blogs/ranking' => 'blogs#ranking'
  match 'cache/graphs/:action/:date/*faction_id' => 'cache#index'
  match 'cache/thumbnails/:mode/:dim/*path' => 'cache#thumbnails'
  match 'clanes/:action' => 'clanes#index'
  match 'clanes/clan/:id/competicion' => 'clanes#competicion'
  match 'competiciones' => 'competiciones#index'
  match 'competiciones/cancelar_reto/:participant1_id/:participant2_id' => 'competiciones#cancelar_reto'
  match 'competiciones/show/:id' => 'competiciones#show'
  match 'competiciones/show/:id/:action' => 'competiciones#index'
  match 'cuenta' => 'cuenta/cuenta#index'
  match 'cuenta/amigos' => 'cuenta/amigos#index'
  match 'cuenta/amigos/:action' => 'cuenta/amigos#index'
  match 'cuenta/amigos/aceptar_amistad/:login' => 'cuenta/amigos#aceptar_amistad', :login => /[^\/]+/
  match 'cuenta/amigos/cancelar_amistad/:login' => 'cuenta/amigos#cancelar_amistad', :login => /[^\/]+/
  match 'cuenta/amigos/iniciar_amistad/:login' => 'cuenta/amigos#iniciar_amistad', :login => /[^\/]+/
  match 'cuenta/apuestas' => 'cuenta/apuestas#index'
  match 'cuenta/cuenta/:action' => 'cuenta/cuenta'
  match 'cuenta/avatar' => 'cuenta/cuenta#avatar'
  match 'cuenta/banco' => 'cuenta/banco#index'
  match 'cuenta/banco/:action' => 'cuenta/banco'
  match 'cuenta/blog' => 'cuenta/blog#index'
  match 'cuenta/blog/:action(/:id)' => 'cuenta/blog'
  match 'cuenta/clanes' => 'cuenta/clanes/general#index'
  match 'cuenta/clanes/:action' => 'cuenta/clanes/general'
  match 'cuenta/clanes/general/:action' => 'cuenta/clanes/general'
  match 'cuenta/clanes/sponsors(/:action)' => 'cuenta/clanes/sponsors'
  match 'cuenta/cuenta/:action' => 'cuenta/cuenta'
  match 'cuenta/clanes/remove_member_from_group' => 'cuenta/clanes/general#remove_member_from_group'
  match 'cuenta/clanes/switch_active_clan/:id' => 'cuenta/clanes/general#switch_active_clan'
  match 'cuenta/comentarios(/:action)' => 'cuenta/comentarios'
  match 'cuenta/competiciones' => 'cuenta/competiciones#index'
  match 'cuenta/competiciones/:action' => 'cuenta/competiciones#index'
  match 'cuenta/competiciones/hack/:action' => 'cuenta/competiciones#index'
  match 'cuenta/configuracion' => 'cuenta/cuenta#configuracion'
  match 'cuenta/distrito' => 'cuenta/distrito#index'
  match 'cuenta/distrito/categorias' => 'cuenta/distrito/categorias#index'
  match 'cuenta/distrito/categorias/create' => 'cuenta/distrito/categorias#create'
  match 'cuenta/distrito/categorias/term/:id' => 'cuenta/distrito/categorias#root'
  match 'cuenta/distrito/categorias/term/:id/contenidos/:content_type' => 'cuenta/distrito/categorias#contenidos'
  match 'cuenta/distrito/categorias/term/:id/contenidos/:content_type/mass_move' => 'cuenta/distrito/categorias#mass_move'
  match 'cuenta/distrito/categorias/term/:id/destroy' => 'cuenta/distrito/categorias#destroy'
  match 'cuenta/distrito/categorias/term/:id/hijos/:content_type' => 'cuenta/distrito/categorias#hijos'
  match 'cuenta/distrito/categorias/term/:id/update' => 'cuenta/distrito/categorias#update'
  match 'cuenta/distrito/:action' => 'cuenta/distrito'
  match 'cuenta/estadisticas' => 'cuenta/cuenta#estadisticas'
  match 'cuenta/estadisticas/hits' => 'cuenta/cuenta#estadisticas_hits'
  match 'cuenta/estadisticas/registros' => 'cuenta/cuenta#estadisticas_registros'
  match 'cuenta/estadisticas/resurrecciones' => 'cuenta/cuenta#estadisticas_resurrecciones'
  match 'cuenta/faccion' => 'cuenta/faccion#index'
  match 'cuenta/faccion' => 'cuenta/faccion#index'
  match 'cuenta/faccion/alertas/new' => 'cuenta/faccion#alertas_new'
  match 'cuenta/faccion/alertas/show/:id' => 'cuenta/faccion#alertas_show', :constraints => { :id => /\d+/ }
  match 'cuenta/faccion/cabeceras' => 'cuenta/faccion#cabeceras'
  match 'cuenta/faccion/cabeceras/create' => 'cuenta/faccion#cabeceras_create'
  match 'cuenta/faccion/cabeceras/destroy/:id' => 'cuenta/faccion#cabeceras_destroy', :constraints => { :id => /\d+/ }
  match 'cuenta/faccion/cabeceras/edit/:id' => 'cuenta/faccion#cabeceras_edit', :constraints => { :id => /\d+/ }
  match 'cuenta/faccion/cabeceras/new' => 'cuenta/faccion#cabeceras_new'
  match 'cuenta/faccion/cabeceras/update/:id' => 'cuenta/faccion#cabeceras_update'
  match 'cuenta/faccion/categorias' => 'cuenta/faccion/categorias#index'
  match 'cuenta/faccion/categorias/create' => 'cuenta/faccion/categorias#create'
  match 'cuenta/faccion/categorias/term/:id' => 'cuenta/faccion/categorias#root'
  match 'cuenta/faccion/categorias/term/:id/contenidos/:content_type' => 'cuenta/faccion/categorias#contenidos'
  match 'cuenta/faccion/categorias/term/:id/contenidos/:content_type/mass_move' => 'cuenta/faccion/categorias#mass_move'
  match 'cuenta/faccion/categorias/term/:id/destroy' => 'cuenta/faccion/categorias#destroy'
  match 'cuenta/faccion/categorias/term/:id/hijos/:content_type' => 'cuenta/faccion/categorias#hijos'
  match 'cuenta/faccion/categorias/term/:id/update' => 'cuenta/faccion/categorias#update'
  match 'cuenta/faccion/informacion' => 'cuenta/faccion#informacion'
  match 'cuenta/faccion/links' => 'cuenta/faccion#links'
  match 'cuenta/faccion/juego' => 'cuenta/faccion#juego'
  match 'cuenta/faccion/links/create' => 'cuenta/faccion#links_create'
  match 'cuenta/faccion/links/destroy/:id' => 'cuenta/faccion#links_destroy', :constraints => { :id => /\d+/ }
  match 'cuenta/faccion/links/edit/:id' => 'cuenta/faccion#links_edit', :constraints => { :id => /\d+/ }
  match 'cuenta/faccion/links/new' => 'cuenta/faccion#links_new'
  match 'cuenta/faccion/links/update/:id' => 'cuenta/faccion#links_update'
  match 'cuenta/faccion/mapas_juegos' => 'cuenta/faccion#mapas_juegos'
  match 'cuenta/faccion/staff' => 'cuenta/faccion#staff'
  match 'cuenta/faccion/mapas_juegos/:action/:id' => 'cuenta/faccion#index'
  match 'cuenta/faccion/:action' => 'cuenta/faccion'
  match 'cuenta/guids' => 'cuenta/guids#index'
  match 'cuenta/guids/:action(/:id)' => 'cuenta/guids'
  match 'cuenta/imagenes' => 'cuenta/cuenta#imagenes'
  match 'cuenta/imagenes/borrar' => 'cuenta/cuenta#borrar_imagen'
  match 'cuenta/mensajes' => 'cuenta/mensajes#mensajes'
  match 'cuenta/mensajes/:action' => 'cuenta/mensajes'
  match 'cuenta/mis_contenidos' => 'cuenta/cuenta#mis_contenidos'
  match 'cuenta/mis_canales' => 'cuenta/mis_canales#index'
  match 'cuenta/mis_canales/:action' => 'cuenta/mis_canales#index'
  match 'cuenta/mis_canales/:action/:id' => 'cuenta/mis_canales#index'
  match 'cuenta/mis_compras' => 'cuenta/tienda#mis_compras'
  match 'cuenta/mis_compras/:id' => 'cuenta/tienda#configurar_compra'
  match 'cuenta/mis_compras/:id/:action' => 'cuenta/tienda#index'
  match 'cuenta/preferencias_notificaciones' => 'cuenta/cuenta#preferencias_notificaciones'
  match 'cuenta/perfil' => 'cuenta/cuenta#perfil'
  match 'cuenta/skins' => 'cuenta/skins#index'
  match 'cuenta/skins/:action' => 'cuenta/skins'
  match 'cuenta/tienda' => 'cuenta/tienda#index'
  match 'cuenta/tienda/:id' => 'cuenta/tienda#show'
  match 'cuenta/tienda/:id/:action' => 'cuenta/tienda#index'
  match 'cuenta/:action' => 'cuenta/cuenta#index'
  match 'descargas/:category' => 'descargas#index', :constraints => { :category => /\d+/ }
  match 'descargas/create' => 'descargas#create'
  match 'descargas/create_from_zip' => 'descargas#create_from_zip'
  match 'descargas/list' => 'descargas#index'
  match 'descargas/new' => 'descargas#new'
  match 'emblemas' => 'emblemas#index'
  match 'emblemas/:id' => 'emblemas#emblema'
  match 'foros/nuevo_topic' => 'foros#nuevo_topic'
  match 'foros/topics_activos' => 'foros#topics_activos'
  match 'foros/forum/:id' => 'foros#forum', :constraints => {:id => /\d+/}
  match 'gamersmafiageist/:survey_edition_date' => 'gamersmafiageist#edicion', :survey_edition_date => /[0-9]{4}/
  match 'imagenes/:category' => 'imagenes#category', :constraints => { :category => /\d+/ }
  match 'imagenes/create' => 'imagenes#create'
  match 'imagenes/create_from_zip' => 'imagenes#create_from_zip'
  match 'imagenes/new' => 'imagenes#new'
  match 'imagenes/potds' => 'imagenes#potds'
  match 'miembros/buscar' => 'miembros#buscar'
  match 'miembros/buscar/:s' => 'miembros#buscar'
  match 'miembros/buscar_por_guid' => 'miembros#buscar_por_guid'
  match 'miembros/del_firma' => 'miembros#del_firma'
  match 'miembros/del_firma/:id' => 'miembros#del_firma'
  match 'miembros/explorar' => 'miembros#explorar'
  match 'miembros/:login' => 'miembros#member', :login => /[^\/]+/
  match 'miembros/:login/:action' => 'miembros#index', :login => /[^\/]+/
  match 'miembros/:login/contenidos' => 'miembros#contenidos', :login => /[^\/]+/
  match 'miembros/:login/contenidos/:content_name' => 'miembros#contenidos_tipo', :login => /[^\/]+/
  match 'site/banners/duke' => 'site#banners_duke'
  match 'site/banners/misc' => 'site#banners_misc'
  match 'site/sponsors' => 'site#sponsors'
  match 'site/sponsors/:sponsor' => 'site#sponsor'
  match 'site/:action(/:id)' => 'site'
  match 'tutoriales/:category' => 'tutoriales#index', :constraints => { :category => /\d+/ }
  match 'tutoriales/create' => 'tutoriales#create'
  match 'tutoriales/list' => 'tutoriales#index'
  match 'tutoriales/new' => 'tutoriales#new'
  root :to => 'home#index', :title => 'Inicio'
  match '/:controller(/:action(/:id))'
  match '*path' => 'application#http_404'
end
