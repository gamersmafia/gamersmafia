Gm.Utils = function() {
  return {
    name: 'Utils',

    ContentInit: function() {
      $('form').each(function() {
        var f = $(this);
        if (f.attr('data-remote-on-success-update') != '') {
          f.on('ajax:complete', function(event, xhr, status) {
            $(f.attr('data-remote-on-success-update')).html(xhr.responseText);
          });
        }
      });

      $('a[data-reveal-selector]').click(function() {
        $($(this).attr('data-reveal-selector')).toggle();
        return false;
      });

      $('pre').litelighter({
          clone: false,
          style: 'light',
      });

      $('.ratebar').each(function() {
        $(this).find('.stars').click(function(e) {
          var url = (
            '/site/rate_content?content_rating[rating]=' +
            $(this).data("rating") + '&content_rating[content_id]=' +
            $(this).data("content-id"));

          $.get(url, function(data) {
            $(e.currentTarget).parent().html("Muchas gracias por tu valoración.");
          });
        });

        $(this).find('.stars').mousemove(function(e) {
          var cur = $(this);
          var parentOffset = cur.parent().offset();
          var relX = (e.pageX - parentOffset.left) / cur.width();
          if (relX < 0.1) {
            relX = 0.1;
          }

          var rating = Math.ceil(relX * 10);
          cur.data("rating", rating);

          var full = Math.floor(rating / 2.0);
          var half = rating % 2;
          var empty = 5 - full - half;

          var str = "";
          for (var i = 0; i < full; i++) {
            str += "&#xe000;"
          }
          for (var i = 0; i < half; i++) {
            str += "&#xe01b;"
          }
          for (var i = 0; i < empty; i++) {
            str += "&#xe045;"
          }

          cur.html(str);
        });
      });
    },

    FullPageInit: function() {
      this.ContentInit();
    },

    TagsAutocomplete: function(li, textInput, autocomplete) {
      textInput.before('<span class="tag">' + $(li).text() + '</span>');
      var valueInput = textInput.next();
      var oldValue = valueInput.val();
      if (oldValue) {
        oldValue += ',';
      }
      valueInput.val(oldValue + $(li).attr('value'));
      textInput.val('');
			$(li).parent().hide();
      textInput.focus();
    },

    setEntityTypeClassInterestAutocomplete: function(input, text, settings) {
      settings.parameters.entity_type_class = $('#entity_type_class').val();
    },

    rate_comment : function(comment_id, cvt_name, cvt_id) {
      $.get('/comments/rate?comment_id=' + comment_id + '&rate_id=' + cvt_id + '&redirto=' + document.location, function(data) {
        $('#moderate-comments-opener-rating' + comment_id).html(data);
      })
      $('#moderate-comments' + comment_id).hide();
      return false;
    },

    gototop : function() {
	if (jQuery.browser.msie && jQuery.browser.version == '6.0') {
            document.location = '#';
	} else{
	    $("body, html").animate({scrollTop: "0px"});
	});
      }
      return false;
    },
    /**
     * Resalta el comentario actual.
     * @param {string} id: id del comentario a resaltar.
     */
    highlightComment : function(id) {
      $('div.comment').addClass('inactive');
      $('#' + id).removeClass('inactive');
    },

    showAllHiddenComments : function() {
      $('.hidden-comments-warning').hide();
      $('.hidden-comments-indicator').hide();
      $('.comment.hidden').removeClass('hidden');
      return false;
    },

    form_sym_action : function(form_id, initial_str, new_str) {
      var f = document.getElementById(form_id);
      if (!f) {
        alert(form_id + ' not found');
        return;
      }

      f.action = f.action.replace(initial_str, new_str);
      f.submit();
    }
  }; // return
}();

Gm.registerModule(Gm.Utils);
