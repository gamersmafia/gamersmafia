# -*- encoding : utf-8 -*-
class DescargasController < InformacionController
  acts_as_content_browser :download
  allowed_portals [:gm, :faction, :clan, :bazar_district]

  def index
    @title = 'Descargas'
    if params[:category].nil? && portal.id > 0
      params[:category] = Term.portal_root_term(portal).first
    end
    parent_id = params[:category]
    if parent_id then
      # TODO BUG no estamos chequeando que la categoría se pueda ver desde aquí
      @category = Term.find_taxonomy(parent_id, 'DownloadsCategory')
      @category = Term.find(parent_id) if @category.nil?
      paths, @navpath = get_category_address(@category, 'DownloadsCategory')
      @title = paths.join(' &raquo; ')
    end
  end

  def _after_show
    if @download
      paths, navpath = get_category_address(
          @download.main_category, 'DownloadsCategory')
      if navpath.nil?
        Rails.logger.warn("No navpath found for #{@download}")
        @navpath = []
      else
        @navpath = navpath + [
            [@download.title,
             "/descargas/#{@download.main_category.id}/#{@download.id}"]
        ]
      end
      @title = @download.title
    end
  end

  def download
    @download = Download.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @download.is_public?

    @title = @download.title
    @download_mirrors = @download.download_mirrors
    Download.increment_counter('downloaded_times', @download.id)
    dd = @download.downloaded_downloads.create({
        :ip => self.remote_ip,
        :referer => request.env['HTTP_REFERER'].to_s,
        :session_id => session[:session_id],
        :user_id => (user_is_authed ? @user.id : nil),
    })
    if @download.main_category
      CacheObserver.expire_fragment("/common/descargas/index/downloads_#{@download.main_category.id}/page_*") # TODO MUY HEAVY, no podemos hacer que cada descarga suponga borrar todas las caches de índices
      CacheObserver.expire_fragment("/common/descargas/index/most_downloaded_#{@download.main_category.root_id}")
    else
      Rails.logger.warn("Download #{@download} has no category!")
    end
    if params[:r]
        #if Cms::URL_REGEXP_FULL =~ params[:r] #DownloadMirror.find_by_url(URI::unescape(params[:r]))
          @download_link = params[:r]
        #lse
        # flash[:error] = "URL de descarga inválida"
        # redirect_to "/descargas/show/#{@download.id}"
        #nd
    else
      # CacheObserver.expire_fragment("/common/descargas/most_downloaded_#{@download.main_category.root_id}")
	gm_link = @download.created_on > 1.day.ago ? 0 : 1
# TODO temp
#gm_link = nil
      final_mirror = Download.create_symlink(dd.download_cookie, @download.file, gm_link)  # 1 = NLS
      final_mirror = 0 if final_mirror.nil?
      end_file = @download.file.gsub("#{Rails.root}/public/storage", '')
      @download_link = "#{Download::MIRRORS_DOWNLOAD[final_mirror]}d/#{dd.download_cookie}/#{File.basename(end_file)}"
    end
    render :layout => 'blank'
  end

  def dauth
    raise ActiveRecord::RecordNotFound unless params[:gmk] && params[:ddc] && params[:f]
    raise AccessDenied unless params[:gmk] == App.mirror_auth_key
    Download.create_symlink(params[:ddc], params[:f])
    render :nothing => true
  end

  def create_from_zip
    require_auth_users
    raise ActiveRecord::RecordNotFound unless Authorization.can_bulk_upload?(@user)
    if params[:categories_terms].nil? || params[:categories_terms].size == 0
      flash[:error] = "Debes elegir una categoría donde subir las descargas."
      new
      render :action => 'new'
    else

      @category = Term.find_taxonomy(params[:categories_terms][0], 'DownloadsCategory')

      if @category.nil? || @category.parent_id.nil? then
        flash[:error] = 'Debes elegir una subcategoría, no una categoría'
        new
        render :action => 'new'
      elsif !params[:download][:file].respond_to?(:path)
        flash[:error] = 'Debes elegir un archivo zip que contenga descargas'
        new
        render :action => 'new'
      else
        newfile = params[:download][:file]
        tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
        # descomprimimos
        if not newfile.path then # TODO comprobar que StringIO tiene path y no se mete en el elsif anterior
          File.open("#{tmp_dir}.zip", 'w+') { |f| f.write(newfile.read()) }
          path = "#{tmp_dir}.zip"
        else
          path = newfile.path
        end

        system("unzip -q -j #{path} -d #{tmp_dir}")
        # añadimos imgs al dir del usuario
        i = 0
        for f in (Dir.entries(tmp_dir) - %w(.. .))
          im = Download.new
          File.open("#{tmp_dir}/#{f}") do |ff|
            im.file = ff
            im.state = Cms::PENDING
	    im.title = f.gsub('(\.+)$', '')
            im.description = ''
            im.user_id = @user.id
            if im.save
              @category.link(im.unique_content)
              i += 1
            end
          end
        end

        # limpiamos
        system("rm -r #{tmp_dir}")
        flash[:notice] = "#{i} descargas subidas correctamente. Tendrán que ser moderadas antes de aparecer publicada."
        redirect_to '/descargas'
      end
    end
  end

  def edit
    @download = Download.find(params[:id])
    # require_user_can_edit(@download)
    raise ContentLocked if @download.is_locked_for_user?(@user)
    @title = "Editar #{@download.title}"
    # paths, navpath = get_category_address(@download.main_category, 'DownloadsCategory')
    @navpath = []
    @navpath << [@download.title, "/descargas/#{@download.main_category.id}/#{@download.id}"] if @download.main_category
    @navpath << ['Editar', "/descargas/edit/#{@download.id}"]
    if Authorization.can_edit_content?(@user, @download) then
      @download.lock(@user)
      render :action => 'edit'
    else
      render :action => 'show'
    end
  end
end
