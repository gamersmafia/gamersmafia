# -*- encoding : utf-8 -*-
class GmPortal

  def layout
    'gm'
  end

  def last_comment_on
    (GlobalVars.get_cached_var('last_comment_on') || Time.now).to_time
  end

  def small_header
	  nil
  end

  def id
    -1
  end

  def default_gmtv_channel_id
    1
  end

  def channels
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end

  def name
    'Gamersmafia'
  end

  def code
    'gm'
  end

  def home
    'tetris'
  end

  def skin_id
    nil
  end

  def skins(user)
    # TODO HACK HACK HACK
    [Skin.find_by_hid('default')] + Skin.find(:all)
  end

  def skin
    Skin.find_by_hid('default')
  end

  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        GmPortalPollProxy
      else
        cls_name = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s))
        cls = Object.const_get(cls_name)

        GenericContentProxy.new(cls, 'gm')
      end
    elsif /_categories/ =~ method_id.to_s then
      Term.toplevel(:clan_id => nil)
      # []
    else
      super
    end
  end

  def respond_to?(method_id, include_priv = false)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      true
    elsif /_categories/ =~ method_id.to_s then
      true
    else
      super
    end
  end

  def competitions
    Competition
  end

  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    Term.toplevel(:slug => 'gm')
  end
end

class GmPortalPollProxy
  def self.current
    t = Term.single_toplevel(:slug => 'gm')
    Poll.in_term(t).published.find(
        :all,
        :conditions => Poll::CURRENT_SQL,
        :order => 'polls.created_on DESC',
        :limit => 1)
  end

  def self.method_missing(method_id, *args)
    Term.single_toplevel(:slug => 'gm').poll.send(method_id, *args)
  end
end
