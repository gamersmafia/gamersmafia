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

  def adsense_comments
    if App.show_ads && (!user_is_authed || @user.created_on > 1.year.ago)
      ADSENSE_COMMENTS_SNIPPET
    end
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

end