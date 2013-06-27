# -*- encoding : utf-8 -*-
class ImagenesController < BazarController
  acts_as_content_browser :image
  allowed_portals [:gm, :faction, :clan, :bazar, :bazar_district]

  def category
    @category = Term.find_taxonomy(params[:category].to_i, 'ImagesCategory')
    @category = Term.find(params[:category].to_i) if @category.nil?
    @title = @category.name
    if not @category.parent_id then
      @navpath = [
          ['Imágenes', '/imagenes'],
          [@category.name, "/imagenes/#{@category.id}"],
      ]
      render :action => 'toplevel'
    else
      @navpath = [
          ['Imágenes', '/imagenes'],
          [@category.parent.name, "/imagenes/#{@category.parent.id}"],
          [@category.name, "/imagenes/#{@category.id}"],
      ]
      render :action => 'gallery'
    end
  end

  def no_ads
    (@category && [1559, 1560].include?(@category.id))
  end

  def index
    @categories = portal.categories(Image)
    @navpath = [['Imágenes', '/imagenes'], ]
    @category = @categories[0]
    render :action => 'toplevel'
  end

  def toplevel
  end

  def potds
    @title = 'Imágenes del día'
  end

  def gallery
  end

  def _after_show
    if @image # podemos estar haciendo 301
      @category = @image.main_category
      if @image.main_category && @image.main_category.parent then
        @title = "#{@image.main_category.parent.name} &raquo; #{@image.main_category.name} &raquo; Imagen #{File.basename(@image.file) if @image.file}"
        @navpath = [['Imágenes', '/imagenes'], [@image.main_category.parent.name, "/imagenes/#{@image.main_category.parent.id}"], [@image.main_category.name, "/imagenes/#{@image.main_category.id}"], [@image.resolve_hid, gmurl(@image)]]
      elsif @image.main_category
        @title = "#{@image.main_category.name} &raquo; Imagen #{@image.file ? File.basename(@image.file) : ''}"
        @navpath = [['Imágenes', '/imagenes'], [@image.main_category.name, "/imagenes/#{@image.main_category.id}"], [@image.file ? File.basename(@image.file) : 'Imagen', gmurl(@image)]]
      end
    end
  end

  def _after_create
    # @image.reload
    if @image.file.nil? || @image.file == ''
      flash[:error] = "Error al crear la imagen"
      Content.delete_content(@image, Ias.MrMan, "Sin imagen")
    end
  end

  def create_from_zip
    require_auth_users
    raise ActiveRecord::RecordNotFound unless Authorization.can_bulk_upload?(@user)
    if params[:categories_terms].size == 0
      flash[:error] = "Debes elegir una categoría donde subir las imágenes."
      new
      render :action => 'new'
    else

      @category = Term.find_taxonomy(params[:categories_terms][0], 'ImagesCategory')

      if @category.parent_id.nil? then
        flash[:error] = 'Debes elegir una subcategoría, no una categoría'
        new
        render :action => 'new'
      elsif !params[:image][:file].respond_to?(:path)
        flash[:error] = 'Debes elegir un archivo zip que contenga imágenes'
        new
        render :action => 'new'
      else
        newfile = params[:image][:file]
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
          im = Image.new
          File.open("#{tmp_dir}/#{f}") do |ff|
            im.file = ff
            im.state = Cms::PENDING
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
        flash[:notice] = "#{i} imágenes subidas correctamente. Tendrán que ser moderadas antes de aparecer publicada."
        redirect_to '/imagenes'
      end
    end
  end
end
