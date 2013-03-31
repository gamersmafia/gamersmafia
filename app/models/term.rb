# -*- encoding : utf-8 -*-
require 'has_slug'

class Term < ActiveRecord::Base
  VALID_TAXONOMIES = %w(
      BazarDistrict
      Clan
      ContentsTag
      DownloadsCategory
      EventsCategory
      Game
      GamePublisher
      GamingPlatform
      Homepage
      ImagesCategory
      NewsCategory
      TopicsCategory
      TutorialsCategory
  )

  acts_as_rootable
  acts_as_tree :order => 'name'

  has_slug :name
  file_column :header_image
  file_column :square_image

  before_save :check_no_parent_if_contents_tag
  before_save :check_references_to_ancestors
  before_save :check_taxonomy
  before_save :copy_parent_attrs

  # VALIDATES siempre los últimos
  validates_format_of :slug, :with => /^[a-z0-9_.-]{0,50}$/
  validates_format_of :name, :with => /^.{1,100}$/
  plain_text :name, :description
  validates_uniqueness_of :name, :scope => [:parent_id, :taxonomy]
  validates_uniqueness_of :slug, :scope => [:parent_id, :taxonomy]

  def self.subscribed_users_per_tag
    rows = User.db_query(
        "SELECT
          entity_id,
          COUNT(*) AS cnt
        FROM user_interests a
        JOIN terms b
        ON a.entity_type_class = 'Term'
        AND a.entity_id = b.id
        AND b.taxonomy = 'ContentsTag'
        GROUP BY entity_id")
    zero_tags = Term.with_taxonomy("ContentsTag").count - rows.size
    (rows.collect{|row| row['cnt'].to_i } + [0]*zero_tags).percentile(0.99) || 0
  end

  # Returns the term associated with a game
  def self.game_term(game)
    Term.with_taxonomy("Game").find_by_game_id!(game.id)
  end

  def self.delete_empty_content_tags_terms
    Term.contents_tags.find(:all, :conditions => 'contents_count = 0').each do |t|
      next if t.contents_terms.count > 0 || t.users_contents_tags.count > 0
      t.destroy
    end and nil
  end

  def self.taxonomies
    VALID_TAXONOMIES
  end

  def to_param
    self.slug
  end

  def to_s
    "id: '#{self.id}' slug: '#{self.slug}' name: '#{self.name}'" +
    " parent: '#{self.parent_id}' root_id: '#{self.root_id}'"
  end

  def check_taxonomy
    if self.taxonomy && !self.class.taxonomies.include?(self.taxonomy)
      self.errors.add(
          "term",
          "Taxonomía '#{self.taxonomy}' incorrecta. Taxonomías válidas:" +
          " #{self.class.taxonomies.join(', ')}")
      false
    else
      true
    end
  end

  def self.final_decision_made(decision)
    case decision.decision_type_class
    when "CreateTag"
      user = User.find(decision.context[:initiating_user_id] || Ias.jabba.id)
      if decision.final_decision_choice.name == Decision::BINARY_YES
        decision.context[:initial_contents].each do |content_id|
          content = Content.find_by_id(content_id.to_i)
          if content.nil?
            Rails.logger.error(
                "'#{content_id}' is not a valid content id for a new tag." +
                " Skipping..")
            next
          end
          UsersContentsTag.tag_content(
              content, user, decision.context[:tag_name], delete_missing=false)
          tag = Term.with_taxonomy("ContentsTag").find_by_name(
              decision.context[:tag_name])
          decision.context[:result] = (
              "<a href=\"/tags/#{tag.code}\">Ver tag</a>")
          decision.save
        end
        user.notifications.create({
          :sender_user_id => Ias.mrman.id,
          :type_id => Notification::DECISION_RESULT,
          :description => (
              "¡Enhorabuena! Tu solicitud para crear el tag" +
              " '#{decision.context[:tag_name]}' ha sido aceptada." +
              " <a href=\"/decisiones/#{decision.id}\">Más información</a>."),
        })
      else  # no
        user.notifications.create({
          :sender_user_id => Ias.mrman.id,
          :type_id => Notification::DECISION_RESULT,
          :description => (
              "Tu solicitud para crear el tag '#{decision.context[:tag_name]}'" +
              " ha sido rechazada. <a href=\"/decisiones/#{decision.id}\">Más" +
              " información</a>."),
        })
      end
    else
      raise ("final decision made on unknown type" +
             " (#{decision.decision_type_class})")
    end
  end

  def self.find_taxonomy(id, taxonomy)
    raise "Taxonomy can't be nil" if taxonomy.nil?
    Term.with_taxonomy(taxonomy).find(:first, :conditions => ["id = ?", id])
  end

  def self.find_taxonomy_by_code(code, taxonomy)
    # Solo para taxonomías toplevel
    Term.find(:first, :conditions => ['id = root_id AND code = ? AND taxonomy = ?', code, taxonomy])
  end


  # Devuelve los ids de los hijos de la categoría actual o de la categoría obj de forma recursiva incluido el id de obj
  def all_children_ids(opts={})
    cats = [self.id]
    conds = []
    conds << opts[:cond] if opts[:cond].to_s != ''
    conds << "taxonomy = #{User.connection.quote(opts[:taxonomy])}" if opts[:taxonomy]

    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0


    if self.id == self.root_id then # shortcut
      db_query("SELECT id FROM terms WHERE root_id = #{self.id} AND id <> #{self.id} #{cond}").each { |dbc| cats<< dbc['id'].to_i }
    else # hay que ir preguntando categoría por categoría
      if conds.size > 0
        self.children.find(:all, :conditions => cond[4..-1]).each { |child| cats.concat(child.all_children_ids(opts)) }
      else
        self.children.find(:all).each { |child| cats.concat(child.all_children_ids(opts)) }
      end
    end
    cats.uniq
  end

  def self.taxonomy_from_class_name(cls_name)
    "#{ActiveSupport::Inflector::pluralize(cls_name)}Category"
  end


  def get_ancestors
    # devuelve los ascendientes. en [0] el padre directo y en el último el root
    path = []
    parent = self.parent

    while parent do
      path<< parent
      parent = parent.parent
    end

    path
  end

  def add_sibling(sibling_term)
    raise "sibling_term must be a term but is a #{sibling_term.class.name}" unless sibling_term.class.name == 'Term'
    @siblings ||= []
    @siblings<< sibling_term
  end

  private
  def check_no_parent_if_contents_tag
    !(self.taxonomy == "ContentsTag" && !self.parent_id.nil?)
  end

  def check_references_to_ancestors
    if !self.new_record?
      if self.parent_id_changed?
        return false if self.parent_id == self.id # para evitar bucles infinitos
        self.root_id = parent_id.nil? ? self.id : self.class.find(parent_id).root_id
        self.class.find(:all, :conditions => "id IN (#{self.all_children_ids.join(',')})").each do |child|
          next if child.id == self.id
          child.root_id = self.root_id
          child.save
        end
      end
    end
    true
  end

  public


# OLD
  belongs_to :game
  belongs_to :bazar_district
  belongs_to :gaming_platform
  belongs_to :clan

  scope :portal_root_term, lambda { |portal|
    taxonomy = case portal.class.name
    when "BazarPortal"
      "Homepage"
    when "ArenaPortal"
      "Homepage"
    when "BazarDistrictPortal"
      "BazarDistrict"
    when "FactionsPortal"
      Game.find_by_slug(portal.code) ?  "Game" : "GamingPlatform"
    when "ClansPortal"
      "Clan"
    else
      raise "Unknown portal type '#{portal.type}' for portal '#{portal.code}'"
    end
    {:conditions => "taxonomy = '#{taxonomy}' AND slug = '#{portal.code}'"}
  }

  scope :with_contents, :conditions => "contents_count > 0"
  scope :contents_tags, :conditions => "taxonomy = 'ContentsTag'"
  scope :with_taxonomy, lambda { |taxonomy| {:conditions => "taxonomy = '#{taxonomy}'"}}
  scope :with_taxonomies, lambda { |taxonomies|
      joined_taxonomies = taxonomies.collect{|t| "'#{t}'"}.join(", ")
      {:conditions => "taxonomy IN (#{joined_taxonomies})"}
  }

  scope :editable_taxonomies,
      {:conditions => "taxonomy IN ('Game', 'GamingPlatform', 'BazarDistrict')"}

  scope :in_category, lambda { |t| {
    :conditions => ['id IN (
                       SELECT term_id
                       FROM contents_terms
                       WHERE content_id IN (
                         SELECT content_id
                         FROM contents_terms
                         WHERE term_id IN (?)))',
                    t.all_children_ids]}
  }

  has_many :contents_terms, :dependent => :destroy
  has_many :contents, :through => :contents_terms
  has_many :users_contents_tags #, :dependent => :destroy
  has_many :tagged_contents, :through => :users_contents_tags, :source => :content

  belongs_to :last_updated_item, :class_name => 'Content', :foreign_key => 'last_updated_item_id'
  # before_save :set_slug

  acts_as_rootable
  acts_as_tree :order => 'name'

  has_slug :name
  before_destroy :sanity_check
  before_save :check_references_to_ancestors
  before_save :copy_parent_attrs

  # VALIDATES siempre los últimos
  validates_format_of :slug, :with => /^[a-z0-9_.-]{0,50}$/
  validates_format_of :name, :with => /^.{1,100}$/
  plain_text :name, :description
  validates_uniqueness_of :name, :scope => [:game_id, :bazar_district_id, :gaming_platform_id, :clan_id, :taxonomy, :parent_id]
  validates_uniqueness_of :slug, :scope => [:game_id, :bazar_district_id, :gaming_platform_id, :clan_id, :taxonomy, :parent_id]

  def orphan?
    self.contents.count == 0
  end

  def contents_tagged_count
    raise "Invalid taxonomy" unless self.taxonomy == 'ContentsTag'
    User.db_query("SELECT count(distinct(content_id)) FROM users_contents_tags WHERE term_id = #{self.id}")[0]['count'].to_i
  end


  def sanity_check
    true # return false if self.contents_count > 25
  end

  def copy_parent_attrs
    return true if self.id == self.root_id

    par = self.parent
    self.game_id = par.game_id
    self.bazar_district_id = par.bazar_district_id
    self.gaming_platform_id = par.gaming_platform_id
    self.clan_id = par.clan_id
    if par.taxonomy && par.taxonomy.include?("Category")
      self.taxonomy = par.taxonomy
    end
    true
  end

  def code
    # TODO temp
    slug
  end

  def add_content_type_mask(content_type)
    @content_type_mask = content_type
  end

  def set_slug
    if self.slug.nil? || self.slug.to_s == ''
      self.slug = self.name.bare.downcase
      # TODO esto no comprueba si el slug está repetido
    end
    true
  end

  def import_mode
    @_import_mode || false
  end

  def set_import_mode
    @_import_mode = true
  end

  def link(content, normal_op=true)
    raise "TypeError, arg is #{content.class.name}" unless content.class.name == 'Content'

    # dupcheck, don't link twice.
    if !self.contents.find(:first, :conditions => ['contents.id = ?', content.id]).nil?
      Rails.logger.warn("#{content} is already linked to #{self}")
      return true
    end

    if (Cms::CATEGORIES_TERMS_CONTENTS.include?(content.content_type.name) &&
        !self.taxonomy.include?("Category"))
      Rails.logger.warn(
        "#{self} is a root term but #{content} requires a category" +
        " term.")
      return false if normal_op

      # Exceptional behavior
      taxo = "#{ActiveSupport::Inflector::pluralize(content.content_type.name)}Category"
      t = self.children.find(:first, :conditions => "taxonomy = '#{taxo}'")
      t = self.children.create(:name => 'General', :taxonomy => taxo) if t.nil?
      t.link(content, normal_op)
    elsif Cms::ROOT_TERMS_CONTENTS.include?(content.content_type.name) && self.taxonomy && self.taxonomy.index('Category')
      Rails.logger.warn(
        "Current term has taxonomy: #{self.taxonomy} but the specific content" +
        " #{content} can only be linked to root terms.")
      return false if normal_op
      self.root.link(content, normal_op)
    end

    ct = self.contents_terms.create(:content_id => content.id)

    if normal_op # TODO quitar esto despues de 2009.1
      self.resolve_last_updated_item
      # PERF esto hacerlo en accion secundaria?

      term = self
      while term
        term.update_attributes({
            :contents_count => term.contents_count + 1,
            :comments_count => term.comments_count + content.comments_count})
        term = term.parent
      end

      if self.id == self.root_id || self.taxonomy.include?('Category')
        content.url = nil
        Routing.gmurl(content)
      end
    end
    true
  end

  def unlink(content)
    raise "TypeError" unless content.class.name == 'Content'
    self.contents_terms.find(:all, :conditions => ['content_id = ?', content.id]).each do |ct|
      ct.destroy
    end

    # PERF esto hacerlo en accion secundaria?
    o = self
    while o
      Term.decrement_counter(:contents_count, o.id)
      User.db_query("UPDATE terms SET comments_count = comments_count - #{content.comments_count}")
      o = o.parent
    end
    self.resolve_last_updated_item
    true
  end

  def self.find_taxonomy(id, taxonomy)
    sql_tax = taxonomy.nil? ? 'IS NULL' : "= #{User.connection.quote(taxonomy)}"
    Term.find(:first, :conditions => ["id = ? AND taxonomy #{sql_tax}", id])
  end

  def self.find_taxonomy_by_code(code, taxonomy)
    # Solo para taxonomías toplevel
    Term.find(:first, :conditions => ['id = root_id AND code = ? AND taxonomy = ?', code, taxonomy])
  end

  def self.toplevel(options={})
    conditions = 'id = root_id'
    if options[:clan_id]
      conditions << ' AND clan_id '
      conditions << (options[:clan_id].nil? ? 'IS NULL' : " = #{options[:clan_id].to_i}")
    end

    conditions << " AND slug = #{User.connection.quote(options[:slug])}" if options[:slug]
    conditions << " AND id = #{options[:id].to_i}" if options[:id]

    conditions << " AND game_id = #{options[:game_id].to_i}" if options[:game_id]
    conditions << " AND gaming_platform_id = #{options[:gaming_platform_id].to_i}" if options[:gaming_platform_id]
    conditions << " AND bazar_district_id = #{options[:bazar_district_id].to_i}" if options[:bazar_district_id]
    Term.find(:all, :conditions => conditions, :order => 'lower(name)')
  end

  def self.single_toplevel(opts={})
    raise "Invalid single_toplevel, opts must be Hash!" if opts.class.name != 'Hash'
    self.toplevel(opts)[0]
  end

  # Devuelve los ids de los hijos de la categoría actual o de la categoría obj de forma recursiva incluido el id de obj
  def all_children_ids(opts={})
    cats = [self.id]
    conds = []
    conds << opts[:cond] if opts[:cond].to_s != ''
    conds << "taxonomy = #{User.connection.quote(opts[:taxonomy])}" if opts[:taxonomy]

    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0


    if self.id == self.root_id then # shortcut
      db_query("SELECT id FROM terms WHERE root_id = #{self.id} AND id <> #{self.id} #{cond}").each { |dbc| cats<< dbc['id'].to_i }
    else # hay que ir preguntando categoría por categoría
      if conds.size > 0
        self.children.find(:all, :conditions => cond[4..-1]).each { |child| cats.concat(child.all_children_ids(opts)) }
      else
        self.children.find(:all).each { |child| cats.concat(child.all_children_ids(opts)) }
      end
    end
    cats.uniq
  end

  # devuelve portales relacionados con el término actual
  def get_related_portals
    portals = [GmPortal.new]
    if self.game_id || self.gaming_platform_id
      f = Faction.find_by_code(self.root.slug)
      if f
        portals += Portal.find(:all, :conditions => ['id in (SELECT portal_id from factions_portals where faction_id = ?)', f.id])
      end
    elsif self.bazar_district_id
      portals << self.bazar_district
    elsif self.clan_id
      portals << ClansPortal.find_by_clan_id(self.clan_id)
    else # PERF devolvemos todos por contents como funthings
      portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
    end
    portals
  end

  def recalculate_counters
    recalculate_contents_count
    last = self.get_or_resolve_last_updated_item
    if last && last.state == Cms::DELETED
      self.last_updated_item_id = nil
      # self.save
      self.get_or_resolve_last_updated_item
    end
  end

  def recalculate_contents_count
    newc = ContentsTerm.count(
        :conditions => ["term_id IN (?)", self.all_children_ids(self)])
    self.contents_count = newc
    self.save
  end

  # Finds the last updated item id within this term and updates the
  # last_updated_item_id attribute with whatever is found recursively up to the
  # root.
  def resolve_last_updated_item
    last_content = Content.published.in_term_tree(self).find(
        :first, :order => "updated_on DESC")
    if last_content
      self.last_updated_item_id = last_content.id
    else
      self.last_updated_item_id = nil
    end
    self.save
    self.parent.resolve_last_updated_item if self.parent
  end

  # Returns the last updated item linked to this term. If the attribute is nil
  # it will call resolve_last_updated_item.
  def get_or_resolve_last_updated_item
    self.resolve_last_updated_item if self.last_updated_item_id.nil?
    self.last_updated_item ? self.last_updated_item.real_content : nil
  end

  def last_published_content(cls_name, opts={})
    # opts: user_id
    conds = []
    conds << "user_id = #{opts[:user_id].to_i}" if opts[:user_id]
    conds << opts[:conditions] if opts[:conditions]
    cond = ''
    cond = "#{conds.join(' AND ')}" if conds.size > 0
    if cls_name
      cat_ids = self.all_children_ids(:taxonomy => Term.taxonomy_from_class_name(cls_name))
    else
      cat_ids = self.all_children_ids
    end

    Content.in_term_ids(cat_ids).published.find(
      :first, :conditions => cond, :order => "created_on DESC")
  end

  def can_be_destroyed?
    # primera linea es para categorias no de primer nivel
    # segunda es para categorias de primer nivel
     ((self.root_id != self.id && self.contents_count == 0) || \
    self.root_id == self.id && (self.game_id || self.gaming_platform_id) && Faction.find_by_code(self.code).nil?)
  end

  def self.taxonomy_from_class_name(cls_name)
    "#{ActiveSupport::Inflector::pluralize(cls_name)}Category"
  end

  # valid opts keys: cls_name
  def contents_count(opts={})
    # TODO perf optimizar mas, si el tag tiene el mismo taxonomy que el solicitado
    sql_cond = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    if !opts[:cls_name].nil?
      taxo = self.class.taxonomy_from_class_name(opts[:cls_name])
      User.db_query("SELECT count(*) FROM (SELECT content_id
                                                              FROM contents_terms a
                                                              JOIN terms b on a.term_id = b.id
                                                              JOIN contents on a.content_id = contents.id
                                                             WHERE (((a.term_id IN (#{all_children_ids(:taxonomy => taxo).join(',')})
                                                               AND b.taxonomy = #{User.connection.quote(taxo)})
                                                                OR a.term_id = #{self.id})
                                                                   #{sql_cond})
                                                           GROUP BY content_id
                                                            ) as foo")[0]['count'].to_i

    elsif self.taxonomy
      User.db_query("SELECT count(*) FROM (SELECT content_id
                                                              FROM contents_terms a
                                                              JOIN terms b on a.term_id = b.id
                                                              JOIN contents on a.content_id = contents.id
                                                             WHERE (((a.term_id IN (#{all_children_ids(:taxonomy => self.taxonomy).join(',')})
                                                               AND b.taxonomy = #{User.connection.quote(self.taxonomy)})
                                                                OR a.term_id = #{self.id})
                                                                #{sql_cond})
                                                           GROUP BY content_id
                                                            ) as foo")[0]['count'].to_i
    else # shortcut, show everything
      if self.attributes['contents_count'].nil?
        self.recalculate_counters
        self.reload
        self.attributes['contents_count']
      end
      self.attributes['contents_count']
    end
  end


  def reset_contents_urls
    # TODO PERF más inteligencia
    self.find(:published, :treemode => true).each do |rc|
      uniq = rc.unique_content
      User.db_query("UPDATE contents SET url = NULL, portal_id = NULL WHERE id = #{uniq.id}")
      uniq.reload
      Routing.gmurl(uniq)
      # self.children.each { |child| child.reset_contents}
    end
  end

  # Busca contenidos asociados a este término o a uno de sus hijos
  def find(*args)
    args = _add_cats_ids_cond(*args)
    res = Content.find(*args)

    if res.kind_of?(Array)
      res.uniq.collect { |cont| cont.real_content }
    elsif res
      res.real_content
    end
  end

  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      if Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(method_id.to_s))
        TermContentProxy.new(ActiveSupport::Inflector::camelize(method_id.to_s), self)
      elsif Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
        TermContentProxy.new(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)), self)
      else
        raise "No se que hacer con metodo #{method_id}"
      end
    end
  end

  def respond_to?(method_id, include_priv = false)
    if Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(method_id.to_s))
      true
    elsif Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
      true
    else
      super
    end
  end

  # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
  # TODO se puede optimizar usando caches en categorías para images
  def count(*args)
    args = _add_cats_ids_cond(*args)
    opts = args.pop
    opts.delete(:order) if opts[:order]
    args.push(opts)
    if opts[:joins]
      if opts[:conditions] && opts[:conditions].kind_of?(Array)
        opts[:conditions] = ActiveRecord::Base.send( "sanitize_sql_array", opts[:conditions])
      end
      opts[:joins] << " join contents_terms on contents.id = contents_terms.content_id " unless opts[:joins].include?('contents_terms')
      Content.count_by_sql("SELECT count(*) FROM (SELECT contents.id FROM contents #{opts[:joins]} WHERE #{opts[:conditions]} GROUP BY contents.id) AS foo")
    else
      self.contents.count(*args)
    end
  end


  # acepta keys: treemode (true: incluye categorías de hijos)
  def _add_cats_ids_cond(*args)
    @_add_cats_ids_done = true
    options = {:treemode => true}.merge(args.last.is_a?(Hash) ? args.pop : {}) # copypasted de extract_options_from_args!(args)
    @siblings ||= []

    if options[:treemode]
      @_cache_cats_ids ||= (self.all_children_ids + [self.id])
      @siblings.each { |s| @_cache_cats_ids += s.all_children_ids }
      # options[:conditions] = (options[:conditions]) ? ' AND ' : ''

      new_cond = "term_id IN (#{@_cache_cats_ids.join(',')})"
    else
      new_cond = "term_id IN (#{([self.id] + @siblings.collect { |s| s.id }).join(',')})"
    end

    # si el primer arg es un id caso especial!
    if args.reverse.first.kind_of?(Fixnum)
      nargs = args.reverse
      theid = nargs.pop
      nargs.push(:first)
      raise "find(id) a traves de term sin haber especificado content_type" unless options[:content_type]
      new_cond << " AND #{ActiveSupport::Inflector::tableize(options[:content_type])}.id = #{theid}"
      args = nargs
    end

    if options[:content_type].nil? && options[:content_type_id].nil? && self.taxonomy.to_s.index('Category')
      options[:content_type] = Cms.extract_content_name_from_taxonomy(self.taxonomy)
    end

    if options[:content_type].nil? && options[:content_type_id].nil? && @content_type_mask
      options[:content_type] = @content_type_mask
    end

    if options[:content_type]
      new_cond << " AND contents.content_type_id = #{ContentType.find_by_name(options[:content_type]).id}"
      options[:joins] = "JOIN #{ActiveSupport::Inflector::tableize(options[:content_type])} ON #{ActiveSupport::Inflector::tableize(options[:content_type])}.unique_content_id = contents.id"
    end


    if options[:content_type_id]
      new_cond << " AND contents.content_type_id = #{options[:content_type_id]}"
      ct = ContentType.find(options[:content_type_id])
      options[:joins] = "JOIN #{ActiveSupport::Inflector::tableize(ct.name)} ON #{ActiveSupport::Inflector::tableize(ct.name)}.unique_content_id = contents.id"
      #options[:include] ||= []
      #options[:include] << :contents
    end

    options[:joins] ||= ''
    options[:joins] <<= " JOIN contents_terms on contents.id = contents_terms.content_id "

    options.delete :treemode
    options.delete :content_type
    options.delete :content_type_id

    if options[:conditions].kind_of?(Array)
      options[:conditions][0] = "#{options[:conditions][0]} AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions] = "#{options[:conditions]} AND #{new_cond}"
    else
      options[:conditions] = "#{new_cond}"
    end

    args.push(options)

    agfirst = args.first
    if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
      options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
      new_cond = "contents.state = #{Cms.const_get(agfirst.to_s.upcase)}"

      if options[:conditions].kind_of?(Array)
        options[:conditions][0] = "#{options[:conditions][0]} AND #{new_cond} "
      elsif options[:conditions].to_s != '' then
        options[:conditions] = "#{options[:conditions]} AND #{new_cond} "
      else
        options[:conditions] = new_cond
      end

      options[:order] = "contents.created_on DESC" unless options[:order]
      args[0] = :all
      args.push(options)
    end
    args
  end

  def random(limit=3)
    cat_ids = self.all_children_ids
    self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and #{ActiveSupport::Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'RANDOM()', :limit => limit)
  end

  def most_popular_authors(opts)
    q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    opts[:limit] ||= 5
    dbitems = User.db_query("SELECT count(contents.id),
                                    contents.user_id
                              from #{ActiveSupport::Inflector::tableize(opts[:content_type])}
                              JOIN contents on  #{ActiveSupport::Inflector::tableize(opts[:content_type])}.unique_content_id = contents.id
                             WHERE contents.state = #{Cms::PUBLISHED}#{q_add}
                          GROUP BY contents.user_id
                          ORDER BY sum((coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0))) desc
                             limit #{opts[:limit]}")
    dbitems.collect { |dbitem| [User.find(dbitem['user_id']), dbitem['count'].to_i] }
  end


  def most_rated_items(opts)
    raise "content_type unspecified" unless opts[:content_type] || opts[:joins]
    opts = {:limit => 5}.merge(opts)
    self.find(:published,
              :content_type => opts[:content_type],
              :conditions => "cache_rated_times > 1",
    :order => 'coalesce(cache_weighted_rank, 0) DESC',
    :limit => opts[:limit])
  end

  def most_popular_items(opts)
    opts = {:limit => 3}.merge(opts)
    raise "content_type unspecified" unless opts[:content_type]
    self.find(:published,
              :content_type => opts[:content_type],
              :conditions => "cache_rated_times > 1",
    :order => '(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) DESC',
    :limit => opts[:limit])
  end

  def comments_count
    # TODO perf
    User.db_query("SELECT SUM(A.comments_count)
                     FROM contents A
                     JOIN contents_terms B ON A.id = B.content_id
                    WHERE B.term_id IN (#{all_children_ids.join(',')})
                      AND A.state = #{Cms::PUBLISHED}")[0]['sum'].to_i
  end

  def last_created_items(limit = 3) # TODO esta ya sobra me parece, mirar en tutoriales
    self.find(:published,
              :order => 'created_on DESC',
    :limit => limit)
  end

  def random_item
    # TODO PERF usar campo random_id
    self.find(:published,
              :order => 'random()')
  end

  def last_updated_items(opts={})
    opts = {:limit => 5, :order => 'updated_on DESC'}.merge(opts)
    self.find(:published, opts)
  end


  def last_updated_children(opts={})
    opts = {:limit => 5}.merge(opts)
    sql_cond = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    Content.find_by_sql("SELECT *
                           FROM contents
                          WHERE id IN (SELECT last_updated_item_id
                           FROM terms WHERE id IN (SELECT id FROM terms WHERE parent_id = #{self.id})#{sql_cond})
                       ORDER BY updated_on DESC
                          LIMIT #{opts[:limit]}").collect { |c| c.terms.find(:all, :conditions => "1 = 1 #{sql_cond}")[0] }.compact.sort_by { |e| e.name.downcase }
  end


  # TODO tests
  def most_active_users(taxonomy, time_interval='1 month')
	 return all_time_users(taxonomy, time_interval)
  end

  def all_time_users(taxonomy, time_interval='1 month')
    raise "unsupported" unless taxonomy == 'TopicsCategory'

    q_time = time_interval ? " AND created_on > (now() -  '#{time_interval}'::interval)" : ''

	tbl = {}
    User.db_query("SELECT count(*), user_id
		         FROM contents
		        WHERE contents.id in (SELECT content_id
		      					FROM contents_terms
		      				       WHERE term_id IN (#{all_children_ids(:taxonomy => taxonomy).join(',')}))
		  	    #{q_time}
		     GROUP BY user_id HAVING count(*) > 2
		     ORDER BY count(*) DESC").each do |t|
      tbl[t['user_id'].to_i] = {:karma_sum => Karma::KPS_CREATE['Topic'] * t['count'].to_i,
        :topics => t['count'].to_i,
        :comments => 0}
    end

    User.db_query("SELECT count(*), user_id
		         FROM comments
		        WHERE comments.content_id in (SELECT content_id
		      					FROM contents_terms
		      				       WHERE term_id IN (#{all_children_ids(:taxonomy => taxonomy).join(',')}))
		  	    #{q_time}
		     GROUP BY user_id HAVING count(*) > 2
		     ORDER BY count(*) DESC").each do |c|
		tbl[c['user_id'].to_i] = {:karma_sum => 0, :topics => 0, :comments => 0} unless tbl[c['user_id'].to_i]
		tbl[c['user_id'].to_i][:karma_sum] += Karma::KPS_CREATE['Comment'] * c['count'].to_i
		tbl[c['user_id'].to_i][:comments] += c['count'].to_i
    end

    first = nil
    second = nil
    third = nil
    fourth = nil
    fifth = nil

    inverted = {}
    tbl.keys.each do |u|
	inverted[tbl[u][:karma_sum]] ||= []
	inverted[tbl[u][:karma_sum]] << [u, tbl[u]]
    end


    inverted.keys.sort.reverse.each do |kps|
        break if fifth

	inverted[kps].each do |row|
            break if fifth

	    if first.nil?
		    first = row
	    elsif second.nil?
		    second = row
	    elsif third.nil?
		    third = row
	    elsif fourth.nil?
		    fourth = row
	    else
		    fifth = row
	    end
	end
    end


    # NOTA: tb contamos comentarios de hace más de 3 meses en el top 3 de comentarios
    # buscamos el total de karma generado por este topic
    max = first ? first[1][:karma_sum] : 1 # no es 0 para no dividir por 0

    result = []
    if first
      first[1][:relative_pcent] = 1.0
      result<< [User.find(first[0]), first[1]]
    end

    if second
      second[1][:relative_pcent] = second[1][:karma_sum].to_f / max
      result<< [User.find(second[0]), second[1]]
    end

    if third
      third[1][:relative_pcent] = third[1][:karma_sum].to_f / max
      result<< [User.find(third[0]), third[1]]
    end

    if fourth
      fourth[1][:relative_pcent] = fourth[1][:karma_sum].to_f / max
      result<< [User.find(fourth[0]), fourth[1]]
    end

    if fifth
      fifth[1][:relative_pcent] = fifth[1][:karma_sum].to_f / max
      result<< [User.find(fifth[0]), fifth[1]]
    end

    result
  end

  def most_active_items(content_type)
    # TODO per hit
    # TODO no filtramos
    self.find(:published,
              :conditions => "contents.updated_on > now() - '3 months'::interval",
    :content_type => content_type,
    :order => '(contents.comments_count / extract (epoch from (now() - contents.created_on))) desc',
    :limit => 5)
  end


  def top_contributors(opts)
    total = User.db_query("SELECT count(DISTINCT(A.id))
                                 FROM contents A
                                 JOIN contents_terms B ON A.id = B.content_id
                                  AND B.term_id IN (#{all_children_ids(opts.pass_sym(:taxonomy)).join(',')})
                                WHERE state = #{Cms::PUBLISHED}")[0]['count'].to_f

    # TODO tests
    # devuelve el usuario que más contenidos ha aportado a la categoría
    User.db_query("SELECT user_id, count(DISTINCT(A.id))
                                 FROM contents A
                                 JOIN contents_terms B ON A.id = B.content_id
                                  AND B.term_id IN (#{all_children_ids(opts.pass_sym(:taxonomy)).join(',')})
                                WHERE state = #{Cms::PUBLISHED}
                             GROUP BY user_id
                             ORDER BY count(A.id) DESC
                                LIMIT #{opts[:limit]}").collect do |dbr|
      {:user => User.find(dbr['user_id'].to_i),
       :count => dbr['count'].to_i,
       :pcent => dbr['count'].to_i / total}
    end
  end

  def get_ancestors
    # devuelve los ascendientes. en [0] el padre directo y en el último el root
    path = []
    parent = self.parent

    while parent do
      path<< parent
      parent = parent.parent
    end

    path
  end

  def self.find_by_toplevel_group_code(code)
    case code
      when 'gm'
      Term.single_toplevel(:slug => 'gm').children.find(:all, :order => 'lower(name)')
      when 'juegos'
      Term.find(:all, :conditions => 'id = root_id AND game_id IS NOT NULL', :order => 'lower(name)')
      when 'plataformas'
      Term.find(:all, :conditions => 'id = root_id AND gaming_platform_id IS NOT NULL', :order => 'lower(name)')
      when 'arena'
      Term.single_toplevel(:slug => 'arena').children.find(:all, :order => 'lower(name)')
      when 'bazar'
      Term.find(:all, :conditions => 'id = root_id AND bazar_district_id IS NOT NULL', :order => 'lower(name)')
    else
      raise "toplevel group code '#{code}' unknown"
    end
  end


  def add_sibling(sibling_term)
    raise "sibling_term must be a term but is a #{sibling_term.class.name}" unless sibling_term.class.name == 'Term'
    @siblings ||= []
    @siblings<< sibling_term
  end

  private
  def check_references_to_ancestors
    if !self.new_record?
      if self.parent_id_changed?
        return false if self.parent_id == self.id # para evitar bucles infinitos
        self.root_id = parent_id.nil? ? self.id : self.class.find(parent_id).root_id
        self.class.find(:all, :conditions => "id IN (#{self.all_children_ids.join(',')})").each do |child|
          next if child.id == self.id
          child.root_id = self.root_id
          child.save
        end
      end

      self.delay.reset_contents_urls if self.root_id_changed?
    end
    true
  end

  def self.content_types_from_root(root_term)
    raise "Root term isn't really root, bastard!" unless root_term.id == root_term.root_id
    sql_conds = Cms::CATEGORIES_TERMS_CONTENTS.collect { |s| "'#{s}'"}
    if root_term.game_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.gaming_platform_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.clan_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.bazar_district_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.clan_id
    else # especial
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    end
  end

end

class TermContentProxy
  def initialize(content_name, term)
    @cls_name = content_name
    @term = term
  end

  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:content_type] = @cls_name
      #args.push(opts)
      # args = @term._add_cats_ids_cond(*args)

      # opts = args.last.is_a?(Hash) ? args.pop : {}
      if method_id == :count # && opts[:joins]
        opts.delete :joins
        opts.delete :order
      end
      args.push(opts)
      begin
        res = @term.send(method_id, *args)
        res
      rescue ArgumentError
        @term.send(method_id)
      end
    end
  end
end
