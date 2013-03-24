# -*- encoding : utf-8 -*-
class Bet < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  TIE = 0
  TOP_BET_WINNERS = (
      "#{Rails.root}/public/storage/apuestas/top_bets_winners_minicolumns_data")

  INCOMPLETE_BET_SQL = "winning_bets_option_id IS NULL
                        AND tie is false
                        AND cancelled is false
                        AND forfeit is false"

  OPEN_BETS_SQL = "#{INCOMPLETE_BET_SQL} AND closes_on > now()"
  AWAITING_RESULT_SQL = "#{INCOMPLETE_BET_SQL} AND closes_on <= now()"

  CLOSED_BETS_SQL = "closes_on < now()
                 AND (winning_bets_option_id is not null
                   OR tie is true
                   OR cancelled is true
                   OR forfeit is true)"

  after_save :process_bets_options
  has_many :bets_options, :dependent => :destroy

  scope :awaiting_result, :conditions => Bet::AWAITING_RESULT_SQL,
                                :order => 'closes_on DESC, id DESC'

  scope :closed_bets, :conditions => Bet::CLOSED_BETS_SQL,
                            :order => 'closes_on DESC, id DESC'

  scope :open_bets, :conditions => Bet::OPEN_BETS_SQL,
                          :order => 'closes_on ASC, id ASC'

  scope :played_bets, :conditions => (
      "#{CLOSED_BETS_SQL} AND cancelled IS FALSE AND forfeit IS FALSE")

  def self.generate_top_bets_winners_minicolumns
    # Buscamos los users que más han ganado en los ultimos days y mostramos sus
    # ganancias en sus últimas 30 apuestas.
    days = 30
    bets = 30
    data = {}
    i = 0
    Bet.top_earners("#{days} days").each do |dbt|
      # Don't remove tp, if you do YAML will incorrectly parse it as string for
      # some values and as int for others .
      # usamos i para que al cargar luego el dict se cargue luego en el orden
      # correcto.
      k = "rank#{i}_#{dbt[0].id}"
      data[k] = {:sum => dbt[1].to_i}
      u = dbt[0]
      dst_file = (
          "#{Rails.root}/public/storage/minicolumns/bets_top_last30/#{u.id}.png"
      )

      dst_dir = File.dirname(dst_file)
      FileUtils.mkdir_p(dst_dir) unless File.exists?(dst_dir)

      netw = Bet.earnings(u, bets, "#{days} days")
      data[k][:individual] = netw
      i += 1
      bet_rate = netw.concat([0] * (bets - netw.size)).reverse.join(',')
      `/usr/bin/python script/spark.py bet_rate #{bet_rate} "#{dst_file}"`
    end

    # TODO hacer esto para CADA portal LOL
    dst = Bet::TOP_BET_WINNERS
    FileUtils.mkdir_p(File.dirname(dst)) unless File.exists?(File.dirname(dst))
    File.open(dst, 'w').write(YAML::dump(data))
  end

  # Calculates prediction accuracy stats for the crowd and for everybody who
  # bet on every bet closed on a given date.
  def self.update_prediction_accuracy(date)
    crowd_wins = 0
    users_totals = {}
    users_wins = {}
    bets = Bet.published.played_bets.find(
        :all,
        :conditions => ["closes_on::date = ?::date", date])
    bets.each do |bet|
      crowd_decision = bet.determine_crowd_decision
      crowd_selection, winners, user_votes = crowd_decision
      user_votes.each do |k, v|
        users_totals[k] ||= 0
        users_totals[k] += 1
        users_wins[k] ||= 0
      end
      winners.each do |user_id|
        users_wins[user_id] += 1
      end

      if bet.tie and crowd_selection == Bet::TIE
        crowd_wins += 1
      elsif bet.winning_bets_option_id == crowd_selection
        crowd_wins += 1
      end
    end

    return if bets.size == 0

    # Persist results
    User.db_query(
        "UPDATE stats.general
            SET played_bets_participation = #{bets.size},
                played_bets_crowd_correctly_predicted = #{crowd_wins}
          WHERE created_on = '#{date}'::date")

    users_totals.each do |user_id, bets|
      correctly_predicted = users_wins[user_id]
      User.db_query(
          "UPDATE stats.users_daily_stats
              SET played_bets_participation = #{bets},
                  played_bets_correctly_predicted = #{correctly_predicted}
            WHERE user_id = #{user_id}
              AND created_on = '#{date}'::date")
    end
  end

  def self.earnings(user, limit=30, time_window=nil)
    # Returns a user earnings during a time window.
    #
    # Args:
    #   user: the user to calculate earnings for.
    #   limit: the maximum number of bets to consider.
    #   time_window: an SQL-compatible time interval definition. Eg: '7 days'
    #
    # Returns:
    #   An array of earnings per bet sorted by bet closing time.
    where_sql = ""
    if time_window
      where_sql = " AND bet_id in (SELECT id
                                     FROM bets
                                    WHERE closes_on >= now()
                                          - '#{time_window}'::interval)"
    end

    db_query("SELECT net_ammount
                FROM stats.bets_results
               WHERE user_id = #{user.id}
                #{where_sql}
            ORDER BY (SELECT closes_on FROM bets WHERE id = bet_id) DESC
               LIMIT #{limit}").collect do |dbr|
      dbr['net_ammount'].to_i * (-1)
     end
  end

  def self.top_earners(time_window=nil)
    # Returns the user who earned more money in a time interval.
    #
    # Args:
    #   time_window: an SQL-compatible time interval definition. Eg: '7 days'
    where_sql = ""
    if time_window
      where_sql = " AND closes_on >= now() - '#{time_window}'::interval"
    end

    User.db_query("SELECT user_id,
                     SUM(net_ammount)
                FROM stats.bets_results
               WHERE bet_id IN (SELECT id
                                 FROM bets
                                 WHERE state = #{Cms::PUBLISHED}
                                   AND (winning_bets_option_id IS NOT NULL
                                    OR forfeit = 't'
                                    OR cancelled = 't'
                                    OR tie = 't')
                                   #{where_sql})
               GROUP BY user_id
               ORDER BY sum(net_ammount) ASC
                  LIMIT 10").collect do |dbr|
      [User.find(dbr['user_id'].to_i), dbr['sum']]
    end
  end

  def can_be_reopened?
    # Returns true if a completed bet can be reopened.
    self.completed? && self.state == Cms::PUBLISHED &&
    self.closes_on > 2.weeks.ago
  end

  def amount_on_team1
    self.bets_options.first.ammount
  end

  def amount_on_team2
    self.bets_options.last.ammount
  end

  def ratio_amounts
    amount1 = self.amount_on_team1.to_f
    amount1 / [amount1 + self.amount_on_team2, 1].max
  end

  def complete(result)
    # Completes a bet.
    #
    # Args:
    #   result: "cancelled", "forfeit", "tie" or the winning bets_option.id.
    return if self.completed?

    # We make sure that the bet's cached total amount is correct
    total_amount = BetsOption.sum(:ammount,
                                  :conditions => ['bet_id = ?', self.id]).to_f
    self.update_attribute(:total_ammount, total_amount)

    case result
    when "cancelled"
      self.return_bet_money
      self.cancelled = true
    when "forfeit"
      self.return_bet_money
      self.forfeit = true
    when "tie"
      self.resolve_tie
      self.tie = true
    else
      self.resolve_not_tie(result)
      self.winning_bets_option_id = result
    end

    self.save
    self.calculate_earnings
  end

  def completed?
    # Returns true if a bet's result has been set.
    (!self.winning_bets_option_id.nil?) || self.cancelled || self.forfeit ||
    self.tie
  end

  def can_be_resolved?
    !self.completed? && (Time.now > self.closes_on)
  end

  def earnings(user)
    # Returns the amount a user got back from a bet including what he bet.
    db_query("SELECT net_ammount
                FROM stats.bets_results
               WHERE user_id = #{user.id}
                 AND bet_id = #{self.id}")[0]['net_ammount'].to_i * (-1)
  end


  def options_new=(opts_new)
    @_tmp_options_new = opts_new
    self.attributes.delete :options_new
  end

  def options_delete=(opts_new)
    @_tmp_options_delete = opts_new
    self.attributes.delete :options_delete
  end

  def options=(opts_new)
    @_tmp_options = opts_new
    self.attributes.delete :options
  end

  def reopen
    # Reopens a closed bet.
    #
    # TODO(slnc): This only works if the bet's title hasn't been modified
    # since the bet was completed because we depend on cash movements' titles to
    # return the money back to users.
    raise "Bet unclosed" unless self.can_be_reopened?

    self.update_attributes({ :winning_bets_option_id => nil,
                             :cancelled => false,
                             :forfeit => false,
                             :tie => false})

    conditions = "description LIKE 'Ganancias %\"#{title.gsub('"', '\\"')}\"'"
    CashMovement.find(:all, :conditions => conditions).each do |cm|
      Bank.revert_transfer(cm)
    end

    User.db_query("DELETE FROM stats.bets_results WHERE bet_id = #{self.id}")
  end

  def team1
    self.bets_options.first.name
  end

  def team2
    self.bets_options.last.name
  end

  def users_with_bets
    User.db_query(
      "SELECT COUNT(DISTINCT(user_id))
       FROM bets_tickets
       WHERE bets_option_id IN (SELECT id FROM bets_options WHERE bet_id = #{self.id})
       AND ammount > 0")[0]['cnt'].to_i
  end

  protected
  def calculate_earnings
    # Calculates how much each bet participant won discounting their own bets.
    _users = self.users
    _users.each do |user|
      if self.cancelled? || self.forfeit? || _users.size == 1
        net_ammount = 0
      else
        description = "Ganancias por tu apuesta por \"#{self.resolve_hid}\""
        conditions = ["object_id_to_class = 'User'
                   AND object_id_to = #{user.id}
                   AND description = ?", description]
        cash_movement = CashMovement.find(:first, :conditions => conditions)
        earnings = cash_movement ? cash_movement.ammount : 0

        net_ammount = self.total_user_amount(user) - earnings
      end

      db_query("INSERT INTO stats.bets_results(bet_id, user_id, net_ammount)
                     VALUES (#{self.id}, #{user.id}, #{net_ammount})")
    end
  end

  def process_bets_options
    if @_tmp_options_new
      @_tmp_options_new.each do |s|
        self.bets_options.create({:name => s.strip}) if s.strip != ''
      end
      @_tmp_options_new = nil
    end

    if @_tmp_options_delete
      @_tmp_options_delete.each do |id|
        self.bets_options.find(id).destroy if self.bets_options.find_by_id(id)
      end
      @_tmp_options_delete = nil
    end

    if @_tmp_options
      @_tmp_options.keys.each do |id|
        option = self.bets_options.find_by_id(id.to_i)
        if option && option.name != @_tmp_options[id]
          option.name = @_tmp_options[id].strip
          option.save
        end
      end
      @_tmp_options = nil
    end
    true
  end

  def resolve_not_tie(winning_bets_option_id)
    # Resolves a bet where one participant won and the other lost.
    #
    # Everybody who bet on the winning option gets their money back. In addition
    # all the money bet on the losing option is distributed amoung people who
    # bet on the winning option. The more you bet on the winning option compared
    # to other people who also bet on the winning option the more money you will
    # get from the pot of money from the losing option. Eg:
    #
    # UserA bets 100 on option 1
    # UserB bets 10 on option 1
    # UserC bets 50 on option 2
    # Option 1 wins.
    # UserA will get 100 + (100/110) * 50
    # UserB will get 10 + (10/110) * 50
    if self.bets_options.find_by_id(winning_bets_option_id).nil?
      raise "Unable to find bet option #{winning_bets_option_id}"
    end

    _users = self.users
    if _users.size == 1
      user_earnings = self.total_user_amount(_users[0])
      return if user_earnings == 0
      Bank.transfer(:bank, _users[0], user_earnings,
          "Solo tú participaste en la apuesta \"#{self.resolve_hid}\"")
    elsif _users.size > 1
      amount_on_loser = BetsOption.sum(
          :ammount, :conditions => ["bet_id = ? AND id <> ?", self.id,
                                    winning_bets_option_id])
      return if amount_on_loser == 0

      winning_option = BetsOption.find(winning_bets_option_id)
      winning_option.bets_tickets.each do |ticket|
        percentage = (ticket.ammount / winning_option.ammount)
        user_earnings = ticket.ammount + percentage * amount_on_loser
        next if user_earnings == 0
        Bank.transfer(:bank, ticket.user, user_earnings,
            "Ganancias por tu apuesta por \"#{self.resolve_hid}\"")
      end
    end
  end

  def resolve_tie
    # Resolves a bet where both participants tied.
    #
    # The algorithm has 2 phases:
    # Phase 1: each user gets back an amount proportional to how even they
    # placed their bets. Eg:
    # UserA bets 50 on option 1 and 50 on option 2. Gets back 50/50 * 100 = 100
    # UserB bets 10 on option 1 and 90 on option 2. Gets back 10/90 * 100 = 11.1
    #
    # Phase 2: from all the undistributed money left each user gets a percentage
    # relative to how much they got from the first option. Eg: (from the
    # previous example)
    # Remaining money to distribute: 200 - 100 - 11.1 = 88.9.
    # UserA will get 88.9 * 100/111.1 = 80
    # UserB will get 88.9 * 11.1/100 = 8.88
    #
    # In phase 1 we favor people who bet for a tie and in phase 2 we favor
    # people who risked more by betting more money.
    phase1_money = {}
    ratios = {}
    money_pool = self.total_ammount
    _bets_options = self.bets_options
    _users = self.users

    # We calculate ratio of amount bet across options for each user (phase 1).
    for user in _users
      amount1 = user_amount_in_option(user, _bets_options[0])
      amount2 = user_amount_in_option(user, _bets_options[1])

      if amount1 == 0 && amount2 == 0
        next
      elsif amount1 == 0 || amount2 == 0
        ratio = 0.01
      else
        ratio = (amount1 < amount2) ? amount1/amount2 : amount2/amount1
      end

      ratios[user.id] = ratio
      phase1_money[user.id] = ratio * (amount1 + amount2)
      money_pool -= phase1_money[user.id]
    end

    if Math.standard_deviation(ratios.values) == 0
      # Everybody made exactly the same bet, to prevent rounding issues we
      # return exactly what they bet.
      reason = "Ganancias por tu apuesta por \"#{self.resolve_hid}\""
      self.return_bet_money(reason=reason)
    else
      total_phase1 = phase1_money.values.sum.to_f
      # Phase 2
      _users.each do |user|
        next if phase1_money[user.id].to_i == 0
        percentage = (phase1_money[user.id] / total_phase1)
        earnings = phase1_money[user.id] + percentage * money_pool
        if earnings > 0
          Bank.transfer(:bank, user, earnings,
            "Ganancias por tu apuesta por \"#{self.resolve_hid}\"")
        end
      end
    end
  end

  def return_bet_money(reason=nil)
    # Returns to each user exactly the amount they bet.
    return if self.completed?

    if reason.nil?
      reason = "Apuestas para partida \"#{self.resolve_hid}\" canceladas"
    end

    self.users.each do |user|
      user_earnings = self.total_user_amount(user)
      if user_earnings > 0
        Bank.transfer(:bank, user, user_earnings, reason)
      end
    end
  end

  def user_amount_in_option(user, bets_option)
    # Returns the amount bet by a user in a given option.
    ticket = bets_option.bets_tickets.find_by_user_id(user.id)
    ticket ? ticket.ammount : 0.0
  end

  def users
    # Returns users who have placed bets in this bet.
    User.find(:all, :conditions => "id IN (
        SELECT distinct(user_id) as user_id
          FROM bets_tickets
         WHERE bets_option_id IN (SELECT id
                                    FROM bets_options
                                   WHERE bet_id = #{self.id}))")
  end

  def total_user_amount(user)
    # Returns the total amount of money placed on this bet by a user.
    conditions = "bets_option_id IN (SELECT id
                                       FROM bets_options
                                      WHERE bet_id = #{self.id})
              AND user_id = #{user.id}"
    BetsTicket.sum(:ammount, :conditions => conditions)
  end

  public
  def determine_crowd_decision
    votes_tie = 0
    votes_a = 0
    votes_b = 0
    options = []
    users_tie = []
    users_a = []
    users_b = []
    user_votes = {}
    self.bets_options.each do |option|
      options<< option
    end
    winners = []
    self.users.each do |user|
      sum_option_a = self.user_amount_in_option(user, options[0])
      sum_option_b = self.user_amount_in_option(user, options[1])
      next if sum_option_a + sum_option_b == 0
      if sum_option_a == sum_option_b
        votes_tie += 1
        user_votes[user.id] = Bet::TIE
        winners<< user.id if self.tie
      elsif sum_option_a > sum_option_b
        votes_a += 1
        user_votes[user.id] = options[0].id
        winners<< user.id if self.winning_bets_option_id == options[0].id
      else
        votes_b += 1
        user_votes[user.id] = options[1].id
        winners<< user.id if self.winning_bets_option_id == options[1].id
      end
    end

    if votes_tie + votes_a + votes_b == 0
      return [-1, winners, user_votes]
    end

    if votes_tie > votes_a and votes_tie > votes_b
      return [Bet::TIE, winners, user_votes]
    elsif votes_a > votes_tie and votes_a > votes_b
      return [options[0].id, winners, user_votes]
    elsif votes_b > votes_tie and votes_b > votes_a
      return [options[1].id, winners, user_votes]
    else
      return [options[0].id, winners, user_votes]
    end
  end
end
