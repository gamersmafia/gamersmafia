# -*- encoding : utf-8 -*-
require 'test_helper'

class SentEmailTest < ActiveSupport::TestCase

  def create_email
    se = SentEmail.new(:message_key => "foo")
    assert_difference("SentEmail.count") do
      se.save
    end
    se
  end

  test "remove_old_sent_emails old" do
    se = create_email
    se.update_attribute(:created_on, 2.months.ago)
    assert_difference("SentEmail.count", -1) do
      SentEmail.remove_old_sent_emails
    end
  end

  test "remove_old_sent_emails not old" do
    se = create_email
    assert_difference("SentEmail.count", 0) do
      SentEmail.remove_old_sent_emails
    end
  end
end
