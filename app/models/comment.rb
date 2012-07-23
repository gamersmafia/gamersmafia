# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base
  belongs_to :content
  belongs_to :user
  after_create :do_after_create
  after_create :schedule_image_parsing
  after_save :schedule_ne_references_calculation

  belongs_to :lastedited_by, {:class_name => 'User',
                              :foreign_key => 'lastedited_by_user_id'}
  has_many :comments_valorations, :dependent => :destroy

  before_save :truncate_long_comments
  before_save :set_portal_id_based_on_content
  before_save :check_copy_if_changing_lastedited_by_user_id
  serialize :cache_rating

  validates_presence_of :comment, :message => 'no puede estar en blanco'
  validates_presence_of :user_id, :message => 'no puede estar en blanco'

  # Comment is visible to everybody.
  VISIBLE = 0

  # Comment is only visible to people who want to see unpopular comments.
  HIDDEN = 1

  # Comment is not visible to anyone because it violates the netiquette.
  MODERATED = 2

  # Minimum number of comment valorations to hide a comment.
  NEGATIVE_VALORATIONS_TO_HIDE = 3

  def hidden?
    self.state == HIDDEN
  end

  def moderated?
    self.state == MODERATED
  end

  def visible?
    self.state == VISIBLE
  end

  def check_crowd_decision_on_visibility
    negative_valorations = self.comments_valorations.negative.count
    positive_valorations = self.comments_valorations.positive.count
    neutral_valorations = self.comments_valorations.neutral.count
    absolute_negative = negative_valorations - positive_valorations - neutral_valorations
    if absolute_negative >= NEGATIVE_VALORATIONS_TO_HIDE && self.visible?
      self.update_attributes(:state => HIDDEN)
    elsif absolute_negative < NEGATIVE_VALORATIONS_TO_HIDE && self.hidden?
      self.update_attributes(:state => VISIBLE)
    end
  end

  def regenerate_ne_references(users=[])
    NeReference.find(
        :all,
        :conditions => ["referencer_class = 'Comment' AND referencer_id = ?",
                        self.id]).each { |ne| ne.destroy }

    if users == []
      users = {}
      User.db_query("SELECT id, lower(login) as login FROM users where login_is_ne_unfriendly = 'f'").each do |dbu|
        users[dbu['login']] ||= []
        users[dbu['login']]<< ['User', dbu['id'].to_i]
      end

      User.db_query("SELECT user_id, lower(old_login) as old_login FROM user_login_changes").each do |dbu|
        users[dbu['old_login']] ||= []
        users[dbu['old_login']]<< ['User', dbu['user_id'].to_i]
      end

      User.db_query("SELECT id, lower(tag) as tag FROM clans").each do |dbu|
        users[dbu['tag']] ||= []
        users[dbu['tag']]<< ['Clan', dbu['id'].to_i]
      end
    end

    references = self.comment.slnc_tokenize & users.keys
    ne_refs = []
    references.uniq.each do |ref|
      ne_refs << NeReference.create({
          :entity_class => users[ref][0][0],
          :entity_id => users[ref][0][1],
          :referencer_class => 'Comment',
          :referencer_id => self.id,
          :referenced_on => self.created_on
      })
    end
    ne_refs
  end

  def schedule_image_parsing
    self.delay.download_remotes
  end

  def schedule_ne_references_calculation
    self.delay.regenerate_ne_references
  end

  def download_remotes
    new_t = Cms.download_and_rewrite_bb_imgs(self.comment, "comments/#{self.id % 1000}/#{self.id % 100}")
    self.update_attributes(:comment => new_t) if new_t != self.comment
  end

  def check_copy_if_changing_lastedited_by_user_id
    if (self.lastedited_by_user_id_changed? &&
        self.lastedited_by_user_id != self.user_id &&
        (self.lastedited_by_user_id_was.nil? ||
          self.lastedited_by_user_id_was == self.user_id))
      self.lastowner_version = self.comment_was
    elsif self.lastedited_by_user_id == self.user_id
      self.lastowner_version =  nil
    end
    true
  end

  def mark_as_deleted
    del_karma

    # update last_commented_on
    u = self.user
    last_comment = Comment.find_by_user_id(u.id, :conditions => "deleted = 'f'", :order => 'created_on DESC')
    u.lastcommented_on = last_comment ? last_comment.created_on : nil
    u.save

    # update counters
    User.decrement_counter('comments_count', self.user_id)
    Content.decrement_counter('comments_count', self.content_id)
    self.content.terms.each do |t|
      t.recalculate_counters
    end
    self.content.real_content.class.decrement_counter('cache_comments_count', self.content.real_content.id)

    self.deleted = true
    self.save
  end

  def set_portal_id_based_on_content
    self.portal_id = self.content.portal_id
  end

  def truncate_long_comments
    self.comment = self.comment[0..5999] if self.comment.length > 6000
    true
  end

  def do_after_create
    self.add_karma
    self.user.update_attributes(:lastcommented_on => self.created_on)
    self.delay.notify_trackers
  end

  def notify_trackers
    self.content.tracker_items.find(:all, :conditions => 'is_tracked = \'t\'', :include => [:user]).each do |t|
      u = t.user
      if u.id != self.user_id and u.notifications_trackerupdates and (t.notification_sent_on.nil? or t.lastseen_on > t.notification_sent_on) then
        Notification.trackerupdate(
            u, {:content => self.content.real_content}).deliver
        t.notification_sent_on = Time.now
        t.save
      end
    end
  end

  # Updates the weight that this comment has.
  #
  # If there are more than 60% negative ratings on a given comment the weight of
  # this comment towards ? will be 0, else it will be 1.
  # TODO(slnc): this is dead code but we are going to use something very similar
  # soon to automatically hide comments with a lot of negative ratings.
  #def update_default_comments_valorations_weight
  #  recent_ratings_proxy = self.comments_valorations_ratings.recent
	#  positive = recent_ratings_proxy.count(:conditions => 'comments_valorations_type_id IN (select id from comments_valorations_types where direction = 1)')
	#  negative = recent_ratings_proxy.count(:conditions => 'comments_valorations_type_id IN (select id from comments_valorations_types where direction = -1)')
	#  neutral = recent_ratings_proxy.count(:conditions => 'comments_valorations_type_id IN (select id from comments_valorations_types where direction = 0)')
  #  ratio = negative.to_f/(positive + negative + neutral)
	#  if ratio > 0.6
  #    weight = 0.0
	#  else
	#	  weight = 1.0
	#  end
  #end

  # Devuelve la página en la que aparece el comentario actual.
  def comment_page
    younger_comments = Comment.count(
        :conditions => ["deleted = 'f' AND content_id = ? AND created_on <= ?",
                        self.content_id, self.created_on])
   (younger_comments / Cms.comments_per_page.to_f).ceil
  end

  def can_be_rated_by?(user)
    !(user.id == self.user_id ||  # is author
     user.created_on > 7.days.ago ||  # is_too_young
     Karma.level(user.karma_points) == 0 ||  # no karma
     (user.remaining_rating_slots == 0 &&  # no ratings left
      user.comments_valorations.find_by_comment_id(self.id).nil?))
  end

  # Returns weight of a user's valoration on a given comment.
  #
  # Users rating a comment on their own faction have more weight than when they
  # rate on comments from a different faction.
  def user_weight(user)
    return 0 if user.default_comments_valorations_weight == 0

    content = self.content.real_content
    case content.class.name
      when 'Blogentry'
      user_authority = Blogs.user_authority(user)
      user_authority = 1.1 if user_authority < 1.1
      Math.log10(user_authority)/Math.log10(Blogs.max_user_authority)
    else
      max_karma = Karma.max_user_points
      max_faith = Faith.max_user_points
      # en caso de que no haya nadie popular
      max_friends = User.most_friends(1)[:friends] rescue 1
      ukp = user.karma_points
      ukp = 1.1 if ukp < 1.1

      ufp = user.faith_points
      ufp = 1.1 if ufp < 1.1

      karma_score = Math.log10(ukp) / Math.log10(max_karma)
      faith_score = Math.log10(ufp) / Math.log10(max_faith)
      friends_score = user.friends_count / (max_friends)
      w = (karma_score + faith_score + friends_score) / 3.0

      # Aproximación: si el usuario está comentado en su facción multiplicamos
      # por 2. Si usásemos los puntos de karma y de fe para esta facción no
      # sería necesario
      if (content.respond_to?(:my_faction) &&
          content.has_category? &&
          content.main_category &&
          content.my_faction &&
          content.my_faction.id == user.faction_id)
        w *= 2
        # nono limitamos a 1 para no perjudicar a los peces gordos
      end
      w
    end
  end

  def add_karma
    Karma.add_karma_after_comment_is_created(self)
  end

  def del_karma
    Karma.del_karma_after_comment_is_deleted(self)
  end

  def can_edit_comment?(user, is_moderator, saving=false)
    return false if user.nil?

    # If author is editing his comment we increase the limit to 30 min instead
    # of 15min.
    author_max_secs = Time.now - 60 * (saving ? 30 : 15)
    moderator_max_secs = 60 * 60 * 24 * 60  # two months

    if ((user.id == self.user.id && self.created_on > author_max_secs) ||
        (is_moderator && self.created_on > Time.now - moderator_max_secs))
      true
    else
      false
    end
  end

  def rate(user, rating)
    weight = self.user_weight(user)
    prev = comments_valorations.find(
        :first, :conditions => ['user_id = ?', user.id])
    if prev.nil?
      prev = comments_valorations.create({
          :user_id => user.id,
          :comments_valorations_type_id => rating.id,
          :weight => weight,
      })
    else
      prev.comments_valorations_type_id = rating.id
      prev.weight = weight
      prev.save
    end

    # TODO: por qué has_comments_valorations? devuelve true?
    if !has_comments_valorations
      self.has_comments_valorations = true
      self.save
    end
  end

  def get_rating
    if self.cache_rating.nil?
      self.cache_rating = Comments.get_ratings_for_comments([self.id])
      self.save
    end
    self.cache_rating
  end

  def user_can_report_comment?(user)
    user.is_hq?
  end

  # Returns previous comment if there is a previous comment to the current one
  # or nil if there is no previous comment.
  def previous_comment
    Comment.find(
        :first,
        :conditions => ["deleted = 'f' AND content_id = ? AND created_on < ?",
                        self.content_id,
                        self.created_on],
        :order => 'created_on DESC, id DESC')
  end


  def validate
    if new_record? && Comment.count(:conditions => [
          'host = ? and comment = ? and user_id = ? and content_id = ?',
          self.host, self.comment, self.user_id, self.content_id])
      self.errors.add(
          'text', 'Ya existe un comentario idéntico en este contenido.')
      return false
    end

    content = self.content
    if content.nil? || content.real_content.nil?
      self.errors[:base] << (
        'El contenido al que se refiere este comentario ya no existe')
      return false
    end
  end
end
