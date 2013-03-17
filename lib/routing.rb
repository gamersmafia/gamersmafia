# -*- encoding : utf-8 -*-
module Routing
  def self.url_for_content_onlyurl(object)
    uniq = object.class.name == 'Content' ?  object : object.unique_content
    if uniq.url.nil?
      # actualizamos url y portal_id
      # competitions
      # %w(Competition CompetitionsMatch)

      object = uniq.real_content
      cls_name = object.class.name
      # determinamos dominio
      if %w(Funthing).include?(cls_name)
        dom = App.domain_bazar
        portal_id = BazarPortal.new.id
        #elsif %w(Demo Bet).include?(cls_name)
        #  dom = App.domain_arena
        #  portal_id = ArenaPortal.new.id
      elsif cls_name == 'Blogentry'
        dom = App.domain
        portal_id = GmPortal.new.id
      elsif cls_name == 'Coverage'
        dom = Routing.get_domain_of_root_term(object.event.main_category.root)
      elsif Cms::CONTENTS_WITH_CATEGORIES.include?(cls_name)

        maincat = object.main_category
        if maincat
          dom = Routing.get_domain_of_root_term(maincat.root)
        else
          dom = App.domain
        end
      else
        raise "url_for_content_onlyurl() #{cls_name} not understood}"
      end

      d = dom.gsub(".#{App.domain}", '')
      d = 'gm' if d == "" || d == App.domain

      if %w(gm arena bazar).include?(d)
        portal_id = Object.const_get("#{d.titleize}Portal").new.id
      else
        portal_id = Portal.find_by_code(d).id
      end

      href = Cms.translate_content_name(object.class.name)
      href = href.normalize
      # TODO quitar esto y usar gmurl
      if href == 'topics' then
        out = "/foros/topic/#{object.id}"
      elsif href == 'preguntas' then
        out = "/respuestas/show/#{object.id}"
      elsif href == 'anuncios-de-reclutamiento' then
        out = "/reclutamiento/anuncio/#{object.id}"
      elsif object.class.name == 'Blogentry' then
        out = "/blogs/#{object.user.login}/#{object.id}"
      elsif object.class.name == 'Event'
        cm = CompetitionsMatch.find_by_event_id(object.id)
        if cm
          out = "/competiciones/partida/#{cm.id}"
        else
          out = "/#{href}/show/#{object.id}"
        end
      elsif object.class.name == 'Coverage' then
        out = "/coverages/show/#{object.id}"
      else
        out = "/#{href}/show/#{object.id}"
      end
      uniq.url = "http://#{dom}#{out}"
      uniq.portal_id = portal_id
      User.db_query("UPDATE contents SET url = #{User.connection.quote(uniq.url)}, portal_id = #{portal_id} WHERE id = #{uniq.id}")
      User.db_query("UPDATE comments SET portal_id = #{portal_id} WHERE content_id = #{uniq.id}")
    end
    uniq.url
  end

  # Devuelve el dominio para el término raíz dado
  def self.get_domain_of_root_term(term)
    raise "term is not root term" unless term.id == term.root_id
    theportal = Portal.find_by_code(term.slug)
    if theportal
      "#{theportal.code}.#{App.domain}"
    elsif term.slug == 'gm'
      App.domain
    elsif %w(bazar otros).include?(term.slug)
      App.domain_bazar
    elsif %w(arena).include?(term.slug)
      App.domain_arena
    else
      App.domain
    end
  end

  def self.gmurl(object, opts={})
    cls_name = object.class.name
    if cls_name.index('Category')
      # DEPRECATED taxonomies
      href = Cms::translate_content_name(ActiveSupport::Inflector::singularize(cls_name.gsub('Category', '')))
      href = href.normalize
      case href
        when 'topics'
        href = "foros/forum"
        when 'preguntas'
        href = "respuestas/categoria"
        when 'anuncios-de-reclutamiento'
        href = 'reclutamiento'
      end
      dom = get_domain_of_root_term(object.root)
      "http://#{dom}/#{href}/#{object.id}"
    elsif cls_name == 'Comment'
      base_url = self.gmurl(object.content.real_content)
      page = object.comment_page
      "#{base_url}?page=#{page}#comment#{object.id}"
    elsif cls_name == 'Term'
      if %w(BazarDistrict Homepage).include?(object.taxonomy)
        "http://#{object.slug}.#{App.domain}"

      elsif object.taxonomy == 'Game'
        if Faction.find_by_code(object.slug)
          "http://#{object.slug}.#{App.domain}"
        else
          "/juegos/#{Game.find_by_name(object.name).id}"
        end

      elsif object.taxonomy == 'GamingPlatform'
        if Faction.find_by_code(object.slug)
          "http://#{object.slug}.#{App.domain}"
        else
          "/plataformas/#{GamingPlatform.find_by_name(object.name).id}"
        end

      elsif object.taxonomy == 'Clan'
        "/clanes/show/#{object.id}"

      elsif object.taxonomy == 'ContentsTag'
        "/tags/#{object.slug}"

      else
        opts[:taxonomy] = object.taxonomy unless opts[:taxonomy]
        if opts[:taxonomy].index('Category')
          href = Cms::translate_content_name(ActiveSupport::Inflector::singularize(opts[:taxonomy].gsub('Category', '')))
          href = href.normalize
          case href
            when 'topics'
            href = "foros/forum"
            when 'preguntas'
            href = "respuestas/categoria"
            when 'anuncios-de-reclutamiento'
            href = 'reclutamiento'
          end
          dom = get_domain_of_root_term(object.root)
          "http://#{dom}/#{href}/#{object.id}"
        else
          raise "gmurl for term with unrecognized taxonomy '#{opts[:taxonomy]}'"
        end
      end
    elsif cls_name == 'Faction'
      "http://#{object.code}.#{App.domain}/"
    elsif cls_name == 'Clan'
      "http://#{App.domain}/clanes/clan/#{object.id}"
    elsif %w(Competition League Ladder Tournament).include?(cls_name)
      "http://arena.#{App.domain}/competiciones/show/#{object.id}"
    elsif %w(Friend User).include?(cls_name)
      # TODO the right way would be URI.escape('b@rto',Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) but we only have problems with @ right now so I hack it
      "http://#{App.domain}/miembros/#{object.login.gsub('@', '%40')}"
    elsif nil
      raise "Nil object can't have url"
    else
      Routing.url_for_content_onlyurl(object)
    end
  end

  def resolve_portal_mode
    @global_vars = GlobalVars.get_all_vars

    @@portals = {} if @global_vars["portals_updated_on"].to_time > Time.now

    # esto no hay que hacerlo aquí
    # hay clientes que mandan un HTTP_CLIENT_IP incorrecto TODO esto peta
    if request.env.include?('HTTP_CLIENT_IP') and (request.env['HTTP_CLIENT_IP'] =~ /^unknown$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i).nil? then
      request.env['HTTP_CLIENT_IP'] = request.env['REMOTE_ADDR']
    end

    if [App.domain, 'kotoko', "arena.#{App.domain}"].include?(request.host)
      @portal = GmPortal.new
    elsif request.host == "bazar.#{App.domain}"
      @portal = BazarPortal.new
    else
      # buscamos un portal para el host dado
      host = request.host.gsub(/\.$/, '') # hay gente q pone los dominios con punto al final
      km = host.match(/([^.]+\.[^.]+)$/)
      raise DomainNotFound if km.nil? # blank host or invalid name
      k = km[1]
      @@portals ||= {}
      @@portals = {} if Rails.env == 'test'
      if not @@portals.has_key?(host) then
        if App.domain_aliases.include?(k)
          raise DomainNotFound # ya no soportamos los dominios viejos
        else
          ptal = Portal.find_by_code(host.match('^([^.]+)[.]+')[1])
          ptal = nil if ptal && ptal.clan_id
          ptal = Portal.find_by_fqdn(k) if ptal.nil?
          @@portals[host] = ptal
        end
      end

      @portal = @@portals[host]
      raise DomainNotFound if @portal.nil?
    end
  end
end
