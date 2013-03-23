# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    `rake db:migrate`
    `rake assets:precompile`
    `./script/delayed_job restart`
    Cms.uncompress_ckeditor_if_necessary
    CacheObserver.expire_fragment("/common/gmversion")
    # For some reason it's generating a new version on light but it should be
    # the same as in the repo. Temporarily disabling.
    # `gcc -o /tmp/embed script/embed_ttf/embed.c && /tmp/embed public/fonts/gm_icons.ttf`
    `touch #{Rails.root}/tmp/restart.txt`
    publish_news(AppR.ondisk_git_version_full, AppR.ondisk_git_version)
    `./script/release.rb`
  end

  private
  def publish_news(version_full, version)
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
