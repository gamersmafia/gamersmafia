# -*- encoding : utf-8 -*-
class FactionsPortal < Portal
  VALID_HOMES = %w(fps softcore)
  before_save :check_factions_portal_home

  scope :softcore, :conditions => 'factions_portal_home = \'softcore\''
  scope :fps, :conditions => 'factions_portal_home = \'fps\''
  scope :gaming_platform, :conditions => 'factions_portal_home = \'platform\''

  def terms_ids(taxonomy)
    # factionsportals can either be multi-game, single-game or
    # single-gaming-platform
    if factions[0].is_gaming_platform
      root_taxonomy = "GamingPlatform"
    else
      root_taxonomy = "Game"
    end
    terms = Term.with_taxonomy(root_taxonomy).find(
        :all,
        :conditions => "slug IN (#{toplevel_categories_codes.join(',')})",
        :order => 'UPPER(name) ASC')
    res = []
    terms.each do |t|
      res += t.all_children_ids(:taxonomy => taxonomy)
    end
    res
  end

  def juego_title
    @_cache_mgmenu_juego_title ||= begin
      games = self.games
      gaming_platforms = self.gaming_platforms
      if games.size > 1
      'Juegos'
      elsif games.size == 1
      'Juego'
      elsif gaming_platforms.size > 1
      'Plataformas'
      else
      'Plataforma'
      end
    end
  end

  def check_factions_portal_home
    if factions_portal_home.to_s == '' || VALID_HOMES.include?(factions_portal_home)
      true
    else
      self.errors.add('factions_portal_home', "El home especificado '#{self.factions_portal_home}' no es válido")
      false
    end
  end

  def home
    if self.juego_title == 'Plataforma'
        'facciones_platform'
    elsif self.factions_portal_home.to_s != ''
        "facciones_#{self.factions_portal_home}"
    else
        'facciones_fps'
    end
  end

  def layout
    'gm'
  end

  def channels
    cond = "OR gmtv_channels.faction_id IN (#{faction_ids.join(',')})"
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL #{cond})", :order => 'gmtv_channels.id ASC', :include => :user)
  end

  def needs_you
    self.factions.count == 1 && self.factions.find(:first).needs_you
  end

  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    self.factions.collect do |f|
      Term.single_toplevel(f.referenced_thing_field => f.referenced_thing.id)
    end
  end

  # devuelve array de ints con las ids de las categorías visibles del tipo dado
  def get_categories(cls)
    # buscamos los nombres de todas las categorías de los juegos que tenemos
    # asociados
    cats_full = [0]
    taxonomy = Cms.taxonomy_from_content_name(cls.name)
    self.categories(cls).each do |t|
      cats_full += t.all_children_ids(:taxonomy => taxonomy)
    end
    cats_full
  end

  def games
    self.factions.collect {|f| Game.find_by_slug(f.code)} .compact.sort {|a,b| a.code <=> b.code }
  end

  def gaming_platforms
    self.factions.collect {|f| GamingPlatform.find_by_slug(f.code)} .compact.sort {|a,b| a.code <=> b.code }
  end


  def competitions
    FactionsPortalCompetitionProxy.new(self)
  end

  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        FactionsPortalPollProxy.new(self)
      elsif method_id == :coverage
        FactionsPortalCoverageProxy.new(self)
      else
        # TODO TAXONOMIES BUG, portales con mas de un root term no funcionan ya
        obj = Object.const_get(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
        if obj.respond_to?(:is_categorizable?)
          t = Term.find(:first, :conditions => "id = root_id AND slug IN (#{toplevel_categories_codes.join(',')})", :order => 'UPPER(name) ASC')
          t.add_content_type_mask(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
          #return t
          # TODO
          # ahora reemplazamos obj por la categoría de primer nivel si es facción o plataforma
          g = self.games
          if g.size > 1
            g.delete_at(0)
            g.each do |gg| t.add_sibling(Term.single_toplevel(:game_id => gg.id)) end
          end
          return t
        end
        obj
      end
    elsif /(news|downloads|topics|events|tutorials|polls|images|questions)_categories/ =~ method_id.to_s then
      # Devolvemos categorías de primer nivel de esta facción
      # it must have at least one
      Term.find(:all, :conditions => "id = root_id AND slug IN (#{toplevel_categories_codes.join(',')})", :order => 'UPPER(name) ASC')
    else
      super
    end
  end

  def respond_to?(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      true
    elsif /(news|downloads|topics|events|tutorials|polls|images|questions)_categories/ =~ method_id.to_s then
      true
    else
      super
    end
  end

  # Devuelve los banners asociados a este portal
  def factions_links
    banners = []
    urls = []
    self.factions.each do |f|
      f.factions_links.find(:all, :order => 'lower(name)').each do |fl|
        next if urls.include?(fl.url)
        banners<< fl
        urls<< fl.url
      end
    end
    banners
  end

  public
  def toplevel_categories_codes
    factions.collect {|f| "'#{f.code}'" }
  end
end

class FactionsPortalPollProxy
  def initialize(portal)
    @portal = portal
  end

  def current
    t = Term.find(
        :first,
        :conditions => "id = root_id AND slug IN (#{@portal.toplevel_categories_codes.join(',')})",
        :order => 'UPPER(name) ASC')
    Poll.in_term(t).published.find(:all, :conditions => Poll::CURRENT_SQL, :order => 'created_on DESC', :limit => 1)
  end

  def respond_to?(method_id, include_priv = false)
    true
  end

  def method_missing(method_id, *args)
    t = Term.find(:first, :conditions => "id = root_id AND slug IN (#{@portal.toplevel_categories_codes.join(',')})", :order => 'UPPER(name) ASC').poll
    return t.send(method_id, *args)

    obj = Poll
    g = @portal.games
    if g.size > 1
      obj = obj.category_class.find_by_code(g[0].slug) # cargamos la categoría como proxy para hacer consultas y que incluya la constraint de term
    elsif @portal.factions.size > 0 # platform
      obj = obj.category_class.find_by_code(@portal.factions[0].code)
    end

    if g.size > 1
      g.delete_at(0)
      g.each { |gg| obj.add_sibling(obj.class.find_by_code(gg.slug)) }
    end
    obj.send(method_id, *args)
  end
end

class FactionsPortalCoverageProxy
  def initialize(portal)
    @portal = portal
  end

  def _add_event_ids_cond(*args)
    options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
    codes = @portal.factions.collect { |g| "'#{g.code}'" }
    codes = [] if codes.size == 0
    new_cond = "event_id IN (SELECT external_id FROM contents_terms a join contents b on a.content_id = b.id AND b.content_type_id = (select id from content_types where name = 'Event') AND a.term_id = (select id from terms where parent_id IS NULL and slug = '#{@portal.code}'))"

    if options[:conditions].kind_of?(Array)
      options[:conditions][0] = "#{options[:conditions][0]} AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions] = "#{options[:conditions]} AND #{new_cond}"
    else
      options[:conditions] = "#{new_cond}"
    end
    args.push(options)
  end

  def find(*args)
    args = _add_event_ids_cond(*args)
    Coverage.find(*args)
  end

  # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
  # TODO se puede optimizar usando caches en categorías para images
  def count(*args)
    args = _add_cats_ids_cond(*args)
    Competition.count(*args)
  end
end

class FactionsPortalCompetitionProxy
  def initialize(portal)
    @portal = portal
  end

  def _add_cats_ids_cond(*args)
    options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
    g_ids = @portal.games.collect { |g| g.id }
    g_ids = [0] if g_ids.size == 0
    new_cond = "game_id IN (#{g_ids.join(',')})"

    if options[:conditions].kind_of?(Array)
      options[:conditions][0] = "#{options[:conditions][0]} AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions] = "#{options[:conditions]} AND #{new_cond}"
    else
      options[:conditions] = "#{new_cond}"
    end
    args.push(options)
  end

  def find(*args)
    args = _add_cats_ids_cond(*args)
    Competition.find(*args)
  end

  # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
  # TODO se puede optimizar usando caches en categorías para images
  def count(*args)
    args = _add_cats_ids_cond(*args)
    Competition.count(*args)
  end
end
