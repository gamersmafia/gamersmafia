# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class ApuestasControllerTest < ActionController::TestCase
  test_common_content_crud({
      :name => 'Bet',
      :form_vars => {
          :title => 'footapang',
          :closes_on => 1.week.since,
          :options_new => ['opcion1', 'opcion2']},
      :root_terms => 1})

  test "should_create_with_options" do
    sym_login 1
    post(:create,
         :bet => {
             :title => 'footapang',
             :closes_on => 1.week.since,
             :options_new => ['opcion1', 'opcion2']},
         :root_terms => 1)
    assert_response :redirect
    @b = Bet.find_by_title('footapang')
    assert_not_nil @b
    assert_equal 2, @b.bets_options.count
    assert_not_nil @b.bets_options.find_by_name('opcion1')
    assert_not_nil @b.bets_options.find_by_name('opcion2')
  end

  test "should_allow_to_change_options_if_not_published" do
    test_should_create_with_options
    b = Bet.find_by_title('footapang')
    post :update, {:id => b.id,
      :bet => { :options => {b.bets_options.find_by_name('opcion1').id => 'opcion1_mod',
        b.bets_options.find_by_name('opcion2').id => 'opcion2_mod'}, # lo hacemos a propósito porque primero se borra y luego se actualiza, para comprobar que no se intenta actualizar una opción borrada
      :options_delete => [b.bets_options.find_by_name('opcion2').id],
      :options_new => ['opcion3', 'opcion4'] }
    }
    b.reload
    assert_equal 3, b.bets_options.count
    assert_nil b.bets_options.find_by_name('opcion1')
    assert_not_nil b.bets_options.find_by_name('opcion1_mod')
    assert_nil b.bets_options.find_by_name('opcion2')
    assert_not_nil b.bets_options.find_by_name('opcion3')
    assert_not_nil b.bets_options.find_by_name('opcion4')
  end

  test "shouldnt_allow_to_reduce_bet_for_option_after_15min" do
    test_should_create_with_options
    sym_login 1
    Bank.transfer(:bank, User.find(1), 100, "Asuntos sucios")
    Content.publish_content_directly(@b, Ias.MrMan)
    assert_equal Cms::PUBLISHED, @b.state
    bop1 = @b.bets_options.find(:first)
    post :update_cash_for_bet, {:id => @b.id, :bet_options => {bop1.id.to_s => '10'}}
    assert_response :redirect

    bt = bop1.bets_tickets.find(:first, :order => 'id DESC')
    # test that it works if within time limit
    post :update_cash_for_bet, {:id => @b.id, :bet_options => {bop1.id.to_s => '9'}}
    assert_response :redirect
    assert_nil flash[:error], flash[:error]
    bt.reload
    assert_equal 9, bt.ammount.to_i


    bt.created_on = 2.weeks.ago
    assert_equal true, bt.save

    # out of time limit
    post :update_cash_for_bet, {:id => @b.id, :bet_options => {bop1.id.to_s => '5'}}
    assert_response :redirect
    assert_not_nil flash[:error]
    bt.reload
    assert_equal 9, bt.ammount.to_i
  end

  test "complete_should_work" do
    test_should_create_with_options
    Content.publish_content_directly(@b, User.find(1))
    @b.reload
    @b.closes_on = 1.week.ago
    assert @b.save
    post :complete, {:id => @b.id, :winner => @b.bets_options.find(:first).id}
    assert_response :redirect
    assert !@b.completed?
    @b.reload
    assert @b.completed?
  end

  test "resolve_should_work" do
    test_should_create_with_options
    Content.publish_content_directly(@b, User.find(1))
    @b.reload
    @b.closes_on = 1.week.ago
    assert @b.save
    get :resolve, { :id => @b.id }
    assert_response :success
  end

  test "should_initialize_not_closed_bet" do
    test_should_create_with_options
    @b.closes_on = 1.week.since
    @b.cancelled = false
    @b.forfeit = false
    @b.tie = false
    @b.winning_bets_option_id = nil
    assert_not_nil @b.closes_on
    assert_equal @b.cancelled, false
    assert_equal @b.forfeit, false
    assert_equal @b.tie, false
    assert_equal @b.winning_bets_option_id, nil
  end

  test "should_not_resolve_if_not_closed" do
    test_should_initialize_not_closed_bet
    assert !@b.can_be_resolved?
  end

  test "should_resolve_if_closed" do
    test_should_initialize_not_closed_bet
    @b.closes_on = 1.day.ago
    assert @b.can_be_resolved?
  end

  test "should_not_resolve_if_cancelled" do
    test_should_initialize_not_closed_bet
    @b.cancelled = true
    assert !@b.can_be_resolved?
  end

  test "should_not_resolve_if_forfeit" do
    test_should_initialize_not_closed_bet
    @b.forfeit = true
    assert !@b.can_be_resolved?
  end

  test "should_not_resolve_if_tie" do
    test_should_initialize_not_closed_bet
    @b.tie = true
    assert !@b.can_be_resolved?
  end

  test "should_not_resolve_if_winning_bets_option_id_not_nil" do
    test_should_initialize_not_closed_bet
    @b.winning_bets_option_id = 23
    assert !@b.can_be_resolved?
  end

  test "cambiar_resultado_should_work" do
    test_complete_should_work
    post :cambiar_resultado, :id => @b.id
    assert_redirected_to "/apuestas/resolve/#{@b.id}"
    @b.reload
    assert !@b.completed?
  end
end
