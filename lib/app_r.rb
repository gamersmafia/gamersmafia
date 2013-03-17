# -*- encoding : utf-8 -*-
module AppR
  REVISION_FILE = "#{Rails.root}/config/REVISION"

  def self.ondisk_git_version_full
    all_tags = `git --git-dir=#{Rails.root}/.git --work-tree=#{Rails.root} tag | grep release`.strip.split("\n")
    if all_tags.size == 0
      last_tag = `git --git-dir=#{Rails.root}/.git --work-tree=#{Rails.root} log master --no-merges --pretty=format:"%h" | head -n 1`.strip
    else
      last_tag = all_tags.sort.last
    end

    GlobalVars.update_var("svn_revision", last_tag)
    last_tag
  end

  def self.ondisk_git_version
    @_cache_ondisk_git_version ||= begin
      self.ondisk_git_version_full.gsub(/[^0-9]/, "")
    end
  end

  def self.last_public_version_snippet
    @_cache_last_public_version_snippet ||= begin
      news = News.published.find(
          :first,
          :conditions => "title LIKE 'Gamersmafia actualizada a la versión%'",
          :order => 'created_on DESC')
      if news
        version = news.title.split(' ').last
        if /^[0-9]{10}$/ =~ version
          version = "#{version[0..8]}.#{version[8..-1]}"
        end
        "<a href=\"#{Routing.gmurl(news.unique_content)}\">#{version}</a>"
      else
        Appr.ondisk_git_version
      end
    end
  end
end
