# -*- encoding : utf-8 -*-
class HqController < ApplicationController
  before_filter do |c|
    raise AccessDenied unless c.user && c.user.has_skill_cached?("Capo")
  end

  def bans_requests
    @title = "Histórico de peticiones de bans/unbans"
  end

  def antifloods
    @title = "Antifloods activos"
  end

  def alerts_archive
    @title = "Histórico de sucesos"
  end
end
