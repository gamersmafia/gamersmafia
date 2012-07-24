# -*- encoding : utf-8 -*-
class Cuenta::Clanes::GeneralController < ApplicationController
  def submenu
    'Clan'
  end

  def submenu_items
    clanes_menu_items
  end

  before_filter :require_auth_users

  before_filter do |c|
    if c.user.last_clan_id then
      c.clan = Clan.find_by_id(c.user.last_clan_id)
      if c.clan.nil? or c.clan.deleted?
        c.user.update_attributes(:last_clan_id => nil)
      end
    end
  end

  def index
  end

  def menu

  end

  def new
    @user.last_clan_id = nil
    @title = 'Nuevo clan'
    @navpath = [['Mis clanes', '/cuenta/clanes'],
                ['Nuevo', '/cuenta/clanes/new']]
    @newclan = Clan.new
  end

  def create
    # TODO validación
    @newclan = Clan.new(params[:newclan].merge({:creator_user_id => @user.id}))
    if @newclan.save then
      @newclan.add_user_to_group(@user, 'clanleaders')
      @user.update_attributes(:last_clan_id => @newclan.id)
      flash[:notice] = 'Clan creado correctamente.'
      redirect_to :action => 'index'
    else
      flash[:error] = "Error al crear el clan:"+
                      " #{@newclan.errors.full_messages_html}"
      render :action => 'new'
    end
  end

  def borrar
    @clan = Clan.find(params[:clan_id])
    require_auth_clan_leader
    raise AccessDenied unless clan.admins.size == 1
    clan.mark_as_deleted
    flash[:notice] = "Clan eliminado correctamente"
    redirect_to '/cuenta/clanes'
  end

  def abandonar
    @clan = Clan.find(params[:clan_id])
    require_auth_member
    if @clan.all_users_of_this_clan.size == 1
      flash[:error] = "Eres el último miembro del clan."+
                      " Si quieres abandonarlo tendrás que borrarlo."
    else
      clan.member_leave(@user)
      flash[:notice] = "Has abandonado el clan \"#{clan.id}\"."
    end
    redirect_to '/cuenta/clanes'
  end

  def update
    require_auth_clan_leader
    params[:clan][:irc_channel] = (
      params[:clan][:irc_channel].gsub('#', '').strip if (
                                                params[:clan][:irc_channel]))
    if @clan.update_attributes(params[:clan]) then
      flash[:notice] = 'Cambios guardados correctamente.'
      redirect_to '/cuenta/clanes/configuracion'
    else
      flash[:error] = "Error al guardar los datos:"+
                       " #{@clan.errors.full_messages_html}"
      render :action => 'configuracion'
    end
  end

  def add_member_to_group
    require_auth_clan_leader
    u = User.find_by_login(params[:login])
    if u
      g = @clan.clans_groups.find(params[:clans_group_id])
      g.users<< u unless g.users.find_by_id(u.id)
      ClansMovement.create(:clan_id => @clan.id,
                           :user_id => u.id,
                           :direction => ClansMovement::IN)
      @clan.recalculate_members_count
      flash[:notice] = "Usuario añadido al grupo \"#{g.name}\" correctamente"
    else
      flash[:error] = 'El usuario especificado no existe.'
    end

    redirect_to '/cuenta/clanes/miembros'
  end


  def remove_member_from_group
    require_auth_clan_leader
    begin
      u = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = 'El usuario especificado no existe.'
    else
      @clan.clans_groups.find(params[:clans_group_id]).users.delete(u)
      ClansMovement.create(:clan_id => @clan.id,
                           :user_id => u.id,
                           :direction => ClansMovement::OUT)
      @clan.recalculate_members_count
    end

    redirect_to '/cuenta/clanes/miembros'
  end


  def configuracion
    require_auth_clan_leader
  end

  def miembros
    require_auth_clan_leader
  end

  def amigos
    require_auth_clan_leader
  end

  def add_friend
    require_auth_clan_leader

    begin
      if params[:id] then
        c = Clan.find(params[:id])
      else
        c = Clan.find_by_name(params[:name])
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = 'Clan no encontrado.'
    else
      @clan.add_friend(c)
      flash[:notice] = 'Amistad establecida correctamente.'
    end

    redirect_to '/cuenta/clanes/amigos'
  end

  def del_friends
    require_auth_clan_leader

    if params[:clans] then
      params[:clans].each do |c|
        flash[:notice] = ''
        begin
          clan = Clan.find(c)
        rescue ActiveRecord::RecordNotFound
          flash[:error] = "Clan #{c} no encontrado."
        else
          @clan.del_friend(clan)
          flash[:notice]<< "Amistad con clan <strong>#{clan.tag}</strong>"+
                           " eliminada<br />"
        end
      end
    end

    flash[:notice] = nil if flash[:notice] == ''
    redirect_to '/cuenta/clanes/amigos'
  end

  def banco
    require_auth_clan_leader
  end

  def switch_active_clan
    @user.update_attributes(:last_clan_id => params[:id])
    redirect_to '/cuenta/clanes'
  end
end
