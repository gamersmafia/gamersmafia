# -*- encoding : utf-8 -*-
module Popularity
  def self.update_rankings
    update_ranking_users
    update_ranking_clans
  end

  def self.update_ranking_users
    lista = {}

    # We look at 3 weeks because karma is generated with 2 weeks difference.
    User.db_query(
      "SELECT id,
              coalesce(
                (SELECT sum(popularity)
                   FROM stats.users_daily_stats
                  WHERE created_on >= now() - '3 weeks'::interval
                    AND user_id = users.id), 0) as popularity
         FROM users
        WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')})").each do |dbr|
      lista[dbr['popularity'].to_i] ||= []
      lista[dbr['popularity'].to_i] << dbr['id'].to_i
    end

    pos = 1
    real_pos = 1
    lista.keys.sort.reverse.each do |k|
      # en caso de empate los ids menores (mas antiguos) tienen preferencia
      lista[k].sort.each do |uid|
        User.db_query(
            "UPDATE users
             SET cache_popularity = #{k},
                 ranking_popularity_pos = #{pos}
           WHERE id = #{uid}")
        real_pos += 1
      end
      pos = real_pos
    end
  end

  def self.update_ranking_clans
    lista = {}
    User.db_query("SELECT id,
                          coalesce((select sum(popularity)
                                      from stats.clans_daily_stats
                                     where created_on >= now() - '3 week'::interval
                                       AND clan_id = clans.id), 0) as popularity
                     FROM clans
                    WHERE deleted='f'").each do |dbr|
      lista[dbr['popularity'].to_i] ||= []
      lista[dbr['popularity'].to_i] << dbr['id'].to_i
    end

    pos = 1
    real_pos = 1
    lista.keys.sort.reverse.each do |k|
      # en caso de empate los ids menores (mas antiguos) tienen preferencia
      lista[k].sort.each do |uid|
        User.db_query("UPDATE clans SET cache_popularity = #{k}, ranking_popularity_pos = #{pos} WHERE id = #{uid}")
        real_pos += 1
      end
      pos = real_pos
    end
  end

  def self.user_daily_popularity(u, date_start, date_end)
    res = {}
    User.db_query("SELECT popularity,
                        created_on
                   FROM stats.users_daily_stats
                  WHERE user_id = #{u.id}
                    AND created_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                 ORDER BY created_on").each do |dbr|
      res[dbr['created_on'][0..10]] = dbr['popularity'].to_i
    end
    curdate = date_start
    curstr = curdate.strftime('%Y-%m-%d')
    endd = date_end.strftime('%Y-%m-%d')

    while curstr <= endd
      res[curstr] ||= 0
      curdate = curdate.advance(:days => 1)
      curstr = curdate.strftime('%Y-%m-%d')
    end
    res
  end

  def self.ranking_user(u)
    # contamos incluso los que tienen 0
    ucount = User.db_query("SELECT count(*) FROM users WHERE state IN (#{User::STATES_CAN_LOGIN.join(',')})")[0]['count'].to_i
    pos = u.ranking_popularity_pos ? u.ranking_popularity_pos : ucount
    {:pos => pos, :total => ucount }
  end
end
