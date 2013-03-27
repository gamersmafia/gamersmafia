# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base

  # Comment is visible to everybody.
  VISIBLE = 0

  # Comment is only visible to people who want to see unpopular comments.
  HIDDEN = 1

  # Comment is not visible to anyone because it violates the netiquette.
  MODERATED = 2

  # Comment is not visible because it's duplicated.
  DUPLICATED = 3

  # Minimum number of comment valorations to hide a comment.
  NEGATIVE_VALORATIONS_TO_HIDE = 3

  MODERATION_REASONS = {
    :copyright => 1,
    :malware => 2,
    :porno => 3,
  }

  MODERATION_REASONS_TO_SYM = MODERATION_REASONS.invert

  FROZEN_ATTRIBUTES_IF_MODERATED = [
    :comment,
  ].freeze

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
  before_save :check_not_moderated
  belongs_to :portal
  serialize :cache_rating

  validates_presence_of :comment, :message => 'no puede estar en blanco'
  validates_presence_of :user_id, :message => 'no puede estar en blanco'

  scope :karma_eligible,
        :conditions => ["deleted is false AND state NOT IN (?)",
                        [MODERATED, DUPLICATED]]

  scope :visible,
        :conditions => ["state = ?", VISIBLE]


  # Converts a list of b64-encoded or urls into comment code uploading files
  # where necessary.
  def self.images_to_comment(images, user)
    text = []
    images.each do |img|
      if img[0..4] == 'data:'
        img = user.upload_b64_filedata(img)
      end
      text.append("[img]#{img.strip}[/img]")
    end
    text.join("\n")
  end

  # Takes a formatized text and appends it to the end of the comment.
  def append_update(text)
    self.update_attribute(
        :comment,
        "#{self.comment}\n\n[b]Editado[/b]: #{text}")
  end

  def check_not_moderated
    if self.moderated?
      FROZEN_ATTRIBUTES_IF_MODERATED.each do |attribute|
        attr_name = "#{attribute}_changed?"
        if self.send("#{attribute}_changed?")
          self.errors.add(
            attribute,
            "Imposible guardar el comentario porque ya está moderado.")
        end
      end
    end

    self.errors.size == 0
  end

  def karma_eligible?
    !(self.moderated? || self.duplicated?)
  end

  def moderation_reason_sym
    MODERATION_REASONS_TO_SYM[self.moderation_reason]
  end

  def self.moderation_reason_valid?(moderation_reason)
    MODERATION_REASONS_TO_SYM.has_key?(moderation_reason)
  end

  def moderate(user, moderation_reason)
    if !Comment.moderation_reason_valid?(moderation_reason)
      raise "Invalid moderation reason '#{moderation_reason}'"
    end

    raise "Comment is already moderated" if self.moderated?

    if user.id == self.user_id
      raise "Comment owner cannot moderate self comments."
    end

    self.update_attributes(
        :moderation_reason => moderation_reason,
        :state => MODERATED,
        :lastedited_by_user_id => user.id)
  end

  def hidden?
    self.state == HIDDEN
  end

  def duplicated?
    self.state == DUPLICATED
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
    absolute_negative = (
        negative_valorations - positive_valorations - neutral_valorations)
    if absolute_negative >= NEGATIVE_VALORATIONS_TO_HIDE && self.visible?
      self.update_attributes(:state => HIDDEN)
    elsif absolute_negative < NEGATIVE_VALORATIONS_TO_HIDE && self.hidden?
      self.update_attributes(:state => VISIBLE)
    end
  end

  def top_comments_valorations_type
    counts = User.db_query(
        "SELECT comments_valorations_type_id,
           COUNT(*) as cnt
         FROM comments_valorations
         WHERE comment_id = #{self.id}
         GROUP BY comments_valorations_type_id
         ORDER BY cnt DESC
         LIMIT 1")
    if counts.size > 0
      return CommentsValorationsType.find(
          counts[0]['comments_valorations_type_id'].to_i)
    end
  end

  def regenerate_ne_references
    NeReference.find(
        :all,
        :conditions => ["referencer_class = 'Comment' AND referencer_id = ?",
                        self.id]).each { |ne| ne.destroy }

    ne_refs = []
    users, references = extract_ne_references
    references.each do |ref|
      ne_refs << NeReference.create({
          :entity_class => users[ref][0][0],
          :entity_id => users[ref][0][1],
          :referencer_class => 'Comment',
          :referencer_id => self.id,
          :referenced_on => self.created_on,
      })
    end
    ne_refs
  end

  def schedule_image_parsing
    self.delay.download_remotes
  end

  def schedule_ne_references_calculation
    if self.comment_changed?
      self.delay.regenerate_ne_references
      self.delay.update_replies_notifications(self.comment_was)
      self.delay.update_last_comment_on
    end
  end

  def update_last_comment_on
    GlobalVars.update_var("last_comment_on", self.updated_on)
    if self.content.portal
      self.content.portal.update_attribute(:last_comment_on, self.updated_on)
    end
  end

  # Accepts an unformatized string and returns replied users.
  def extract_replied_users(text)
    text = Formatting.comment_without_quoted_text(text)
    replied_users = []
    text.scan(/\[(fullquote|quote)=([0-9]+)\]/).uniq.each do |m|
      replied_comment = Comment.karma_eligible.find_by_position(
          m[1].to_i, self.content)
      next if replied_comment.nil?
      replied_users << replied_comment.user_id
    end
    replied_users.uniq
  end

  def self.find_by_position(position, content)
    return if position < 1 || position > 10000000
    content.comments.find(
        :first,
        :conditions => "deleted = 'f'",
        :order => 'created_on',
        :limit => 1,
        :offset => position - 1)
  end

  def update_replies_notifications(old_comment_was)
    if old_comment_was
      # We unformatize because we look for [quote=<id>] tags
      replied_users_was = self.extract_replied_users(
          Formatting.comment_with_expanded_short_replies(old_comment_was, self))
    else
      replied_users_was = []
    end
    replied_users_is = self.extract_replied_users(
        Formatting.comment_with_expanded_short_replies(self.comment, self))

    replied_users_is -= [self.user_id]
    replied_users_was -= [self.user_id]

    return if replied_users_was.size == 0 && replied_users_is.size == 0

    users_gone = replied_users_was - replied_users_is
    new_users = replied_users_is - replied_users_was

    users_gone.each do |user_id|
      replied_user = User.find(user_id)
      next if replied_user.pref_radar_notifications.to_i != 1
      notification = replied_user.notifications.with_type(
          Notification::COMMENT_REFERENCE_IN_COMMENT).find(
              :first, :conditions => ["data = ?", self.id.to_s])
      notification.destroy if notification
    end

    new_users.each do |user_id|
      replied_user = User.find(user_id)
      next if replied_user.pref_radar_notifications.to_i != 1
      notification = replied_user.notifications.create({
          :type_id => Notification::COMMENT_REFERENCE_IN_COMMENT,
          :description => (
              "<a href=\"#{Routing.gmurl(self.user)}\">#{self.user.login}</a>
              te ha respondido en <a href=\"#{Routing.gmurl(self)}\">este
              comentario</a> a <strong><a href=\"#{Routing.gmurl(self.content)}\">#{self.content.name}</a></strong>."),
          :data => self.id.to_s,
      })
    end
  end

  # TODO(slnc): PERF calculate this on comment creation and store it in the
  # object.
  def position_in_content
    self.content.comments.count(
        :conditions => ["created_on < ?", self.created_on]) + 1
  end

  def download_remotes
    new_t = Cms.download_and_rewrite_bb_imgs(
        self.comment, "comments/#{self.id % 1000}/#{self.id % 100}")
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
    # update last_commented_on
    u = self.user
    last_comment = u.comments.karma_eligible.find(
        :first, :order => 'created_on DESC')
    u.lastcommented_on = last_comment ? last_comment.created_on : nil
    u.save

    # update counters
    User.decrement_counter('comments_count', self.user_id)
    Content.decrement_counter('comments_count', self.content_id)
    self.content.terms.each do |t|
      t.recalculate_counters
    end
    self.content.real_content.class.decrement_counter(
        'cache_comments_count', self.content.real_content.id)

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
    self.user.update_attributes(:lastcommented_on => self.created_on)
    self.delay.notify_trackers
  end

  def notify_trackers
    self.content.tracker_items.find(:all, :conditions => 'is_tracked = \'t\'', :include => [:user]).each do |t|
      u = t.user
      if u.id != self.user_id and u.notifications_trackerupdates and (t.notification_sent_on.nil? or t.lastseen_on > t.notification_sent_on) then
        NotificationEmail.trackerupdate(
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
      # en caso de que no haya nadie popular
      max_friends = User.most_friends(1)[:friends] rescue 1
      ukp = user.karma_points
      ukp = 1.1 if ukp < 1.1

      karma_score = Math.log10(ukp) / Math.log10(max_karma)
      friends_score = user.friends_count / (max_friends)
      w = (karma_score + friends_score) / 2.0

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

  def can_edit_comment?(user, saving=false)
    return false if user.nil?

    # If author is editing his comment we increase the limit to 30 min instead
    # of 15min.
    author_max_secs = Time.now - 60 * (saving ? 30 : 15)
    user.id == self.user.id && self.created_on > author_max_secs
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

  def report_violation(user, moderation_reason)
    org = Organizations.find_by_content(self)

    if !Comment.moderation_reason_valid?(moderation_reason)
      self.errors.add("state", "Razón de moderación inválida")
      return
    end

    if org
      if org.class.name == 'Faction'
        ttype = :faction_comment_report
      else
        ttype = :bazar_district_comment_report
      end
      scope = org.id
    else
      ttype = :general_comment_report
      scope = nil
    end

    sl = Alert.create({
      :scope => scope,
      :type_id => Alert::TYPES[ttype],
      :data => {:moderation_reason => moderation_reason},
      :reporter_user_id => user.id,
      :entity_id => self.id,
      :headline => (
          "#{Cms.faction_favicon(self.content.real_content)} <strong>
          <a href=\"#{Routing.url_for_content_onlyurl(self.content.real_content)}?page=#{self.comment_page}#comment#{self.id}\">#{self.id}</a></strong>
          (<a href=\"#{Routing.gmurl(self.user)}\">#{self.user.login}</a>) reportado #{Comment::MODERATION_REASONS_TO_SYM[moderation_reason]} por <a href=\"#{Routing.gmurl(user)}\">#{user.login}</a>"),
    })

    if sl.new_record?
      self.errors.add("state", sl.errors.full_messages_html)
      return
    end
  end

  private
  def extract_ne_references
    users = {}
    User.db_query(
        "SELECT id,
           LOWER(login) as login
         FROM users
         WHERE login_is_ne_unfriendly = 'f'").each do |dbu|
      users[dbu['login']] ||= []
      users[dbu['login']] << ['User', dbu['id'].to_i]
    end

    User.db_query(
        "SELECT user_id,
           LOWER(old_login) AS old_login
         FROM user_login_changes").each do |dbu|
      users[dbu['old_login']] ||= []
      users[dbu['old_login']] << ['User', dbu['user_id'].to_i]
    end

    User.db_query("SELECT id, LOWER(tag) AS tag FROM clans").each do |dbu|
      users[dbu['tag']] ||= []
      users[dbu['tag']]<< ['Clan', dbu['id'].to_i]
    end

    dirty_references = self.comment.gsub("@", " ").slnc_tokenize & users.keys
    # TODO(slnc): this doesn't work with all logins, we need to restrict and
    # upgrade logins to remove unsupported chars (OLD_LOGIN_REGEXP).
    clean_references = self.comment.downcase.scan(
        Regexp.new("\s@#{User::LOGIN_REGEXP}")).flatten

    referenced_names = (dirty_references + clean_references).uniq.sort
    entity_info = {}
    referenced_names.clone.each do |name|
      if !users.include?(name)
        referenced_names.delete(name)
        # @nick mention for a nonexistent nick
        next
      end
      entity_info[name] = users.fetch(name)
    end
    [entity_info, referenced_names]
  end
end
