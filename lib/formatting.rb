# -*- encoding : utf-8 -*-
require 'rinku'

module Formatting
  SIMPLE_URL_REGEXP = /[a-zA-Z0-9_.:?#&%-\/]+/

  def self.format_bbcode(text)
    text = text
      .gsub(/</, '&lt;')
      .gsub(/>/, '&gt;')
    text = self.fix_incorrect_bbcode_nesting(text)
    text = self.replace_newlines_with_paragraphs(text)
    text = self.replace_bbcodes(text)
    text = self.add_smileys(text)
    text = Rinku.auto_link(text) do |text|
      text.gsub(/http(s*):\/\//, '').truncate(50, :omission => "..")
    end
  end

  def self.replace_bbcodes(text)
    interword_regexp = /[^><]+/
    interword_regexp_strict = /[^\[]+/

    text = text
      .gsub("\r\n", "GM_NEWLINE_MARKER")
      .gsub("\r", "GM_NEWLINE_MARKER")
      .gsub("\n", "GM_NEWLINE_MARKER")

    # collect all quotes references
    full_quotes = {}
    text.scan(/\[fullquote=([0-9]+)\](.+?)\[\/fullquote\]/i).each do |m|
      full_quotes[m[0]] = Formatting.replace_bbcodes(m[1])
    end

    str = text.strip
      .gsub(/\[fullquote=([0-9]+)\].+?\[\/fullquote\]/i,
            '<abbr class="fullquote-opener" title="Ver comentario original" data-quote="\\1">#\\1</abbr>')
      .gsub(/(\[(\/*)(b|i)\])/i, '<\\2\\3>')
      .gsub(/(\[~(#{User::OLD_LOGIN_REGEXP_NOT_FULL})\])/, '<a href="/miembros/\\2">\\2</a>')
      .gsub(Regexp.new("\s@#{User::LOGIN_REGEXP}"), '&nbsp;<span class="user-login"><a href="/miembros/\\1">\\1</a></span>')
      .gsub(/\[flag=([a-z]+)\]/i, '<img class="icon" src="/images/flags/\\1.gif" />')
      .gsub(/\[img\](#{SIMPLE_URL_REGEXP})\[\/img\]/i, '<img src="\\1" />')
      .gsub(/\[url=(#{SIMPLE_URL_REGEXP})\](#{interword_regexp_strict})\[\/url\]/i, '<a href="\\1">\\2</a>')
      .gsub(/\[color=([a-zA-Z]+)\](#{interword_regexp})\[\/color\]/i, '<span class="c_\\1">\\2</span>')
      .gsub(/\[code=([a-zA-Z0-9]+)\](.+?)\[\/code\]/i, '<pre data-lllanguage="\\1">\\2</pre>')
      .gsub(/\[code\](.+?)\[\/code\]/i, '<pre>\\1</pre>')
      .gsub(/\[spoiler\](.+?)\[\/spoiler\]/i,
            '<span class="spoiler">spoiler <span class="spoiler-content hidden">\\1</span></span>')
      .gsub(/\[quote\](.+?)\[\/quote\]/i, "<blockquote><p>\\1</p></blockquote>")
      .gsub(/\[quote=([0-9]+)\](.+?)\[\/quote\]/i,
            '<abbr title="Ver comentario original">\\1</abbr><blockquote><p>\\2</p></blockquote>')

    full_quotes.each do |k, v|
      str = "#{str}\n<div class=\"hidden fullquote-comment fullquote-comment#{k}\"><p>#{v}</p></div>"
    end

    # remove any html tag inside a <code></code>
    str.gsub!(/<pre class="brush: [a-z]+">.*<\/pre>/) { |blck|
      code_part = blck.scan(/<pre class="brush: [a-z]+">(.*)<\/pre>/)[0][0].to_s
      code_part = code_part.
        gsub("<", "&lt;").
        gsub(">", "&gt;").
        gsub("&lt;br /&gt;", "\n")
      brush_part = blck.scan(/<pre class="brush: ([a-z]+)">.*<\/pre>/)[0][0]
      "<pre class=\"brush: #{brush_part}\">#{code_part}<\/pre>"
    }
    str.gsub!("GM_NEWLINE_MARKER", "\n")

    str
  end

  def self.replace_newlines_with_paragraphs(text)
    text = "<p>#{text}</p>"
    text = text
      .gsub("\r\n", "\n")
      .gsub("\r", "\n")

    text = self.transform_except_in_code(text) do |part|
      part.gsub("GM_NEWLINE_MARKER", "</p>GM_NEWLINE_MARKER<p>")
    end
    text.gsub("<p></p>", "")
  end

  # Runs block outside of [code][/code] pairs. The function expects a fully
  # balanced bbquote input text.
  def self.transform_except_in_code(text, &block)
    text.gsub!("\n", "GM_NEWLINE_MARKER")
    final_text_parts = []
    text.partition(/\[code[=a-z]*+\].+?\[\/code\]/).each do |part|
      if !(/\[code[=a-z]*\]/ =~ part)
        part = block.call(part)
      end
      final_text_parts.append(part)
    end

    final_text_parts
      .join("")
      .gsub("GM_NEWLINE_MARKER", "\n")
  end

  # Replaces smileys codes with html images
  def self.add_smileys(text)
    text = self.transform_except_in_code(text) do |part|
      part
        .gsub(/([\s>]{1}|^)[oO]{1}:(\))+/, '\1<img src="/images/smileys/angel.gif" />')  # o:)
        .gsub(/([\s>]{1}|^)(:['_*´]+(\()+)/, '\1<img src="/images/smileys/cry.gif" />')  # // :'( | :*( | :_( | :´(
        .gsub(/([\s>]{1}|^):([a-z0-9]+):/, '\1<img src="/images/smileys/\2.gif" />')
        .gsub(/([\s>]{1}|^)(:(o)+)/i, '\1<img src="/images/smileys/eek.gif" />')  #// :o | :O
        .gsub(/([\s>]{1}|^)(r_r)/i, '\1<img src="/images/smileys/roll.gif" />')
        .gsub(/([\s>]{1}|^)(x_x)/i, '\1<img src="/images/smileys/ko.gif" />')
        .gsub(/([\s>]{1}|^)(z_z)/i, '\1<img src="/images/smileys/zz.gif" />')
        .gsub(/([\s>]{1}|^)(o(_)+(o)+)/i, '\1<img src="/images/smileys/eek.gif" />')  #// o_O
        .gsub(/([\s>]{1}|^)(:(p)+)/i, '\1<img src="/images/smileys/tongue.gif" />\\4')  #// :p | :P
        .gsub(/([\s>]{1}|^)(x(d)+)/i, '\1<img src="/images/smileys/grin.gif" />')  #// xd
        .gsub(/([\s>]{1}|^)(:(0)+)/, '\1<img src="/images/smileys/eek.gif" />')  #// :0
        .gsub(/([\s>]{1}|^)(8\)+)/, '\1<img src="/images/smileys/cool.gif" />')  #// 8)
        .gsub(/([\s>]{1}|^)(:\?+)/, '\1<img src="/images/smileys/huh.gif" />')  #// :?
        .gsub(/([\s>]{1}|^)(:x+)/i, '\1<img src="/images/smileys/lipsrsealed.gif" />')  #// :x
        .gsub(/([\s>]{1}|^)(:(\|)+)/, '\1<img src="/images/smileys/indifferent.gif" />')  #// :|
        .gsub(/([\s>]{1}|^)(\^(_)*(\^)+)/, '\1<img src="/images/smileys/happy.gif" />')  #// ^^ | ^_^
        .gsub(/([\s>]{1}|^)(;([\)D])+)/, '\1<img src="/images/smileys/wink.gif" />')  #// )
        .gsub(/([\s>]{1}|^)(:(\*)+)/, '\1<img src="/images/smileys/morreo.gif" />')  #// :*
        .gsub(/([\s>]{1}|^)(:(\@)+)/, '\1<img src="/images/smileys/morreo.gif" />')  #// :@
        .gsub(/([\s>]{1}|^)(:(\\)+)/, '\1<img src="/images/smileys/undecided.gif" />')  #// :)
        .gsub(/([\s>]{1}|^)(:(\))+)/, '\1<img src="/images/smileys/smile.gif" />')  #// :)
        .gsub(/([\s>]{1}|^)(x(\))+)/i, '\1<img src="/images/smileys/happy.gif" />')  # // x)
        .gsub(/([\s>]{1}|^)(:(D)+)/i, '\1<img src="/images/smileys/happy.gif" />')  ##// :D
        .gsub(/([\s>]{1}|^)(:(\()+)/, '\1<img src="/images/smileys/sad.gif" />')  #// :(
        .gsub(/([\s>]{1}|^)=(\))+/, '\1<img src="/images/smileys/smile.gif" />')  #// =)
    end
  end

  def self.fix_incorrect_bbcode_nesting(input)
    q = []
    regexp = /(\[\/*(b|i|span|code=[^\]]*|code|spoiler|quote|img|url=[^\]]*|url)\])/i
    next_idx = input.index(regexp)

    while next_idx
      m = regexp.match(input[next_idx..-1])
      bbcode = m[2][0..(m[2].index(/=|$/)-1)]      # get 'b' or 'quote'
      insertion = ''

      if m[0][1..1] != '/'
        q << bbcode
      else
        if bbcode.gsub('/', '') == q.last
          q.pop
        else
          insertion = "[#{bbcode}]"
          input = "#{input[0..next_idx-1]}#{insertion}#{input[next_idx..-1]}"
        end
      end

      next_idx += m[0].size + insertion.size
      next_idx = input.index(regexp, next_idx)
    end

    q.each do |bbcode|
      input = "#{input}[/#{bbcode}]"
    end
    input.gsub(
        /(\[(b|i|code|spoiler|quote)\]\[\/(b|i|spoiler|code|quote)\])/i, '')
  end

  # Removes [quote] bbcode pairs from text and all that they contain
  def self.remove_quotes(text)
    text = text.
      gsub("\r\n", "GM_NEWLINE_MARKER").
      gsub("\n", "GM_NEWLINE_MARKER").
      gsub("\r", "GM_NEWLINE_MARKER").
      gsub(/(\[(full)*quote[=0-9]*\].+?\[\/(full)*quote\])/, "(quote)").
      gsub("GM_NEWLINE_MARKER", "\n")
  end

  # Returns a string with [quote][/quote] pairs but with no text within the
  # quotes.
  def self.comment_without_quoted_text(text)
    text.
      gsub("\r\n", "GM_NEWLINE_MARKER").
      gsub("\n", "GM_NEWLINE_MARKER").
      gsub("\r", "GM_NEWLINE_MARKER").
      gsub(/(\[quote[=0-9]*\])([^\[]+)(\[\/quote\])/, "\\1\\3").
      gsub("GM_NEWLINE_MARKER", "\n")
  end

  def self.comment_with_expanded_short_replies(comment_text, comment)
    # we build a new string with quotes replaced by placeholders
    new_str = comment_text.
      gsub("\r\n", "GM_NEWLINE_MARKER").
      gsub("\n", "GM_NEWLINE_MARKER").
      gsub("\r", "GM_NEWLINE_MARKER")
    quotes = {}
    quote_id = 0
    comment_text.scan(/(\[quote[=0-9]*\][^\[]+\[\/quote\])/).each do |q|
      quote_id += 1
      key = "GM_START_QUOTE_MARKER#{quote_id}GM_END_QUOTE_MARKER"
      new_str.sub(q[0], key)
      quotes[key] = q[0]
    end

    new_str = new_str.gsub(/#([0-9]+)/) do |m|
      replied_comment = Comment.karma_eligible.find_by_position($1.to_i, comment.content)
      if replied_comment.nil? || replied_comment.id == comment.id
        m
      else
        "[fullquote=#{$1}][b]##{$1} [~#{replied_comment.user.login}][/b]:\n\n#{Formatting.remove_quotes(replied_comment.comment)}[/fullquote]#{$2}"
      end
    end

    # We restore removed quotes
    quotes.each do |k, v|
      new_str.sub(k, v)
    end
    new_str.gsub("GM_NEWLINE_MARKER", "\n")
  end

  def self.html_to_bbcode(str)
    return str if str.to_s == ""

    str.clone.strip
      .gsub('<br />', "\n")
      .gsub('<[/]*p>', "")
      .gsub(/(<(\/*)(blockquote)>)/i, '<\\2quote>')
      .gsub(/<pre class="brush: ([^"]+)">/i, '[code=\\1]')
      .gsub(/(<(\/*)(pre)>)/i, '[\\2code]') # TODO we don't preserve the class!
      .gsub(/(<(\/*)(b|i|code|quote)>)/i, '[\\2\\3]')
      .gsub(/<img class="icon" src="\/images\/flags\/([a-z]+).gif" \/>/i, '[flag=\\1]')
      .gsub(/<img src="([^"]+)" \/>/i, '[img]\\1[/img]')
      .gsub(/<span class="spoiler">spoiler <span class="spoiler-content hidden">([^<]+)<\/span><\/span>/, "[spoiler]\\1[/spoiler]")
      .gsub(/<span class="user-login"><a href="\/miembros\/([^"]+)">([^<]+)<\/a><\/span>/, "@\\1")
      .gsub(/<a href="\/miembros\/([^"]+)">([^<]+)<\/a>/i, '[~\\1]')
      .gsub('url=www', 'url=http://www')
      .gsub(/<a href="([^"]+)">([^<]+)<\/a>/i, '[url=\\1]\\2[/url]')
      .gsub('<p>', '')
      .gsub('</p>', '')
      .gsub('&lt;', '<')
      .gsub('&gt;', '>')
  end

  def self.git_log_to_html(git_log)
    out = []
    git_log.gsub(/^commit /, "COMMIT_STARTcommit").split("COMMIT_STARTcommit").each do |commit|
      next if commit.empty?
      commit_lines = commit.split("\n")
      commit_id = commit_lines[0]
      author = commit_lines[1].split(" ")[1]
      title = commit_lines[4].strip
      description = commit_lines[5..-1].join("\n")
      out << "<strong>#{title}</strong><br />"
      out << "<span class=\"f_milli\">por <a href=\"/miembros/#{author}\">#{author}</a> | <a href=\"http://github.com/gamersmafia/gamersmafia/commits/#{commit_id}\">commit</a></span>"
      if description.strip.empty?
        out << "<br /><br /><br />"
      else
        description = "<p>#{description.gsub(/^[ ]+/, "").strip.gsub("\n\n", "</p>\n<p>")}</p>".gsub("<p></p>", "")
        description.gsub!(/#([0-9]+)/, "<a href=\"https://github.com/gamersmafia/gamersmafia/issues/\\1\">\\1</a>")
        description.gsub!("fixes ", "corrige ")
        description.gsub!("closes ", "cierra ")
        out << description
        out << "<br />"
      end
    end
    out.join("\n")
  end
end
