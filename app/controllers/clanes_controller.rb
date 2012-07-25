# -*- encoding : utf-8 -*-
class ClanesController < ComunidadController
  allowed_portals [:gm, :faction]

  before_filter :except => [ :index, :buscar, :clan_selector_list ] do |c|
    c.curclan = Clan.find(:first,
                          :conditions => ['id = ? and deleted is false',
                                          c.params[:id].to_i])
    raise ActiveRecord::RecordNotFound unless c.curclan
  end

  attr_accessor :curclan

  def submenu
    'Clan' if curclan
  end

  def submenu_items
    l =  []

    if curclan then
      l<< ['General', "/clanes/clan/#{@clan.id}"]
      l<< ['Competición', "/clanes/clan/#{@clan.id}/competicion"]
    end

    l
  end

  def index
  end

  def clan
    @title = curclan.name
    @clan = curclan
  end

  def competicion
    @clan = curclan
  end

  def buscar
    if (not params) or (not params[:s]) or (params[:s].to_s == '') then
      redirect_to '/clanes'
    else
      @title = 'Resultados de la búsqueda'
      @clans = Clan.paginate(:page => params[:page], :per_page => 50,
      :conditions => ['deleted = \'f\' AND (lower(name) like lower(?) or lower(tag) like lower(?))',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%',
        '%' + params[:s].gsub(/[']/) { '\\'+$& } + '%'],
      :order => 'lower(name) ASC')
    end
  end

  def clan_selector_list
    headers['content-type'] = 'text/javascript'
    render :layout => false
  end
end
