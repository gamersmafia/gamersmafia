# -*- encoding : utf-8 -*-
class Cuenta::ApuestasController < ApplicationController

  def index
    require_auth_users
    @navpath = [['Preferencias', '/cuenta'],
                ['Mis apuestas', '/cuenta/apuestas']]
    @title = 'Mis apuestas'
  end
end
