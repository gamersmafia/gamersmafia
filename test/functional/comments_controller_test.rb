# -*- encoding : utf-8 -*-
require 'test_helper'

class CommentsControllerTest < ActionController::TestCase

  NEW_COMMENT_OPTS = {
    :comment => {
      :comment => 'foo',
      :content_id => Content.published.find(:first).id,
    },
    :add_to_tracker => '1', :redirto => '/foo',
  }

  test "should_allow_registered_user_to_comment" do
    sym_login :panzer
    panzer = User.find_by_login('panzer')
    assert_difference("Comment.count") do
      post :create, NEW_COMMENT_OPTS
    end
    assert_redirected_to '/foo'
    @c = Comment.find(:first, :order => 'id DESC')
    assert_equal panzer.id, @c.user_id
  end

  test "should_update" do
    test_should_allow_registered_user_to_comment
    orig = @c.comment
    sym_login @c.user_id
    post :update, { :id => @c.id, :comment => {:comment => 'feoooote'}}
    assert_response :redirect
    @c.reload
    assert_equal 'feoooote', @c.comment
    assert_equal @c.user_id, @c.lastedited_by_user_id
  end

  test "should_edit_previous_comment_if_last_comment_is_yours_and_less_than_1h" do
    test_should_allow_registered_user_to_comment
    prev = Comment.find(:first, :order => 'id DESC')

    c_initial = Comment.count
    opts = {}.merge(NEW_COMMENT_OPTS)
    opts[:comment][:comment] ='bar'
    post :create, opts
    assert_redirected_to '/foo'
    assert_equal c_initial, Comment.count
    @c = Comment.find(:first, :order => 'id DESC')

    assert_equal @c.id, prev.id
    assert_equal "#{prev.comment}\n\n[b]Editado[/b]: bar", @c.comment
  end

  test "should_add_to_tracker_if_comment_created_ok" do
    u = User.find_by_login(:panzer)
    u.notifications_trackerupdates = true
    u.save
    items_count = u.tracker_items.count
    test_should_allow_registered_user_to_comment
    assert_equal items_count + 1, u.tracker_items.count
  end

  test "should_not_break_if_trying_to_add_to_tracker_if_comment_created_ok_twice" do
    u = User.find_by_login(:panzer)
    items_count = u.tracker_items.count
    test_should_add_to_tracker_if_comment_created_ok
    post :create, NEW_COMMENT_OPTS
    assert_response :redirect
    assert_equal items_count + 1, u.tracker_items.count
  end

  test "rateup with skill" do
    test_should_allow_registered_user_to_comment
    give_skill(1, "RateCommentsUp")
    sym_login 1
    User.db_query(
        "UPDATE users set created_on = '2006-01-01 00:00:00' where id = 1")
    assert_difference("CommentsValoration.count") do
      post :rate, {:comment_id => @c.id, :rate_id => 2}
    end
    assert_response :success
  end

  test "rateup no skill" do
    test_should_allow_registered_user_to_comment
    sym_login 1
    User.db_query(
        "UPDATE users set created_on = '2006-01-01 00:00:00' where id = 1")
    assert_difference("CommentsValoration.count", 0) do
      post :rate, {:comment_id => @c.id, :rate_id => 2}
    end
    assert_response :success
  end

  test "ratedown with skill" do
    test_should_allow_registered_user_to_comment
    give_skill(1, "RateCommentsDown")
    sym_login 1
    User.db_query(
        "UPDATE users set created_on = '2006-01-01 00:00:00' where id = 1")
    assert_difference("CommentsValoration.count") do
      post :rate, {:comment_id => @c.id, :rate_id => 5}
    end
    assert_response :success
  end

  test "ratedown no skill" do
    test_should_allow_registered_user_to_comment
    sym_login 1
    User.db_query(
        "UPDATE users set created_on = '2006-01-01 00:00:00' where id = 1")
    assert_difference("CommentsValoration.count", 0) do
      post :rate, {:comment_id => @c.id, :rate_id => 5}
    end
    assert_response :success
  end

  test "report invalid moderation_reason" do
    test_should_allow_registered_user_to_comment
    give_skill(1, "ReportComments")
    sym_login 1
    assert_difference("Alert.count", 0) do
      post :report, :id => @c.id
    end
    assert_response :success
  end

  test "report valid moderation_reason no skill" do
    test_should_allow_registered_user_to_comment
    sym_login 1
    assert_raises(AccessDenied) do
      post :report, {
          :id => @c.id,
          :moderation_reason => Comment::MODERATION_REASONS_TO_SYM.keys.first,
      }
    end
    assert_response :success
  end

  test "report valid moderation_reason with skill" do
    test_should_allow_registered_user_to_comment
    give_skill(1, "ReportComments")
    sym_login 1
    assert_difference("Alert.count", 1) do
      post :report, {
          :id => @c.id,
          :moderation_reason => Comment::MODERATION_REASONS_TO_SYM.keys.first,
      }
    end
    assert_response :success
  end

  test "should_not_add_to_tracker_if_comment_created_ok_but_not_selected" do
    u = User.find_by_login(:panzer)
    u.notifications_trackerupdates = true
    u.save
    items_count = u.tracker_items.count
    c_initial = Comment.count
    sym_login :panzer
    panzer = User.find_by_login('panzer')
    post :create, NEW_COMMENT_OPTS.merge({:add_to_tracker => '0'})
    assert_redirected_to '/foo'
    assert_equal c_initial + 1, Comment.count
    assert_equal items_count, u.tracker_items.count
  end


  test "should_redirect_to_home_if_commenting_to_nonexistent_content" do
    sym_login :panzer
    assert_raises(ActiveRecord::RecordNotFound) {
      post :create, NEW_COMMENT_OPTS.merge({:comment => { :content_id => 0}})
    }
  end

  test "should_edit_comment" do
    test_should_allow_registered_user_to_comment
    get :edit, { :id =>  @c.id }
    assert_response :success
  end

  test "report_should_raise_access_denied_if_not_right_user" do
    test_should_allow_registered_user_to_comment
    sym_login 2
    assert_raises(AccessDenied) do
      post :report, :id => @c.id
    end
  end
end
