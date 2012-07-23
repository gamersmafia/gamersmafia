# -*- encoding : utf-8 -*-
class Cuenta::Clanes::SponsorsController < ApplicationController
  before_filter :require_auth_users
  before_filter :require_auth_clan_leader

  def submenu
    'Clan'
  end

  def submenu_items
    clanes_menu_items
  end

  # TODO duplicado en general_controller.rb
  before_filter do |c|
    if c.user.last_clan_id then
      c.clan = Clan.find_by_id(c.user.last_clan_id)
      if c.clan.nil? or c.clan.deleted?
        c.user.last_clan_id = nil
        c.user.save
      end
    end
  end

  def index
    @title = 'Sponsors'
    @navpath = [['Mis clanes', '/cuenta/clanes'],
                ['Sponsors', '/cuenta/clanes/sponsors']]
    list
    render :action => 'list'
  end

  # TODO remove list and leave index
  def list
    @title = 'Sponsors'
    @navpath = [['Mis clanes', '/cuenta/clanes'],
                ['Sponsors', '/cuenta/clanes/sponsors']]
    @clans_sponsors = ClansSponsor.paginate(
      :conditions => ['clan_id = ?', @clan.id],
      :page => params[:page],
      :per_page => 10)
  end

  def new
    @title = 'Nuevo sponsor'
    @navpath = [['Mis clanes', '/cuenta/clanes'],
                ['Sponsors', '/cuenta/clanes/sponsors'],
                ['Nuevo', '/cuenta/clanes/sponsors/new']]
    @clans_sponsor = ClansSponsor.new
  end

  def create
    params[:clans_sponsor][:clan_id] = @clan.id

    @clans_sponsor = ClansSponsor.new(params[:clans_sponsor])
    if @clans_sponsor.save
      flash[:notice] = 'Sponsor creado correctamente.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @clans_sponsor = (
      ClansSponsor.find_or_404(:first,
                               :conditions => ['id = ? and clan_id = ?',
                                                params[:id],
                                                @clan.id]))
    @title = 'Nuevo sponsor'
    @navpath = [['Mis clanes', '/cuenta/clanes'],
                ['Sponsors', '/cuenta/clanes/sponsors'],
                ['Nuevo', "/cuenta/clanes/sponsors/edit/#{@clans_sponsor.id}"]]
  end

  def update
    @clans_sponsor = (
      ClansSponsor.find_or_404(:first,
                               :conditions => ['id = ? and clan_id = ?',
                                                params[:id],
                                                @clan.id]))
    if @clans_sponsor.update_attributes(params[:clans_sponsor])
      flash[:notice] = 'Sponsor actualizado correctamente.'
      redirect_to :action => 'edit', :id => @clans_sponsor
    else
      render :action => 'edit'
    end
  end

  def destroy
    ClansSponsor.find_or_404(:first,
                             :conditions => ['id = ? and clan_id = ?',
                                              params[:id],
                                              @clan.id]).destroy
    flash[:notice] = 'Sponsor borrado correctamente.'
    redirect_to :action => 'list'
  end
end
