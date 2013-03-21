//= require jquery
//= require jquery_ujs
//= require_tree ./external
//= require gm
//= require_tree ./modules/global
//= require_tree ./legacy

$(document).ready(function() {
  var modules = Gm.getModules();
  for (var i in modules) {
    modules[i].FullPageInit();
  }

  /*
   * TODO(slnc): temporarily disabled until we can make sure that calls to
   * refresh outside boxes are called after page refresh via pjax.
  $('body').pjax('a', {container: "#ccontent"})
    .on('pjax:start', function() { $('#loading').show() })
    .on('pjax:end', function() {
      $('#loading').hide();
      var modules = Gm.getModules();
      for (var i in modules) {
        modules[i].ContentInit();
      }
    });
    */
  $('.bbeditor').each(function() {
    $(this).bbcodeeditor({
      back: $('.back'),
      back_disable: 'btn back_disable',
      blist: $('.blist'),
      bold: $('.bold'),
      code: $('.code'),
      dsize: $('.dsize'),
      forward: $('.forward'),
      forward_disable: 'btn forward_disable',
      image: $('.btn.image'),
      italic:  $('.italic'),
      link: $('.link'),
      nlist: $('.nlist'),
      quote: $('.quote'),
      usize: $('.usize'),
    });
  });

  $('.elastic').elastic();

  $('.autocomplete-me').each(function() {
    var t = $(this);
    if (t.attr('data-autocomplete-click')) {
      t.attr('autocomplete', 'off').autocomplete(t.attr('data-autocomplete-url'), {
        click_fn: function(li, textInput, autocomplete) {
          eval(t.attr('data-autocomplete-click') + '(li, textInput, autocomplete);');
        },
      });
    } else {
      t.attr('autocomplete', 'off').autocomplete(
        t.attr('data-autocomplete-url'), {
          before: function(textInput, text, settings) {
            eval(t.attr('data-autocomplete-before') +
                 '(textInput, text, settings)');
          }
        });
    }
  });

  $('.confirm-click').unbind('click').click(function() {
    return confirm('¿Estás seguro?');
  });

  $('#post_login').focus();

  $('.new-content-selector').unbind('click').click(open_new_content_selector);
  $('.new-content-selector a').unbind('click').click(close_new_content_selector);
  $('.init-session').unbind('click').click(function() {
    $('#login-box').removeClass('hidden');
    $(this).hide();
    return false;
  });

  $('.open-popup-on-click').unbind('click').click(function() {
    $('#'+$(this).data('popup-id')).toggleClass('hidden');
    $('body').click(HideAllPopups);
    return false;
  });

  function HideAllPopups() {
    $('.popup').addClass('hidden');
    $('body').unbind('click', HideAllPopups);
  }
});
