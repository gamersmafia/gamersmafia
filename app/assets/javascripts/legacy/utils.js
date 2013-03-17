/**
 * TODO(slnc): legacy move this out
 */

/**
 * Realiza diversas tareas de configuración de la página.
 * @param {Object} user_is_authed
 * @param {Object} contents
 */
function cfgPage(user_is_authed, contents, controller, action, model_id,
    newsessid, abtest, ads_shown) {
  Gm.Slnc.setupAdClicks();
  pageTracker = st.getTracker();
  if (newsessid)
    pageTracker.setVar('_xnvi', newsessid);
  pageTracker.initData();
  pageTracker.setVar('_xc', controller);
  pageTracker.setVar('_xa', action);
  pageTracker.setVar('_xmi', model_id);

  if (ads_shown)
    pageTracker.setVar('_xad', ads_shown);

  if (abtest)
    pageTracker.setVar('_xab', abtest);

  pageTracker.trackPageview(user_is_authed, contents);

  // Menu setup
  $('#smenu .second-level').hide();
  $('#smenu .third-level').hide();

  $('#show-menu').click(function() {
    if ($(this).hasClass('shown')) {
      $('#thesaw').stop().animate({
        'width' : '0'
      }, 100);
      $(this).removeClass('shown');
    } else {
      $('#thesaw').stop().animate({
        'width' : '615px'
      }, 100);
      $(this).addClass('shown');
    }
  });

  $('div.comment').hover(function() {
    Gm.Utils.highlightComment($(this).attr('id'));
  });

  $('.hidden-comments-warning a').click(function() {
    return Gm.Utils.showAllHiddenComments();
  });

  $('.comment-textarea .btn-comment').click(PreventDuplicatedClicks);
}

function PreventDuplicatedClicks() {
  var now = (new Date()).valueOf();

  // Ignore clicks on Comentar that take place within the same minute
  if ((now - Gm.Comments.last_click_on_comment) < 60 * 1000) {
    return false;
  }
  Gm.Comments.last_click_on_comment = now;
  return true;
}

function report_comment(comment_id) {
  $.facebox({
    ajax : '/site/report_comment_form/' + comment_id
  });
  return false;
}

function new_message(user_id) {
  $.facebox({
    ajax : '/cuenta/mensajes/new?id=' + user_id
  });
  return false;
}

function report_user(user_id) {
  $.facebox({
    ajax : '/site/report_user_form/' + user_id
  });
  return false;
}

function report_content(content_id) {
  $.facebox({
    ajax : '/site/report_content_form/' + content_id
  });
  return false;
}

function close_content(content_id) {
  $.facebox({
    ajax : '/site/close_content_form/' + content_id
  });
  return false;
}

function disable_rating_controls() {
  for(key in comments) {
    var dEl = $('#moderate-comments-opener-rating' + key);
    if (dEl && dEl.html() == 'Ninguna')
      $('#moderate-comments-opener' + key).hide();
  }
}

function check_comments_controls(
    user_id,
    user_last_visited_on,
    unix_now,
    comments_ratings,
    remaining_slots,
    first_time_content,
    do_autoscroll,
    do_show_all_comments,
    can_rate_comments_up,
    can_rate_comments_down,
    can_report_comments) {
  // NO calcular tiempo unix_now por el cliente, es una caja de pandora
  var scroll_to_comment;
  // contiene el elemento al que hacer scroll
  for (key in comments) {
    var comment_div = $('#comment' + key);
    if (can_rate_comments_up && comments[key][1] != user_id) {
      // Puede valorarlo
      if (comments_ratings[key] != undefined)
        $('#moderate-comments-opener-rating' + key).html(comments_ratings[key]);

      if ($('#moderate-comments-opener' + key) != undefined &&
          (comments_ratings[key] != undefined || remaining_slots > 0)) {
        // necesario por un error js raro
        $('#moderate-comments-opener' + key).show();
      }

      if (!can_rate_comments_down) {
        $('#moderate-comments-opener' + key + ' .negative').hide();
      }
    } else {
      // TODO(slnc): hack, por culpa de orden de importación de reglas CSS
      // está el div de valoración se está mostrando siempre. Vamos a eliminar
      // todo este código con Pollo Suicida así que corrigiendo el hack con otro
      // hack.
      $('#moderate-comments-opener' + key).hide();
    }

    if (comments[key][0] > user_last_visited_on && comments[key][1] != user_id) {
      comment_div.find('.comment-header').addClass('unread-item');
      // hacemos scroll excepto que sea primera pag y primer comment
      if ((!first_time_content) && !scroll_to_comment) {
        scroll_to_comment = $('#comment' + key);
      }
    }
    cur_is_first = false;

    if ((comments[key][1] == user_id &&
         comments[key][0] > unix_now - 60 * 15)) {
      $('#comment' + key + 'editlink').removeClass('hidden');
    }

    if (can_report_comments) {
      var rpc = $('#report-comments' + key);
      if (rpc) {
        rpc.removeClass('hidden');
      }
    }
  }

  if (do_show_all_comments == "1") {
    Gm.Utils.showAllHiddenComments();
  }

  if (do_autoscroll == '1' && scroll_to_comment && !first_time_content) {
    $(document).ready(function() {
      $(window).scrollTo(scroll_to_comment, 750, {
        easing : 'swing',
        queue : true,
        axis : 'y',
        offset : -60
      });
    });
  }
}

function open_new_content_selector() {
  $('#new-content-selector').removeClass('hidden');
  return false;
}

function close_new_content_selector() {
  $('#new-content-selector').addClass('hidden');
  return false;
}

function mark_new(item_id, base) {
  $("#" + base + item_id).addClass('updated');
}

function mark_visited(item_id) {
  $('.content' + item_id).removeClass('new').removeClass('unread-item');
}

function mailto(p1) {
  var p2 = 'gamersmafia';
  document.location = 'mailto:' + p1 + '@' + p2 + '.com?Subject=Email sobre Gamersmafia';
}

function skinselector(val) {
  if (val == 'mis-skins')
    document.location = '/cuenta/skins';
  else
    Gm.Slnc.setPref('skin', val);
}

/**
 * Used to call function f with given arguments
 * BindArguments(setactivewmsecondary, masterSections[i]);
 * @param {Object} fn
 */
function BindArguments(fn) {
  var args = [];
  for(var n = 1; n < arguments.length; n++)args.push(arguments[n]);
  return function() {
    return fn.apply(this, args);
  };
}

function switch_block_visi(block_base) {
  var max = block_base + 'max';
  var min = block_base + 'min';

  if ($('#' + min).css('display') != 'none') {
    $('#' + min).hide();
    $('#' + max).show();
  } else {
    $('#' + max).hide();
    $('#' + min).show();
  }
  return false;
}

function closeFacebox() {
  $(document).trigger('close.facebox');
  return false;
}
