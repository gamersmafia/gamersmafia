# -*- encoding : utf-8 -*-
require 'net/smtp'

module Watchdog

  def self.run_hourly_checks
    alerts = []
    alerts.concat([self.check_comments_created])
    alerts.concat([self.check_load])
    alerts.concat([self.check_pageviews])
    if alerts.size > 0
      NotificationEmail.watchdog_alerts(
          "alerts@gamersmafia.com", :alerts => alerts).deliver
    end
  end

  def self.check_pageviews
    if User.db_query(
        "SELECT COUNT(*)
           FROM stats.pageloadtime
          WHERE created_on >= NOW() - '10 minutes'::interval")[0] == 0
      "No ha habido ninguna página vista en los últimos 10 minutos."
    end
  end

  def self.check_comments_created
    hour = Time.now.hour
    if [1..8].include?(hour)
      hours_back = 3
    else
      hours_back = 1
    end
    if Comment.count(
          :conditions => [
              "created_on >= NOW() - '#{hours_back} hours'::interval"]) == 0
      plural = hours_back > 1 ? "s" : ""
      "No se han creado comentarios desde hace #{hours_back} hora#{plural}."
    end
  end

  def self.check_load
    load_values = self.retrieve_top_output
    # [last 1 min, last 5 min, last 10 mins]
    if load_values[0] > 10 || load_values[0] > 7 || load_values[0] > 5
      "Carga del servidor muy elevada: #{load_values}"
    end
  end

  def self.retrieve_top_output
    a = `top -n1`
    idx_load_avg = /load average: [0-9.]/ =~ a
    if idx_load_avg.nil?
      raise "Unable to retrieve load average information from top."
    end

    # We retrieve the sequence of load times from the first line of top. Eg:
    # "load average: 0.02, 0.07, 0.0"
    load_values = (a[idx_load_avg + 13..82]).gsub(",", "").split(" ")
    load_values.collect{|x| x.to_f}
  end

end
