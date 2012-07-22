# -*- encoding : utf-8 -*-
require 'test_helper'

class BetTest < ActiveSupport::TestCase

  def setup
    @bet = Bet.create({
      :user_id => 1,
      :title => 'foo1 vs bar1',
      :terms => 1,
      :closes_on => 1.day.since})
    @bet.change_state(Cms::PUBLISHED, User.find(1))
    @bets_option_foo = @bet.bets_options.create({:name => 'foo'})
    @bets_option_bar = @bet.bets_options.create({:name => 'bar'})
    @bet.closes_on = 1.second.ago
    @bet.save
  end

  def prepare_first_three_users
    @u1 = User.find(1)
    @u2 = User.find(2)
    @u3 = User.find(3)
    Bank.transfer(:bank, @u1, 100, 't1')
    Bank.transfer(:bank, @u2, 100, 't2')
    Bank.transfer(:bank, @u3, 100, 't3')
    @u1.reload
    @u2.reload
    @u3.reload

    @cash_u1 = @u1.cash
    @cash_u2 = @u2.cash
    @cash_u3 = @u2.cash
  end

  test "update_prediction_accuracy smoke_test no winners" do
    some_timestamp = 28.hours.ago
    User.db_query(
        "INSERT INTO stats.general(created_on)
              VALUES ('#{some_timestamp}'::date)")

    @bet.closes_on = some_timestamp
    @bet.complete(@bet.bets_options.first.id)
    assert @bet.completed?
    Bet.update_prediction_accuracy(some_timestamp)
    assert_equal 1, User.db_query(
        "SELECT played_bets_participation
           FROM stats.general
       ORDER BY created_on DESC LIMIT 1")[0][
         "played_bets_participation"].to_i
    assert_equal 0, User.db_query(
        "SELECT played_bets_crowd_correctly_predicted
           FROM stats.general
       ORDER BY created_on DESC
          LIMIT 1")[0]["played_bets_participation"].to_i
  end

  test "update_prediction_accuracy smoke_test with winners" do
    some_timestamp = 28.hours.ago
    User.db_query(
        "INSERT INTO stats.general(created_on)
              VALUES ('#{some_timestamp}'::date)")

    User.db_query(
        "INSERT INTO stats.users_daily_stats(user_id, created_on)
              VALUES (1, '#{some_timestamp}'::date)")

    User.db_query(
        "INSERT INTO stats.users_daily_stats(user_id, created_on)
              VALUES (2, '#{some_timestamp}'::date)")

    prepare_first_three_users
    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => BetsTicket::MIN_BET + 10})
    @bet.closes_on = some_timestamp
    @bet.complete(@bets_option_foo.id)
    assert @bet.completed?
    Bet.update_prediction_accuracy(some_timestamp)
    assert_equal 1, User.db_query(
        "SELECT played_bets_participation
           FROM stats.general
       ORDER BY created_on DESC LIMIT 1")[0][
         "played_bets_participation"].to_i

    assert_equal 1, User.db_query(
        "SELECT played_bets_crowd_correctly_predicted
           FROM stats.general
       ORDER BY created_on DESC
          LIMIT 1")[0]["played_bets_crowd_correctly_predicted"].to_i

    assert_equal 1, User.db_query(
        "SELECT played_bets_correctly_predicted
           FROM stats.users_daily_stats
          WHERE user_id = 1
       ORDER BY created_on DESC LIMIT 1")[0][
         "played_bets_correctly_predicted"].to_i

    assert_equal 1, User.db_query(
        "SELECT played_bets_participation
           FROM stats.users_daily_stats
          WHERE user_id = 1
       ORDER BY created_on DESC LIMIT 1")[0][
         "played_bets_participation"].to_i

    assert_equal 0, User.db_query(
        "SELECT played_bets_correctly_predicted
           FROM stats.users_daily_stats
          WHERE user_id = 2
          ORDER BY created_on DESC LIMIT 1")[0][
            "played_bets_correctly_predicted"].to_i

    assert_equal 1, User.db_query(
        "SELECT played_bets_participation
           FROM stats.users_daily_stats
          WHERE user_id = 2
       ORDER BY created_on DESC LIMIT 1")[0][
         "played_bets_participation"].to_i
  end


  test "should_return_money_if_cancelled" do
    u1 = User.find(1)
    u2 = User.find(2)
    Bank.transfer(:bank, u1, 100 , 't1')
    Bank.transfer(:bank, u2, 100 , 't2')
    u1.reload
    u2.reload

    cash_u1 = u1.cash
    cash_u2 = u2.cash

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({
      :user_id => 1,
      :ammount => BetsTicket::MIN_BET})

    @bets_option_foo.bets_tickets.create({
      :user_id => 2,
      :ammount => BetsTicket::MIN_BET + 5})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => BetsTicket::MIN_BET + 10})

    @bet.complete('cancelled')
    assert_equal true, @bet.completed?

    u1.reload
    u2.reload

    assert_equal cash_u1, u1.cash
    assert_equal cash_u2, u2.cash
  end


  test "should_return_money_if_forfeit" do
    u1 = User.find(1)
    u2 = User.find(2)
    Bank.transfer(:bank, u1, 100 , 't1')
    Bank.transfer(:bank, u2, 100 , 't2')
    u1.reload
    u2.reload

    cash_u1 = u1.cash
    cash_u2 = u2.cash

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({
      :user_id => 1,
      :ammount => BetsTicket::MIN_BET})

    @bets_option_foo.bets_tickets.create({
      :user_id => 2,
      :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => 8})

    @bet.complete('forfeit')
    assert_equal true, @bet.completed?

    u1.reload
    u2.reload

    assert_equal cash_u1, u1.cash
    assert_equal cash_u2, u2.cash
  end


  test "should_properly_distribute_money_if_single_winner" do
    prepare_first_three_users

    bticket = @bets_option_foo.bets_tickets.create(
        :user_id => 1,
        :ammount => BetsTicket::MIN_BET)
    assert !bticket.new_record?, bticket.errors.full_messages_html

    bt = @bets_option_foo.bets_tickets.create(
        :user_id => 2,
        :ammount => BetsTicket::MIN_BET)
    assert !bt.new_record?, bt.errors.full_messages_html
    bt = @bets_option_bar.bets_tickets.create(
        :user_id => 2,
        :ammount => BetsTicket::MIN_BET)
    assert !bt.new_record?, bt.errors.full_messages_html

    @bets_option_bar.bets_tickets.create(
        :user_id => 3,
        :ammount => BetsTicket::MIN_BET)

    @bet.complete(@bets_option_bar.id)

    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload
    @u3.reload

    assert_equal @cash_u1 - BetsTicket::MIN_BET.to_d, @u1.cash
    assert_equal @cash_u2, @u2.cash
    assert_equal @cash_u3 + BetsTicket::MIN_BET.to_d, @u3.cash
  end

  # opcion1 | opcion2
  #     100 |       0       (u1)
  #       0 |     100       (u2)
  test "should_properly_distribute_money_if_tie_all_100pc_and_same_ammount" do
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => 100})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => 100})

    @bet.complete('tie')

    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end

  # opcion1 | opcion2
  #      50 |       0       (u1)
  #       0 |     100       (u2)
  test "should_properly_distribute_money_if_tie_all_100pc_and_different_ammount" do
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => 50})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => 100})

    @bet.complete('tie')

    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end

  # opcion1 | opcion2
  #      50 |      50       (u1)
  #      50 |      50       (u2)
  test "should_properly_distribute_money_if_tie_all_0pc_and_same_ammount" do
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => 50})
    @bets_option_bar.bets_tickets.create({
      :user_id => 1,
      :ammount => 50})
    @bets_option_foo.bets_tickets.create({
      :user_id => 2,
      :ammount => 50})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => 50})

    @bet.complete('tie')

    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end


  # opcion1 | opcion2
  #      50 |      50       (u1)
  #      50 |      50       (u2)
  test "should_properly_distribute_money_if_tie_all_0pc_and_mixed_ammounts" do
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => 25})
    @bets_option_bar.bets_tickets.create({
      :user_id => 1,
      :ammount => 25})
    @bets_option_foo.bets_tickets.create({
      :user_id => 2,
      :ammount => 50})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => 50})

    @bet.complete('tie')

    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end

  # opcion1 | opcion2
  #     100 |       0       (u1)
  #      50 |      50       (u2)
  #      25 |      75       (u3)
  test "should_properly_distribute_money_if_tie_mixed" do
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({
      :user_id => 1,
      :ammount => 100})
    @bets_option_foo.bets_tickets.create({
      :user_id => 2,
      :ammount => 50})
    @bets_option_bar.bets_tickets.create({
      :user_id => 2,
      :ammount => 50})
    @bets_option_foo.bets_tickets.create({
      :user_id => 3,
      :ammount => 25})
    @bets_option_bar.bets_tickets.create({
      :user_id => 3,
      :ammount => 75})

    @bet.complete('tie')

    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload
    @u3.reload

    assert_equal 10.23, @u1.cash
    assert_equal 223.33, @u2.cash
    assert_equal 74.44, @u3.cash
  end

  test "should properly return earnings" do
    test_should_properly_distribute_money_if_tie_mixed

    assert_equal (-97).to_i, @bet.earnings(@u1)
    assert_equal (123).to_i, @bet.earnings(@u2)
    assert_equal (-25).to_i, @bet.earnings(@u3)
  end

  test "should be able to close bet to comments" do
    bet = Bet.find(1)
    assert bet.close(User.find(1), 'blah')
    assert bet.closed?
  end
end
