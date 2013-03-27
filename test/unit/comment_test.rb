# -*- encoding : utf-8 -*-
require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  COPYRIGHT = Comment::MODERATION_REASONS[:copyright]

  test "should update global_vars on creation" do
    last = GlobalVars.get_var("last_comment_on")
    c1 = create_a_comment(:comment => "hola guapo")
    assert_equal c1.updated_on.to_i, GlobalVars.get_var("last_comment_on").to_time.to_i
  end

  test "should update portal last_comment_on on creation" do
    content1 = Content.find(1)
    last = content1.portal.last_comment_on
    c1 = create_a_comment(:comment => "hola guapo", :content_id => content1.id)
    content1.reload
    assert_equal c1.updated_on.to_i, content1.portal.last_comment_on.to_i
  end

  test "top_comments_valorations_type" do
    c1 = create_a_comment(:comment => "hola guapo")
    c1.comments_valorations.create({
        :user_id => 1,
        :comments_valorations_type_id => 1,
        :weight => 0.3,
    })
    assert_equal 1, c1.top_comments_valorations_type.id
  end

  test "expand_comment_references" do
    c1 = create_a_comment(:comment => "hola guapo")
    c2 = create_a_comment(:comment => "##{c1.position_in_content} no, eres feo")
    assert_equal "[fullquote=2][b]#2 [~panzer][/b]:\n\nhola guapo[/fullquote] no, eres feo", Formatting.comment_with_expanded_short_replies(c2.comment, c2)
  end

  test "expand_comment_references with multiple saves" do
    c1 = create_a_comment(:comment => "hola guapo")
    c2 = create_a_comment(:comment => "##{c1.position_in_content} no, eres feo")
    c2.update_attribute(:comment, "#{c2.comment} y más!")
    Formatting.comment_with_expanded_short_replies(c2.comment, c2)
    assert_equal "[fullquote=2][b]#2 [~panzer][/b]:\n\nhola guapo[/fullquote] no, eres feo y más!", Formatting.comment_with_expanded_short_replies(c2.comment, c2)
  end

  test "dont_expand_comment_references within quotes" do
    c1 = create_a_comment(:comment => "hola guapo")
    c2 = create_a_comment(:comment => "##{c1.position_in_content} no, eres feo")
    c3 = create_a_comment(:comment => "##{c2.position_in_content} holaaa")
    assert_equal "[fullquote=3][b]#3 [~panzer][/b]:\n\n#2 no, eres feo[/fullquote] holaaa", Formatting.comment_with_expanded_short_replies(c3.comment, c3)
  end

  test "moderate should work" do
    comment = create_a_comment
    comment.moderate(User.find(1), COPYRIGHT)
    assert_equal 1, comment.lastedited_by_user_id
    assert_equal Comment::MODERATED, comment.state
    assert_equal COPYRIGHT, comment.moderation_reason
  end

  test "don't moderate self" do
    comment = create_a_comment
    assert_raises(RuntimeError) do
      comment.moderate(comment.user, COPYRIGHT)
    end
  end

  test "don't moderate twice" do
    comment = create_a_comment
    comment.moderate(User.find(1), COPYRIGHT)
    assert_raises(RuntimeError) do
      comment.moderate(User.find(1), COPYRIGHT)
    end
  end

  test "superadmin reporting a comment triggers automatic removal" do
    u1 = User.find(1)
    comment = create_a_comment
    comment.report_violation(u1, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, u1)
  end

  test "normal user reporting a comment does not trigger automatic removal" do
    user = User.find(4)
    comment = create_a_comment
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_not_moderated(comment)
  end

  test "capo reporting a comment triggers automatic removal" do
    user = User.find(4)
    give_skill(user.id, "Capo")
    comment = create_a_comment
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "faction moderator reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment
    user.users_skills.create(
        :role => "Moderator",
        :role_data => comment.content.my_faction.id.to_s)
    assert user.is_moderator?
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "faction boss reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment
    faction = comment.content.my_faction
    user.users_skills.create(
        :role => "Boss",
        :role_data => faction.id.to_s)
    assert faction.user_is_moderator(user)
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "don reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment(:content_id => 1113)
    bazar_district = comment.content.bazar_district
    user.users_skills.create(
        :role => "Don",
        :role_data => bazar_district.id.to_s)
    assert bazar_district.user_is_moderator(user)
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  test "sicario reporting a comment triggers automatic removal" do
    user = User.find(4)
    comment = create_a_comment(:content_id => 1113)
    bazar_district = comment.content.bazar_district
    user.users_skills.create(
        :role => "Sicario",
        :role_data => bazar_district.id.to_s)
    assert bazar_district.user_is_moderator(user)
    comment.report_violation(user, COPYRIGHT)
    comment.reload
    assert_comment_moderated(comment, user)
  end

  def assert_comment_not_moderated(comment)
    assert_not_equal Comment::MODERATED, comment.state
  end

  def assert_comment_moderated(comment, moderator)
    assert_equal Comment::MODERATED, comment.state
    assert_equal moderator.id, comment.lastedited_by_user_id
  end

  test "refered_people_should_work" do
    c = create_a_comment
    assert c.save
    references = c.regenerate_ne_references
    assert_equal 'User', references[0].entity_class
    assert_equal 'Comment', references[0].referencer_class
    assert_equal 2, references[0].entity_id
    assert_equal c.id, references[0].referencer_id

    assert_equal references[0].id, c.content.ne_references[0].id
    assert_equal references[0].id, User.find(2).ne_references[0].id
  end

  test "regenerate_ne_references should work with invalid nick mentions" do
    c = create_a_comment(:comment => "@dios no existe")
    assert_difference("NeReference.count", 0) do
      assert c.save
      references = c.regenerate_ne_references
    end
  end

  test "should_create_comment_if_valid" do
    content = Content.find(1)
    content.url = nil
    content.portal_id = nil
    Routing.gmurl(content)
    assert_not_nil content.portal_id
    c = Comment.new({
        :user_id => 1,
        :comment => 'hola mundo!',
        :content_id => 1,
        :host => '127.0.0.1',
    })
    assert c.save
    c.reload
    assert_not_nil c.portal_id
    c.reload
    u = User.find(1)
    assert_equal u.lastcommented_on.to_i, c.created_on.to_i
  end

  test "should_properly_save_copy_when_being_moderated" do
    c = Comment.new({:user_id => 1, :comment => 'u1', :content_id => 1, :host => '127.0.0.1'})
    assert_equal true, c.save
    assert_nil c.lastowner_version
    assert_nil c.lastedited_by_user_id
    assert c.update_attributes(:lastedited_by_user_id => 2, :comment => 'u2')
    assert_equal 'u1', c.lastowner_version
    assert_equal 2, c.lastedited_by_user_id

    # lo edita otra vez el mismo moderadors
    assert c.update_attributes(:lastedited_by_user_id => 2, :comment => 'u22')
    assert_equal 'u1', c.lastowner_version
    assert_equal 2, c.lastedited_by_user_id

    # ahora lo edita un segundo moderador
    assert c.update_attributes(:lastedited_by_user_id => 3, :comment => 'u3')
    assert_equal 'u1', c.lastowner_version
    assert_equal 3, c.lastedited_by_user_id

    # ahora lo vuelve a editar el propietario
    assert c.update_attributes(:lastedited_by_user_id => 1, :comment => 'u1b')
    assert_nil c.lastowner_version
    assert_equal 1, c.lastedited_by_user_id
  end

  test "should_not_create_comment_if_duplicated" do
  end

  test "should_properly_update_lastcommented_on_from_author_when_destroying_comments" do
    # caso 1: existen comentarios anteriormente
    test_should_create_comment_if_valid
    c2 = Comment.new({
        :user_id => 1,
        :comment => 'hola mundo2!',
        :content_id => 1,
        :host => '127.0.0.1',
    })
    assert_equal true, c2.save
    c2.reload
    assert_not_nil c2.mark_as_deleted
    u = User.find(1)
    last_c = Comment.find(
        :first, :conditions => 'user_id = 1', :order => 'id DESC')
    assert_equal u.lastcommented_on.to_i, last_c.created_on.to_i

    # caso 2: no existen comentarios anteriormente
    Comment.find(:all, :conditions => 'user_id = 1').each do |comment|
      comment.mark_as_deleted
    end
    u.reload
    assert_nil u.lastcommented_on
  end

  test "extract_ne_references" do
    comment = Comment.new({
      :comment => "@MRALARIKO hello NAGATO. I love you! I love you too @MRACHMED!!!
      I don't love @mrman. Your email is mrman@mrman.com",
    })
    assert_equal [{
      "mrachmed" => [["User", 58]],
      "mralariko" => [["User", 3]],
      "mrman" => [["User", 53]],
      "nagato" => [["User", 54]],
    },
    ["mrachmed", "mralariko", "mrman", "nagato"]], comment.send(:extract_ne_references)
  end

  test "should not send 2 notifications for multiple refs or editions" do
    comment = Comment.new({
      :comment => "hello nagato. I love you! I love you too @mrachmed @nagato!!!
      I don't love @mrman",
      :content_id => 1,
      :user_id => 1,
      :host => '127.0.0.1',
    })

    u1 = User.find_by_login("nagato")
    sold_radar = self.buy_product(u1, SoldRadar)
    assert_difference("u1.notifications.count") do
      assert comment.save
      assert comment.save
    end
  end

  test "append_update" do
    c1 = Comment.find(1)
    prev = c1.comment
    c1.append_update("bar")
    assert_equal "#{prev}\n\n[b]Editado[/b]: bar", c1.comment
  end

  test "images_to_comment_url" do
    assert_equal "[img]/foo.jpeg[/img]",
                 Comment.images_to_comment(["/foo.jpeg\r"], User.find(1))
  end

  test "images_to_comment_b64" do
    output = Comment.images_to_comment(
        ["data:image/jpeg;base64,foo"], User.find(1))
    assert /^\[img\]\/storage.+\.jpeg\[\/img\]/ =~ output
  end

  test "notify when someone replies to their comment" do
    u1 = User.find(1)
    u2 = User.find(2)
    u1.pref_radar_notifications = 1
    c1 = create_a_comment({:user_id => u1.id})
    assert_difference("u1.notifications.count") do
      c2 = create_a_comment({
          :user_id => u2.id,
          :comment => "##{c1.position_in_content} feo",
      })
    end
  end

  test "remove notification when reference removed" do
    u1 = User.find(1)
    u2 = User.find(2)
    u1.pref_radar_notifications = 1
    c1 = create_a_comment({:user_id => u1.id})
    c2 = create_a_comment({
        :user_id => u2.id,
        :comment => "##{c1.position_in_content} feo",
    })
    assert_difference("u1.notifications.count", -1) do
      c2.update_attribute(:comment, "feo")
    end
  end

  test "extract_replied_users" do
    c1 = create_a_comment
    c2 = create_a_comment(
        :comment => "##{c1.position_in_content} feo")
    assert_equal [c1.user_id], c2.extract_replied_users(Formatting.comment_with_expanded_short_replies(c2.comment, c2))
  end

  test "extract_replied_users with nested quotes" do
    c1 = create_a_comment
    c2 = create_a_comment(
        :comment => "##{c1.position_in_content} feo", :user_id => 2)
    c3 = create_a_comment(
        :comment => "##{c2.position_in_content} feo", :user_id => 3)
    assert_equal [c2.user_id], c3.extract_replied_users(Formatting.comment_with_expanded_short_replies(c3.comment, c3))
  end

  test "extract_replied_users with @ mention in quote" do
    c1 = create_a_comment(:comment => "@panzer4 hola", :user_id => 2)
    c2 = create_a_comment(:comment => "##{c1.position_in_content} feo", :user_id => 3)
    assert_equal [c1.user_id], c2.extract_replied_users(Formatting.comment_with_expanded_short_replies(c2.comment, c2))
  end

  test "referring to yourself shouldnt create a notification" do
    u1 = User.find(1)
    u1.pref_radar_notifications = 1
    c1 = create_a_comment({:user_id => u1.id})
    assert_difference("u1.notifications.count", 0) do
      c2 = create_a_comment({
          :user_id => u1.id,
          :comment => "##{c1.position_in_content} feo",
      })
    end
  end
end
