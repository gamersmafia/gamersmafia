# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    `bundle exec rake db:migrate`
    # After launching a new release custom skins' .css files disappear from
    # app/assets/stylesheets. This will recreate them.
    Skin.rebuild_all
    Skin.update_portal_favicons
    `bundle exec rake assets:precompile`
    `./script/delayed_job restart`
    Cms.uncompress_ckeditor_if_necessary
    CacheObserver.expire_fragment("/common/gmversion")
    # For some reason it's generating a new version on light but it should be
    # the same as in the repo. Temporarily disabling.
    # `gcc -o /tmp/embed script/embed_ttf/embed.c && /tmp/embed public/fonts/gm_icons.ttf`
    `touch #{Rails.root}/tmp/restart.txt`
    `./script/release.rb`
    publish_news(AppR.ondisk_git_version)
  end

  private
  def publish_news(version)
    title = "Gamersmafia actualizada a la versión #{version}"
    if News.published.find_by_title(title)
      Rails.logger.warn("Found news for #{version}. Skipping news creation..")
      return
    end

    last = News.published.find(
        :first,
        :conditions => "title LIKE E'Gamersmafia actualizada a la versión %'",
        :order => 'created_on DESC')
    if last.nil?
      start_rev = "HEAD~20"
    else
      start_rev = last.title.split(" ")[-1]
    end
    if /^[0-9]+$/ =~ start_rev
      start_rev = "release-#{start_rev[0..-3]}-#{start_rev[-2..-1]}"
    end

    interval = "#{start_rev}..#{AppR.ondisk_git_version_full}"
    html_log = Formatting.git_log_to_html(
        `git log --no-merges master --pretty=full #{interval}`)

    if html_log.strip == ''
      # Automatic detection of last changelog failed, we will default to the
      # last 2 releases.
      all_tags = `git tag | grep release`.strip.split("\n")
      do_email = true
      if all_tags.size < 2
        puts "Not enough tags to do diff. No email will be sent."
        do_email = false
      end

      diff_start_tag, diff_end_tag = all_tags.sort[-2..-1]
      interval = "#{diff_start_tag}..#{diff_end_tag}"
      html_log = Formatting.git_log_to_html(
          `git log --no-merges master --pretty=full #{interval}`)
    end

    n = News.create(
        :title => title,
        :description => html_log,
        :user_id => App.webmaster_user_id,
        :state => Cms::DRAFT)
    Term.single_toplevel(:slug => 'gmversion').link(n.unique_content)
    Term.single_toplevel(:slug => 'gm').link(n.unique_content)
    Term.single_toplevel(:name => 'actualizaciones.gm').link(n.unique_content)
  end
end
