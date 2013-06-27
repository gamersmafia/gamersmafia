module CommentsHelper
  ADSENSE_COMMENTS_SNIPPET = <<-END
<div style="margin: 15px 0; padding-left: 120px;">
<script type="text/javascript"><!--
google_ad_client = "pub-6007823011396728";
google_ad_slot = "5381241906";
google_ad_width = 300;
google_ad_height = 250;
//-->
</script>
<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
</div>
  END

  def positive_negative_bar_for_comment(comment)
    count_negative = comment.comments_valorations.negative.count
    count_positive = comment.comments_valorations.positive.count
    count_neutral = comment.comments_valorations.neutral.count
    return '' if count_positive + count_negative == 0
    top_vote = comment.top_comments_valorations_type
    out = []
    out.append("(#{count_negative}") if count_negative > 0
    out.append(
        positive_negative_bar(count_negative, count_neutral, count_positive))
    out.append("(#{count_positive}") if count_positive > 0
    out.append(top_vote.name) if top_vote
    out.join(" ")
  end

  def comment_count(content)
    "<a href=\"#{gmurl(content)}#comments\">#{gm_icon("comment")} #{content.comments_count}</a>"
  end

  def adsense_comments
    if App.show_ads && !controller.no_ads && !(user_is_authed && Authorization.gets_less_ads?(@user))
      ADSENSE_COMMENTS_SNIPPET
    end
  end

  def check_hidden_comments(hidden_comments_count, hidden_comments_users)
    if hidden_comments_count > 0
      out = ["<div class=\"hidden-comments-indicator\">"]
      hidden_comments_users.each do |user|
        out << "#{avatar_img(user, :very_small)}"
      end
      out << ["</div>"]
      out.join(" ")
    end
  end

  def hidden_comments_count_toggler(hidden_comments_count)
    return unless hidden_comments_count > 0

    out = <<-END
<div class="infoinline hidden-comments-warning" style="text-align: right;">
  <a href="">Mostrar <strong>#{hidden_comments_count}</strong>
  #{pluralize_on_count("comentario", hidden_comments_count)}
  #{pluralize_on_count("oculto", hidden_comments_count)}</a>
</div>
      END
  end

  def get_comments(object)
    Comment.paginate({
        :page => params[:page],
        :per_page => Cms.comments_per_page,
        :conditions => ["deleted = 'f' AND content_id = ?",
                        object.unique_content.id],
        :order => 'comments.created_on asc',
        :include => :user
    })
  end

  def resolve_comments_page(object)
    if user_is_authed && !params[:page]
      params[:page] = Cms::page_to_show(@user, object, @object_lastseen_on)
    end

    if params[:page].nil? || params[:page].to_i < 1
      params[:page] = 1
    else
      params[:page] = params[:page].to_i
    end
  end

  ENTICING_IMAGES = [
      '009d48',
      '068b5b',
      '1108b2',
      '14826d',
      '21db24',
      '2bc937',
      '2d3058',
      '2e7ded',
      '334d5e',
      '73ec88',
      '74254',
      '7984ec',
      'e5cbc8',
      'ff0d19',
  ]
  def get_enticing_image
    ENTICING_IMAGES[Kernel.rand(ENTICING_IMAGES.size)]
  end
end
