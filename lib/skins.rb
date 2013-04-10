# -*- encoding : utf-8 -*-
module Skins
  module Clans
    def self.available_modules
      %w(online sponsors clan/randomimg webchat clan/events last_commented_objects clan/last_gm_matches clan/next_gm_matches tracker clan/members clan/visitas clan/poll clan/friends)
    end
  end

  def self.retrieve_portal_favicon(favicon_path)
    begin
      portal_favicon = Magick::Image.read("#{Rails.root}/public/#{favicon_path}").first
      if portal_favicon.columns != 16 || portal_favicon.rows != 16
        invalid_image = true
        Rails.logger.error("ERROR: #{favicon_path} is not a 16x16 image.")
        portal_favicon = nil
      end
    rescue Exception => e
      invalid_image = true
      Rails.logger.error("Cannot read image #{favicon_path}: #{e}")
    end
    portal_favicon
  end

  def self.update_portal_favicons
    builtin_portals = [
      Game.new(:slug => 'gm'),
      Game.new(:slug => 'bazar'),
      Game.new(:slug => 'arena'),
    ]

    entities_with_portals = (
        builtin_portals +
        BazarDistrict.find(:all, :order => 'id') +
        GamingPlatform.find(:all, :conditions => "has_faction = 't'", :order => 'id') +
        Game.find(:all, :conditions => "has_faction = 't'", :order => 'id')
    )
    css_out = ''
    sprite = Magick::Image.new(entities_with_portals.size * 16, 16) { |im|
      im.background_color = 'none'
    }
    i = 0
    entities_with_portals.each do |entity|
      invalid_image = false
      if entity.respond_to?(:icon) && entity.icon.to_s != ""
        favicon_path = entity.icon
      else
        favicon_path = "storage/games/#{entity.icon}.gif"
      end
      portal_favicon = self.retrieve_portal_favicon(favicon_path)
      # Copy game sprite to big sprite
      if portal_favicon
        sprite = sprite.store_pixels(
            i * 16, 0, 16, 16, portal_favicon.get_pixels(0, 0, 16, 16))
      end

      idx_for_sprite = portal_favicon ? i : 0
      css_out<< ("img.gs-#{entity.slug} { background-position: " +
                 "-#{idx_for_sprite*16}px 0; }\n")
      i += 1
    end

    File.open(Skin::FAVICONS_CSS_FILENAME, 'w') {|f| f.write(css_out)}
    sprite.quantize.write("#{Rails.root}/public/storage/gs.png")
  end

  def self.convert_strings_to_attribute_wrappers(attributes, options)
    options_f = {}
    options.each { |k,v| options_f[k.to_sym] = v } # pasamos keys a symbols
    # transformamos las opciones en sus wrappers correspondientes
    attributes.each do |k,v|
      if options_f[k] && !options_f[k].kind_of?(v.class)
        if %w(Percent Hue).include?(
            ActiveSupport::Inflector::demodulize(v.class.name))
          options_f[k] = options_f[k].to_i
        end

        if v.class.name == 'Skins::RgbColor' && options_f[k] == ''
          options_f[k] = 'transparent'
        else
          options_f[k] = v.class.new(options_f[k])
        end

      end
    end
    options_f
  end

  class Hue
    attr_accessor :value

    def initialize(value)
      raise TypeError unless value.kind_of?(Fixnum)
      if value < 0
        @value = 360 + value
      elsif value > 360
        @value = value % 360
      else
        @value = value
      end
    end

    def to_s
      @value.to_s
    end
  end

  class Percent
    attr_accessor :value

    def initialize(value)
      raise TypeError unless value.kind_of?(Fixnum)
      if value < 0
        @value = 100 + value
      elsif value > 100
        @value = 100
      else
        @value = value
      end
    end

    def to_s
      @value.to_s
    end
  end

  class RgbColor
    attr_accessor :value

    def initialize(value)
      if value.kind_of?(Array) # [r, g, b] as ints from 0 to 255
        @value = value
      elsif value.kind_of?(String) && value.length == 6 # value is like "ffffff"
        @value = [value.hex & 0xFF0000, value.hex & 0x00FF00, value.hex & 0x0000FF]
      elsif value.kind_of?(String) && value.length == 7 # value is like "#ffffff"
        value = value[1..6]
        @value = [value.hex & 0xFF0000, value.hex & 0x00FF00, value.hex & 0x0000FF]
      elsif value.nil?
        @value = [0,0,0] # default is black
      else
        raise "Unable to initialize RgbColor with value #{value}"
      end
    end

    def to_s
      sum = 0
      @value.each { |v| sum += v }
      sprintf("#%02x", sum).rjust(6, '0')
    end
  end

  COLORS_STRICT = {}

  COLORS_STRICT_OLD = {
    :body_background_color => '',
    :body_color => '',
    :a_nav_color => '',
    :a_content_color => '',
    :a_action_color => '',
    :a_content_visited_color => '',
    :module_title_background_color => '',
    :module_title_color => '',
    :module_content_background_color => '',
    :module_content_color => '',
    :container_background_color => '',
    :info_color => '',
    :a_info_color => '',
    :icons_actionable => '',
    :icons_non_actionable => '',
    :updated_since_last_visit => '',
    :progress_bars_background_color => '',
    :progress_bars_border_color => '',
    :progress_bars_fill_background_color => '',
    :karma => '',
    :ads_background_color => '',
    :ads_text_color => '',
    :a_ads_color => '',
    :good_background_color => '',
    :good_color => '',
    :good_border_color => '',
    :bad_background_color => '',
    :bad_border_color => '',
    :bad_color => '',
    :comments_header_unread => '',
    :selected_row_background_color => '',

    :macro_quote_color => '',
    :macro_quote_background_color => '',

    :form_text_and_selects_color => '',
    :form_text_and_selects_background_color => '',
  }

  COLORS_OPTIONAL = {
    :cpagein_background_color => '',
    :cpageout_background_color => '',
    :selected_row_color => '',
    :th_background_color => '',
    :th_color => '',
    :module_content_alt_background_color => '',
    :a_nav_hover_color => '',
    :a_content_hover_color => '',
    :a_action_hover_color => '',
    :a_info_hover_color => '',
    :container_border_color => '',
    :module_border_color => '',
    :module_title_border_color => '',
    :module_content_border_color => '',

    :ccontent_container_border_color => '',
    :ccontent_module_background_color => '',
    :ccontent_module_border_color => '',

    :ccontent_module_title_border_color => '',
    :ccontent_module_content_border_color => '',

    :ccontent_container_background_color => '',
    :ccontent_module_title_color => '',
    :ccontent_module_title_background_color => '',
    :ccontent_module_content_color => '',
    :ccontent_module_content_background_color => '',

    :heatmap1 => '',
    :heatmap2 => '',
    :heatmap3 => '',

    :form_button_color => '',
    :form_button_border_color  => '',
    :form_button_background_color  => '',


    :form_text_and_selects_border_color => '',

    :macro_quote_border_color => '',
  }

  module ColorGenerators

    def self.generators
      Skins::ColorGenerators.constants.collect { |c| Skins::ColorGenerators.const_get(c) unless c == 'AbstractGenerator' }.compact
    end

    def self.invert_color(color)
      color.gsub!(/^#/, '')
      sprintf("%X", color.hex ^ 0xFFFFFF)
    end

    # h, s, v están entre 0.0 y 1.0
    def self.hsv_to_rgbNEW(h, s, v)
      return [v, v, v] if s == 0.0 #
      i = h.floor
      f = h - i #
      p = v*(1.0 - s) #
      q = v*(1.0 - s*f) #
      t = v*(1.0 - s*(1.0-f)) #
      return [v, t, p] if i % 6 == 0
      return [q, v, p] if i == 1
      return [p, v, t] if i == 2
      return [p, q, v] if i == 3
      return [t, p, v] if i == 4
      return [v, p, q] if i == 5
      # Cannot get here
    end

    # h, s, v están entre 0.0 y 1.0
    def self.hsv_to_rgb(h, s, v)
      h = 1 - h if h > 1
      h = 1 + h if h < 0
      return [v, v, v] if s == 0.0
      i = (h*6.0).floor # XXX assume int() truncates!
      f = (h*6.0) - i
      p = v*(1.0 - s)
      q = v*(1.0 - s*f)
      t = v*(1.0 - s*(1.0-f))
      return [v, t, p] if i % 6 == 0
      return [q, v, p] if i == 1
      return [p, v, t] if i == 2
      return [p, q, v] if i == 3
      return [t, p, v] if i == 4
      return [v, p, q] if i == 5
      # Cannot get here
    end

    def self.rgb_to_hsv(r, g, b)
      v = [r, g, b].max
      delta = v - [r, g, b].min

      if( v == 0 )
        #// r = g = b = 0    // s = 0, v is undefined
        s = 0
        h = -1
        return [h/360.0, s, v]
      else
        s = delta / v   # s
        delta = 1 if delta == 0
        if( r == v )
          h = ( g - b ) / delta #;   // between yellow & magenta
        elsif( g == v )
          h = 2 + ( b - r ) / delta #; // between cyan & yellow
        else
          h = 4 + ( r - g ) / delta #; // between magenta & cyan
        end

        h *= 60 #;       // degrees
        if( h < 0 )
          h += 360
        end
        [h/360.0, s, v]
      end
    end



    # r, g, b están entre 0.0 y 1.0
    def self.rgb_to_hsvOLD(r, g, b)
      h = 0.0 #
      s = 0.0 #
      v = [r, g, b].max #
      d = v - [r, g, b].min #
      d = 1.0 if d == 0
      if v != 0 #
        s = d / v.to_f #
      end #
      if s != 0 then
        if r == v then
          h = 0.0 + (g-b) / d
        elsif g == v then
          h = 2.0 + (b-r) / d
        end
      else
        h = 4.0 + (r-g) / d
      end

      h = h * (60.0/360)
      if h < 0
        h = h + 1.0
      end
      return h, s, v
    end

    # acepta hex y devuelve triplete entre 0.0 y 1.0
    def self.rgbhex_to_rgb(str)
      hex = str.hex
      r = (hex & 0xff0000) / 0xff0000.to_f
      g = (hex & 0x00ff00) / 0x00ff00.to_f
      b = (hex & 0x0000ff) / 0x0000ff.to_f
      [r, g, b]
    end

    class AbstractGenerator
      CSS_REGEXP_OPTIONAL = "${pat};"
      def self.get_re_for_key(k)
        raise TypeError unless k.kind_of?(String)
        re = Regexp.new("([a-z-]+: ##{Regexp.escape(CSS_REGEXP_OPTIONAL.gsub('pat', k.to_s))})")
      end

      protected
      def self.initialize

      end


      public
      def self.process(options)
        options_f = Skins::convert_strings_to_attribute_wrappers(attributes, options)
        skin_colors = get_colors(options_f)
        base_color_generators_dir = "#{Rails.root}/config/skins/color_generators"
        css_tpl = File.open("#{base_color_generators_dir}/_core.css").read
        # core.css
        COLORS_STRICT.keys.each do |k|
          css_tpl.gsub!("${#{k}}", skin_colors.fetch(k))
        end

        COLORS_OPTIONAL.keys.each do |k|

          if skin_colors.keys.include?(k)

            css_tpl.gsub!("${#{k}}", skin_colors.fetch(k))
          else # remove css declarations from file
            re = get_re_for_key(k.to_s)
            css_tpl = css_tpl.gsub(re, '')
          end
        end

        # custom style.css si lo incluye
        f_custom = "#{base_color_generators_dir}/#{self.name.demodulize}.css"
        if File.exists?(f_custom)
          css_tpl2 = File.open(f_custom).read
          get_colors(options_f).each do |k,v|
            css_tpl2.gsub!("${#{k}}", v)
          end
          css_tpl = css_tpl<< css_tpl2
        end
        css_tpl
      end

      def self.attributes
        self::DEF_OPTIONS
      end
    end

    class BlackSpot < AbstractGenerator
      # valid options keys: hue
      DEF_OPTIONS = {:hue => Hue.new(60)}
      def self.get_colors(options=nil)
        options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
        h = options[:hue].value.to_f / 360.0 # degrees

        #base_b = (100.0 - float(params['darkness'])) / 100.0 # 0 a 100
        s = {}
        # all formats are as follows: (hue, saturation, balance)

        # NEW FORMAT
        s[:body_background_color]           = [h-0.03, 0.88, 0.13]
        s[:body_color]                      = [h-0.03, 0.01, 0.66]

        s[:icons_non_actionable] = [h, 1.0, 1.0] # TODO
        s[:icons_actionable] = [h, 1.0, 1.0] # TODO

        s[:bad_background_color] = [h, 0.0, 0.0] # TODO
        s[:bad_color] = [h, 1.0, 1.0] # TODO
        s[:updated_since_last_visit] = [h, 1.0, 1.0] # TODO

        s[:ads_text_color] = s[:body_color] # TODO
        s[:macro_quote_background_color] = [h, 0.98, 0.18] # TODO confirm
        s[:macro_quote_color] = [0, 1.0, 1.0] # TODO confirm
        s[:progress_bars_background_color] = [h, 0.98, 0.18]
        s[:progress_bars_fill_background_color] = [h, 1.0, 0.69]
        s[:progress_bars_border_color] = [h, 1.0, 0.69]
        s[:karma] = [0.56, 0.78, 0.75]
        s[:ads_background_color] = [h, 0.1, 0.1]
        s[:selected_row_background_color] = [h, 0.5, 0.5] # TODO

        s[:form_text_and_selects_color] = [h, 0.11, 0.00]
        s[:form_text_and_selects_background_color] = [h + 0.01, 0.11, 1.00]

        s[:a_content_color]                      = [h, 0.94, 0.99]
        s[:a_content_visited_color]              = [h, 0.94, 0.99]
        s[:a_content_hover_color]                = [h, 0.66, 0.99]
        s[:a_nav_color] = s[:a_content_color]
        s[:a_nav_hover_color] = s[:a_content_hover_color]
        s[:a_action_color] = s[:a_content_color]
        s[:a_action_hover_color] = s[:a_content_hover_color]
        s[:a_ads_color] = [h-0.03, 0.01, 0.66] # TODO
        s[:a_info_color] = s[:a_nav_color] # TODO
        s[:a_info_hover_color] = s[:a_nav_color] # TODO
        s[:module_content_color] = s[:body_color] # TODO
        s[:module_content_background_color] = [h, 1.0, 0.22] # TODO
        s[:module_title_background_color]        = [h, 1.0, 0.10] # TODO
        s[:module_title_color]            = [h+0.12, 0.10, 1.00] # [h+0.12, 1.00, 0.44] para enlaces de nav?
        # s[:ccontent_module_title_background_color:] =
        # s[:ccontent_module_content_background_color]        = [h, 1.00, 0.10] # TODO

        s[:container_background_color]                       = s[:body_background_color]

        # OLD
        #s[:cpagein_background_color] = s[:body_background_color]
        s[:cpageout_background_color]   = [h, 1.00, 0.28]
        #s[:module_content_color]                   = s[:body_color]


        #s[:nav_titles_color]                = [h + 0.13, 0.95, 0.61]
        #s[:nav_color]                       = s[:body_color]
        #s[:nav_background_color]            = s[:ccontent_module_content_background_color]
        s[:info_color]                      = [h, 0.01, 0.43]
        #s[:info_background_color]           = s[:ccontent_module_content_background_color]

        s[:comments_background_color]       = s[:body_background_color]
        s[:comments_border_color]           = [h, 0.0, 0.0]
        s[:comments_header_unread]           = [h, 0.1, 0.1] # TODO




        # TODO custom
        s[:box_borders_colors] = [h, 0.95, 0.30]
        # END OLD

        colors_generated = {}
        s.each do |k,v|
          colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v| sprintf("%02x", (v*255).to_i) }.join
        end
        colors_generated[:good_color] = '90ee7d'
        colors_generated[:good_border_color] = '1eb000'
        colors_generated[:good_background_color] = '126b00'
        colors_generated[:bad_color] = 'ed7e7e'
        colors_generated[:bad_border_color] = 'b00000'
        colors_generated[:bad_background_color] = '6b0000'
        colors_generated
      end
    end

    class Dark < AbstractGenerator
      DEF_OPTIONS = {:hue => Hue.new(60), :darkness => Percent.new(85)}

      def self.get_colors(options=nil)
        options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
        # TODO protecciones contra valores de colores disparatados
        options[:darkness] = Percent.new(30) if options[:darkness].nil? || options[:darkness].value.to_i < 10


        h = options[:hue].value.to_f / 360.0 # degrees
        base_b = (100.0 - options[:darkness].value.to_f) / 100.0 # 0 a 100
        s = {}
        # all formats are as follows: [hue, saturation, balance]
        # DEFINITIVO
        s[:body_background_color]            = [h, 0.44, base_b]
        s[:body_color]                       = [h, 0.05, base_b + 0.58]
        s[:cpagein_background_color]         = [h, 0.86, base_b]
        s[:cpageout_background_color]   = [h, 0.70, base_b + 0.02]
        s[:ccontent_module_content_background_color] = [h, 0.57, base_b + 0.06]
        s[:module_content_background_color]         = [h, 0.57, base_b + 0.06]
        s[:module_title_color]              = [h, 0.43, base_b + 0.80]
        s[:module_content_color]            = [h, 0.05, base_b + 0.58]
        s[:module_title_background_color]   = [h, 0.59, base_b + 0.20]
        s[:form_text_and_selects_color]     = [h, 0.20, base_b + 0.90]
        s[:form_text_and_selects_background_color] = [h, 0.59, base_b + 0.20]

        # OLD
        s[:nav_titles_color]                = [0.0, 0.65, 0.0]
        s[:nav_color]                       = [h, 0.05, base_b + 0.58]
        s[:nav_background_color]            = [h, 0.44, base_b + 0.12]
        s[:info_color]                      = [h, 0.05, base_b + 0.58]
        s[:info_background_color]           = [h, 0.44, base_b + 0.12]

        s[:comments_background_color]       = [h, 0.19, base_b + 0.10]
        s[:comments_border_color]           = [h, 0.0, 0.0]

        s[:link_color]         = [h - 0.03, 0.54, base_b + 0.81]
        s[:link_visited_color] = [h - 0.03, 0.54, base_b + 0.66]
        s[:link_hover_color]   = [h - 0.03, 0.27, base_b + 0.81]

        # TODO temp
        s[:a_nav_color] = s[:link_color]
        s[:nav_link_visited_color] = s[:a_nav_color]
        s[:nav_link_hover_color] = s[:a_nav_color]

        # TODO temp
        s[:info_link_color] = s[:link_color]
        s[:info_link_visited_color] = s[:link_color]
        s[:info_link_hover_color] = s[:link_color]

        s[:box_borders_colors] = [h, 0.44, base_b]
        s[:icons_actionable] = [h, 0.44, base_b]
        s[:ads_text_color] = [h, 0.44, base_b]
        # s[:module_content_background_color] = [h, 0.44, base_b]
        s[:comments_header_unread] = [h, 0.44, base_b]
        s[:icons_non_actionable] = [h, 0.44, base_b]
        s[:a_content_color] = [h, 0.44, base_b]
        s[:a_ads_color] = [h, 0.44, base_b]

        s[:selected_row_background_color] = [h, 0.44, base_b]
        s[:updated_since_last_visit] = [h, 0.44, base_b]
        s[:a_action_color] = [h, 0.44, base_b]
        s[:good_background_color] = [h, 0.44, base_b]
        s[:container_background_color] = [h, 0.44, base_b]
        s[:macro_quote_color] = [h, 0.44, base_b]
        s[:progress_bars_background_color] = [h, 0.44, base_b]
        s[:progress_bars_fill_background_color] = [0, 0.98, 0.18] # TODO confirm
        s[:progress_bars_border_color] = [0, 0.98, 0.18] # TODO confirm
        s[:a_content_visited_color] = [h, 0.44, base_b]
        s[:bad_background_color] = [h, 0.44, base_b]
        s[:karma] = [h, 0.44, base_b]
        s[:macro_quote_background_color] = [h, 0.44, base_b]

        s[:good_color] = [h, 0.44, base_b]
        s[:a_info_color] = [h, 0.44, base_b]

        s[:ads_background_color] = [h, 0.44, base_b]
        s[:bad_color] = [h, 0.44, base_b]
        s[:bad_border_color] = [h, 0.44, base_b]
        s[:good_border_color] = [h, 0.44, base_b]


        colors_generated = {}
        s.each { |k,v| colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v| sprintf("%02x", (v*255).to_i) }.join }
        colors_generated
      end
    end



    class OnWhite < AbstractGenerator
      DEF_OPTIONS = {:hue => Hue.new(60)}

      def self.get_colors(options=nil)
        options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
        # TODO protecciones contra valores de colores disparatados

        h = options[:hue].value.to_f / 360.0 # degrees
        s = {}

        # DEFINITIVO
        s[:body_color] = [h, 1.00, 0.10]

        s[:module_title_color] = [h, 0.0, 1.0]
        s[:module_title_background_color] = [h, 1.0, 0.75]
        s[:module_content_background_color] = [h, 0, 1]
        s[:module_content_color] = s[:body_color]
        s[:container_background_color] = [h, 0, 1.0]

        s[:form_text_and_selects_background_color] = [h, 0.2, 0.97]
        s[:form_text_and_selects_color] = s[:body_color]


        # OLD
        s[:nav_background_color] = [h, 0.70, 0.45]

        s[:info_background_color] = [h, 0.05, 1.00]



        s[:comments_background_color]       = [h, 0.05, 0.95]
        s[:comments_border_color]           = [h, 0.10, 0.85]


        s[:a_nav_color] = [h, 0.85, 0.75]
        s[:nav_link_hover_color] = [h, 0.00, 1.00]
        s[:nav_link_visited_color] = s[:a_nav_color]

        s[:link_color] = [h, 1.00, 0.90]
        s[:link_hover_color] = [h, 0.40, 1.00]
        s[:link_visited_color] = [h, 1.00, 0.70]

        s[:module_content_color] = s[:body_color]



        s[:info_link_color] = [h, 0.90, 0.60]
        s[:info_link_hover_color] = [h, 0.90, 1.00]
        s[:info_link_visited_color] = s[:link_visited_color]

        s[:box_borders_colors] = [h, 0.40, 1.00]



        # NEW
        s[:icons_actionable] = [h, 0.44, 0.85] # TODO

        s[:ads_text_color] = [h, 0.44, 0.85] # TODO

        s[:comments_header_unread] = [h, 0.44, 0.85] # TODO
        s[:icons_non_actionable] = [h, 0.44, 0.85] # TODO
        s[:a_content_color] = s[:link_color]
        s[:a_ads_color] = [h, 0.44, 0.85] # TODO

        s[:selected_row_background_color] = [h, 0.44, 0.85] # TODO
        s[:updated_since_last_visit] = [h, 0.44, 0.85] # TODO
        s[:a_action_color] = [h, 0.44, 0.85] # TODO
        s[:good_background_color] = [h, 0.44, 0.85] # TODO

        s[:macro_quote_color] = [h, 0.44, 0.85] # TODO
        s[:progress_bars_background_color] = [h, 0.44, 0.85] # TODO
        s[:progress_bars_fill_background_color] = [0, 0.98, 0.18] # TODO confirm
        s[:progress_bars_border_color] = [0, 0.98, 0.18] # TODO confirm
        s[:a_content_visited_color] = [h, 0.44, 0.85] # TODO
        s[:bad_background_color] = [h, 0.44, 0.85] # TODO
        s[:karma] = [h, 0.44, 0.85] # TODO
        s[:macro_quote_background_color] = [h, 0.44, 0.85] # TODO

        s[:good_color] = [h, 0.44, 0.85] # TODO
        s[:a_info_color] = [h, 0.44, 0.85] # TODO

        s[:ads_background_color] = [h, 0.44, 0.85] # TODO

        s[:bad_color] = [h, 0.44, 0.85] # TODO
        s[:good_border_color] = [h, 0.44, 0.85] # TODO
        s[:bad_border_color] = [h, 0.44, 0.85] # TODO



        colors_generated = {}
        s.each { |k,v| colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v| sprintf("%02x", (v*255).to_i) }.join }
        colors_generated

        colors_generated[:body_background_color] = 'eeeeee'
        colors_generated[:cpageout_background_color] = 'eeeeee'
        colors_generated[:cpagein_background_color] = 'ffffff'
        colors_generated[:ccontent_module_content_background_color] = 'ffffff'
        colors_generated[:cpageout_background_color] = '000000'
        colors_generated[:nav_color] = 'b3b3b3'
        colors_generated[:info_color] = '000000'
        colors_generated
      end
    end

    if nil then
      class MonoChromatic < AbstractGenerator
      DEF_OPTIONS = {:hue => Hue.new(60)}

      def self.get_colors(options=nil)
        options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)

        # TODO protecciones contra valores de colores disparatados

        h = options[:hue].value.to_f / 360.0 # degrees
        s = {}

        # DEFINITIVOS
        s[:container_background_color] = [h, 0.44, 0.85]


        # TODO

        # all formats are as follows: (hue, saturation, balance)
        s[:body_background_color]           = [h, 0.03, 0.65]
        s[:body_color]                      = [h, 0.21, 0.42]
        s[:cpagein_background_color] = s[:body_background_color]
        s[:ccontent_module_background_color] = [h, 0.21, 0.42]
        s[:content_title_color]            = [0.0, 0.03, 0.75]
        s[:cpageout_background_color]   = [h, 0.70, 0.02]
        s[:module_content_color]                   = [h, 0.21, 0.42]
        s[:module_content_background_color]        = [h, 0.03, 0.75]
        s[:module_title_background_color]        = [h, 0.21, 0.42]
        s[:headers_color]                   = [h, 0.03, 0.75]
        s[:nav_titles_color]                = [h, 0.03, 0.75]
        s[:nav_color]                       = s[:body_color] # TODO no se usa
        s[:nav_background_color]            = [h, 0.03, 0.75]
        s[:info_color]                      = s[:body_color]
        s[:info_background_color]           = [h, 0.03, 0.75]
        s[:comments_background_color]       = [h, 0.06, 0.70]
        s[:comments_border_color]           = [h, 0.05, 0.60]

        s[:link_color]         = [h, 1.00, 0.55]
        s[:link_visited_color] = [h, 1.00, 0.36]
        s[:link_hover_color]   = [h, 0.93, 1.00]

        s[:box_borders_colors] = [h, 0.21, 0.42]

        # TODO temp
        s[:a_nav_color] = s[:link_color]
        s[:nav_link_visited_color] = s[:a_nav_color]
        s[:nav_link_hover_color] = s[:a_nav_color]

        s[:info_link_visited_color]         = s[:link_visited_color]
        s[:info_link_color]                 = s[:link_color]
        s[:info_link_hover_color]           = s[:link_hover_color]


        # custom
        # TODO estos deberÃ­an estar contemplados por todas las skins, no?
        s[:outside_elements_background_color]        = [h, 0.21, 0.42]
        s[:outside_elements_color]                   = [h, 0.03, 0.85]
        s[:outside_elements_link_color]              = [h, 0.12, 0.85]

        s[:icons_actionable] = [h, 0.44, 0.85]
        s[:form_text_and_selects_background_color] = [h, 0.44, 0.85]
        s[:ads_text_color] = [h, 0.44, 0.85]

        s[:comments_header_unread] = [h, 0.44, 0.85]
        s[:icons_non_actionable] = [h, 0.44, 0.85]
        s[:a_content_color] = [h, 0.44, 0.85]
        s[:a_ads_color] = [h, 0.44, 0.85]

        s[:selected_row_background_color] = [h, 0.44, 0.85]
        s[:updated_since_last_visit] = [h, 0.44, 0.85]
        s[:a_action_color] = [h, 0.44, 0.85]
        s[:good_background_color] = [h, 0.44, 0.85]

        s[:macro_quote_color] = [h, 0.44, 0.85]
        s[:progress_bars_background_color] = [h, 0.44, 0.85]
        s[:progress_bars_fill_background_color] = [0, 0.98, 0.18] # TODO confirm
        s[:progress_bars_border_color] = [0, 0.98, 0.18] # TODO confirm
        s[:a_content_visited_color] = [h, 0.44, 0.85]
        s[:bad_background_color] = [h, 0.44, 0.85]
        s[:karma] = [h, 0.44, 0.85]
        s[:macro_quote_background_color] = [h, 0.44, 0.85]

        s[:good_color] = [h, 0.44, 0.85]
        s[:a_info_color] = [h, 0.44, 0.85]
        s[:form_text_and_selects_color] = [h, 0.44, 0.85]
        s[:ads_background_color] = [h, 0.44, 0.85]
        s[:module_title_color] = [h, 0.44, 0.85]
        s[:bad_color] = [h, 0.44, 0.85]
        s[:bad_border_color] = [h, 0.44, 0.85]
        s[:good_border_color] = [h, 0.44, 0.85]


        colors_generated = {}
        s.each { |k,v|
          colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v|
            sprintf("%02x", (v*255).to_i) }.join
        }
        colors_generated
      end
    end

      class Random < AbstractGenerator
        DEF_OPTIONS = {}

        def self.get_colors(options=nil)
          colors2gen = ['pagebg_color', 'text_color', 'link_color', 'nav_link_color', 'nav_color', 'content_color', 'ccontent_module_content_background_color', 'info_link_color', 'nav_background_color', 'link_hover_color', 'box_borders_colors', 'info_link_hover_color', 'nav_link_visited_color', 'info_background_color', 'body_background_color', 'info_link_visited_color', 'info_color', 'link_visited_color', 'nav_link_hover_color', 'cpageout_background_color', 'body_color', 'cpagein', 'module_header_background_color', 'icons_actionable', 'form_text_and_selects_background_color', 'ads_text_color', 'module_content_background_color', 'comments_header_unread', 'icons_non_actionable', 'a_content_color', 'a_ads_color', 'module_content_color', 'selected_row_background_color', 'updated_since_last_visit', 'a_action_color', 'good_background_color', 'container_background_color', 'macro_quote_color', 'progress_bars_background_color', 'progress_bars_border_color', 'progress_bars_fill_background_color', 'a_content_visited_color', 'bad_background_color', 'karma', 'macro_quote_background_color', 'module_title_background_color', 'good_color', 'a_info_color', 'form_text_and_selects_color', 'ads_background_color', 'module_title_color', 'bad_color', 'a_nav_color', 'good_border_color', 'bad_border_color' ]

          colors_generated = {}
          colors2gen.each do |x|
            # TODO: seguro que se puede hacer mejor, con ^ FFFFFF para generar colores inversos, etc
            colors_generated[x.to_sym] = [Kernel.rand * 255, Kernel.rand * 255, Kernel.rand * 255].collect { |v| sprintf("%02x", (v*255).to_i) }.join
          end
          colors_generated
        end
      end


      class Shapeshifter < AbstractGenerator
        DEF_OPTIONS = {:shape => 'esr'}

        def self.get_colors(options=nil)
          options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
          s = self.send("get_colors_#{options[:shape]}")
          colors_generated = {}
          s.each { |k,v| colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v| sprintf("%02x", (v*255).to_i) }.join }
          colors_generated
        end

        def self.get_colors_esr
          bg_h = 180 / 360.0 # degrees
          hilit_h = 16 / 360.0

          s = {}
          # all formats are as follows: (hue, saturation, balance)
          s[:body_background_color]           = [bg_h, 0.01, 0.40]
          s[:body_color]                      = [bg_h, 0.01, 0.88]
          s[:cpagein_background_color] = s[:body_background_color]
          s[:ccontent_module_background_color] = [0.0, 0.0, 0.12]
          s[:content_title_color]            = [hilit_h, 0.84, 0.98]
          s[:cpageout_background_color]   = [bg_h, 0.02, 0.20]
          s[:module_content_color]                   = s[:body_color]
          s[:ccontent_module_content_background_color]        = [bg_h, 0.02, 0.26]
          s[:module_title_background_color]        = [bg_h, 0.02, 0.26]
          s[:nav_titles_color]                = [0.0, 0.0, 0.12]
          s[:nav_color]                  = s[:body_color]
          s[:nav_background_color]            = s[:ccontent_module_content_background_color]
          s[:info_color]                      = s[:body_color]
          s[:info_background_color]           = s[:ccontent_module_content_background_color]

          s[:comments_background_color]       = [bg_h, 0.04, 0.35]
          s[:comments_border_color]           = [0.0, 0.0, 0.0]

          s[:link_color]         = [hilit_h, 0.84, 0.98]
          s[:link_visited_color] = [hilit_h, 0.62, 0.98]
          s[:link_hover_color]   = [hilit_h, 1.00, 1.00]

          s[:a_nav_color] = [0.0, 0.0, 0.71]
          s[:nav_link_visited_color] = [0.0, 0.0, 0.50]
          s[:nav_link_hover_color] = [0.0, 0.0, 1.00]

          s[:info_link_visited_color] = s[:link_visited_color]
          s[:info_link_color] = s[:link_color]
          s[:info_link_hover_color] = s[:link_hover_color]


          # TODO custom
          s[:box_borders_colors] = [bg_h, 0.02, 0.23]

          s[:icons_actionable] = [bg_h, 0.44, 0.85]
          s[:form_text_and_selects_background_color] = [bg_h, 0.44, 0.85]
          s[:ads_text_color] = [bg_h, 0.44, 0.85]
          s[:module_content_background_color] = [bg_h, 0.44, 0.85]
          s[:comments_header_unread] = [bg_h, 0.44, 0.85]
          s[:icons_non_actionable] = [bg_h, 0.44, 0.85]
          s[:a_content_color] = [bg_h, 0.44, 0.85]
          s[:a_ads_color] = [bg_h, 0.44, 0.85]
          s[:module_content_color] = [bg_h, 0.44, 0.85]
          s[:selected_row_background_color] = [bg_h, 0.44, 0.85]
          s[:updated_since_last_visit] = [bg_h, 0.44, 0.85]
          s[:a_action_color] = [bg_h, 0.44, 0.85]
          s[:good_background_color] = [bg_h, 0.44, 0.85]
          s[:container_background_color] = [bg_h, 0.44, 0.85]
          s[:macro_quote_color] = [bg_h, 0.44, 0.85]
          s[:progress_bars_background_color] = [bg_h, 0.44, 0.85]
          s[:progress_bars_fill_background_color] = [0, 0.98, 0.18] # TODO confirm
          s[:progress_bars_border_color] = [0, 0.98, 0.18] # TODO confirm
          s[:a_content_visited_color] = [bg_h, 0.44, 0.85]
          s[:bad_background_color] = [bg_h, 0.44, 0.85]
          s[:karma] = [bg_h, 0.44, 0.85]
          s[:macro_quote_background_color] = [bg_h, 0.44, 0.85]
          s[:module_title_background_color] = [bg_h, 0.44, 0.85]
          s[:good_color] = [bg_h, 0.44, 0.85]
          s[:a_info_color] = [bg_h, 0.44, 0.85]
          s[:form_text_and_selects_color] = [bg_h, 0.44, 0.85]
          s[:ads_background_color] = [bg_h, 0.44, 0.85]
          s[:module_title_color] = [bg_h, 0.44, 0.85]
          s[:bad_color] = [bg_h, 0.44, 0.85]
          s[:bad_border_color] = [bg_h, 0.44, 0.85] # TODO
          s[:good_border_color] = [bg_h, 0.44, 0.85] # TODO

          s
        end
      end

      class Smoke < AbstractGenerator
        DEF_OPTIONS = {:hue => Hue.new(60)}

        def self.get_colors(options=nil)
          # TODO protecciones contra valores de colores disparatados

          #        if nil
          #            try:
          #                int(params['intensity'])
          #            except ValueError:
          #                params['intensity'] = 5
          #
          #            if params['intensity'] < 0:
          #                params['intensity'] =  0
          #            elif params['intensity'] > 10:
          #                params['intensity'] = 10
          #        end


          options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
          # TODO protecciones contra valores de colores disparatados

          h = options[:hue].value.to_f / 360.0 # degrees
          s = {}

          # DEFINITIVO

          # OLD

          # all formats are as follows: (hue, saturation, balance)
          s[:body_background_color]           = [h, 0.03, 0.39]
          s[:body_color]                      = [h, 0.04, 0.92]
          s[:cpagein_background_color] = s[:body_background_color]
          s[:ccontent_module_background_color] = [h, 0.06, 0.38]
          s[:content_title_color]            = [0.0, 0.0, 0.0]
          s[:cpageout_background_color]   = [h, 0.08, 0.41]
          s[:module_content_color]                   = s[:body_color]
          s[:ccontent_module_content_background_color]        = [h, 0.07, 0.45]
          s[:module_title_background_color]        = [h, 0.4, 0.38]
          s[:nav_titles_color]                = [h, 0.4, 0.38]
          s[:nav_color]                  = s[:body_color]
          s[:nav_background_color]            = s[:ccontent_module_content_background_color]
          s[:info_color]                      = s[:body_color]
          s[:info_background_color]           = s[:ccontent_module_content_background_color]

          s[:comments_background_color]       = [h, 0.07, 0.50]
          s[:comments_border_color]           = [h, 0.07, 0.30]

          s[:link_color]         = [h, 0.42, 0.98]
          s[:link_visited_color] = [h, 0.23, 0.79]
          s[:link_hover_color]   = [h, 0.75, 0.98]

          # TODO temp
          s[:a_nav_color] = [h, 0.08, 0.87]
          s[:nav_link_visited_color] = [h, 0.0, 0.87]
          s[:nav_link_hover_color] = [h, 0.08, 1.0]

          s[:info_link_visited_color] = s[:link_visited_color]
          s[:info_link_color] = s[:link_color]
          s[:info_link_hover_color] = s[:link_hover_color]

          # custom
          s[:box_borders_colors] = [h, 0.07, 0.60]

          s[:icons_actionable] = [h, 0.44, 0.85]
          s[:form_text_and_selects_background_color] = [h, 0.44, 0.85]
          s[:ads_text_color] = [h, 0.44, 0.85]
          s[:module_content_background_color] = [h, 0.44, 0.85]
          s[:comments_header_unread] = [h, 0.44, 0.85]
          s[:icons_non_actionable] = [h, 0.44, 0.85]
          s[:a_content_color] = [h, 0.44, 0.85]
          s[:a_ads_color] = [h, 0.44, 0.85]
          s[:module_content_color] = [h, 0.44, 0.85]
          s[:selected_row_background_color] = [h, 0.44, 0.85]
          s[:updated_since_last_visit] = [h, 0.44, 0.85]
          s[:a_action_color] = [h, 0.44, 0.85]
          s[:good_background_color] = [h, 0.44, 0.85]
          s[:container_background_color] = [h, 0.44, 0.85]
          s[:macro_quote_color] = [h, 0.44, 0.85]
          s[:progress_bars_background_color] = [h, 0.44, 0.85]
          s[:progress_bars_fill_background_color] = [0, 0.98, 0.18] # TODO confirm
          s[:progress_bars_border_color] = [0, 0.98, 0.18] # TODO confirm
          s[:a_content_visited_color] = [h, 0.44, 0.85]
          s[:bad_background_color] = [h, 0.44, 0.85]
          s[:karma] = [h, 0.44, 0.85]
          s[:macro_quote_background_color] = [h, 0.44, 0.85]
          s[:module_title_background_color] = [h, 0.44, 0.85]
          s[:good_color] = [h, 0.44, 0.85]
          s[:a_info_color] = [h, 0.44, 0.85]
          s[:form_text_and_selects_color] = [h, 0.0, 1.0]
          s[:ads_background_color] = [h, 0.44, 0.85]
          s[:module_title_color] = [h, 0.44, 0.85]
          s[:bad_color] = [h, 0.44, 0.85]
          s[:bad_border_color] = [h, 0.44, 0.85]
          s[:good_border_color] = [h, 0.44, 0.85]

          colors_generated = {}
          s.each { |k,v| colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v| sprintf("%02x", (v*255).to_i) }.join }
          colors_generated
        end
      end
    end

    class Soft < AbstractGenerator
      DEF_OPTIONS = {:hue => Hue.new(60)}


      def self.get_colors(options=nil)
        options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
        # TODO protecciones contra valores de colores disparatados

        h = options[:hue].value.to_f / 360.0 # degrees
        s = {}

        # DEFINITIVO
        s[:body_background_color] = [h, 0.40, 1.00]
        s[:body_color] = [h, 0.00, 0.27]
        s[:nav_background_color] = [h, 0.60, 0.60]
        s[:ccontent_module_content_background_color] = [h, 0.05, 1.00]
        s[:cpagein_background_color] = [h, 0.15, 1.00]
        s[:module_title_color] = [h, 0.0, 0.0]
        s[:module_content_background_color] = [h, 0.15, 1.00]
        s[:module_content_color] = s[:body_color]
        s[:container_background_color] = s[:cpagein_background_color] # s[:body_background_color] #[h, 0.44, 0.85] # TODO
        s[:module_title_background_color] = [h, 0.44, 0.85] # [h, 0.19, 0.92]

        s[:form_text_and_selects_background_color] = [h, 0.1, 1.0]
        s[:form_text_and_selects_color] = s[:body_color]

        # OLD
        s[:info_background_color] = [h, 0.20, 0.60]
        s[:nav_color] = s[:body_color]
        s[:a_nav_color] = [h, 0.85, 0.4]
        s[:nav_link_hover_color] = [h, 0.00, 1.00]
        s[:nav_link_visited_color] = s[:a_nav_color]

        s[:link_color] = [h, 1.00, 0.70]
        s[:link_hover_color] = [h, 0.40, 1.00]
        s[:link_visited_color] = [h, 0.40, 0.70]

        s[:comments_background_color]       = [h, 0.06, 0.95]
        s[:comments_border_color]           = [h, 0.06, 0.90]

        s[:module_content_color] = s[:body_color]
        s[:cpageout_background_color] = s[:ccontent_module_content_background_color]

        s[:info_color] = s[:body_color]
        s[:info_link_color] = s[:link_color]
        s[:info_link_hover_color] = s[:link_hover_color]
        s[:info_link_visited_color] = s[:link_visited_color]

        s[:box_borders_colors] = [h, 0.40, 1.00]

        # s[:module_title_background_color] = [h, 0.60, 0.60]

        # new
        s[:icons_actionable] = [h, 0.44, 0.85] # TODO

        s[:ads_text_color] = [h, 0.44, 0.85] # TODO

        s[:comments_header_unread] = [h, 0.44, 0.85] # TODO
        s[:icons_non_actionable] = [h, 0.44, 0.85] # TODO
        s[:a_content_color] = [h, 0.44, 0.85] # TODO
        s[:a_ads_color] = [h, 0.44, 0.85] # TODO

        s[:selected_row_background_color] = [h, 0.44, 0.85] # TODO
        s[:updated_since_last_visit] = [h, 0.44, 0.85] # TODO
        s[:a_action_color] = [h, 0.44, 0.85] # TODO
        s[:good_background_color] = [h, 0.44, 0.85] # TODO

        s[:macro_quote_color] = [h, 0.44, 0.85] # TODO
        s[:progress_bars_background_color] = [h, 0.44, 0.85] # TODO
        s[:progress_bars_fill_background_color] = [0, 0.98, 0.18] # TODO confirm
        s[:progress_bars_border_color] = [0, 0.98, 0.18] # TODO confirm
        s[:a_content_visited_color] = [h, 0.44, 0.85] # TODO
        s[:bad_background_color] = [h, 0.44, 0.85] # TODO
        s[:karma] = [h, 0.44, 0.85] # TODO
        s[:macro_quote_background_color] = [h, 0.44, 0.85] # TODO

        s[:good_color] = [h, 0.44, 0.85] # TODO
        s[:a_info_color] = [h, 0.44, 0.85] # TODO

        s[:ads_background_color] = [h, 0.44, 0.85] # TODO

        s[:bad_color] = [h, 0.44, 0.85] # TODO
        s[:bad_border_color] = [h, 0.44, 0.85] # TODO
        s[:good_border_color] = [h, 0.44, 0.85] # TODO


        colors_generated = {}
        s.each { |k,v|
          colors_generated[k] = Skins::ColorGenerators.hsv_to_rgb(*v).collect { |v| sprintf("%02x", (v*255).to_i) }.join }
        colors_generated
      end
    end

    class Custom < AbstractGenerator
      DEF_OPTIONS  = {
        :page_background_color => 'inherit',
        :page_background_image => 'inherit',
        :page_background_repeat => 'inherit',
        :page_background_position => 'inherit',

        :cpageout_background_color => 'inherit',
        :cpageout_background_image => 'inherit',
        :cpageout_background_repeat => 'inherit',
        :cpageout_background_position => 'inherit',

        :mgheader_background_color => 'inherit',
        :mgheader_background_image => 'inherit',
        :mgheader_background_repeat => 'inherit',
        :mgheader_background_position => 'inherit',

        :mgfooter_background_color => 'inherit',
        :mgfooter_background_image => 'inherit',
        :mgfooter_background_repeat => 'inherit',
        :mgfooter_background_position => 'inherit',
        :mgfooter_separator_color => 'inherit',
        :mgfooter_link_color => 'inherit',
        :mgfooter_link_hover_color => 'inherit',
        :mgfooter_new_color => 'inherit',
        :mgfooter_new_background_color => 'inherit',


      }

      def self.get_colors(options=nil)
        options = options.nil? ? DEF_OPTIONS : DEF_OPTIONS.merge(options)
        colors_generated = {}
        options.each do |k,v|
          v = RgbColor.new(v) unless v.kind_of?(RgbColor) || DEF_OPTIONS[k].class.name != 'RgbColor'
          colors_generated[k] = v.to_s
        end
        colors_generated
      end
    end
  end
end
