# -*- encoding : utf-8 -*-
class SentEmail < ActiveRecord::Base
  validates_presence_of :message_key
  validates_uniqueness_of :message_key

  def self.remove_old_sent_emails
    User.db_query(
        "DELETE FROM sent_emails
         WHERE created_on <= now() - '1 month'::interval")
  end
end
