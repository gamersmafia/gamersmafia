var Gm = Gm || {};

Gm = function() {
  var registeredModules = [];

  return {
    getModules: function() {
      return registeredModules;
    },

    triggerContentInit: function() {
      var modules = Gm.getModules();
      for (var i in modules) {
        modules[i].FullPageInit();
      }
    },

    registerModule: function(module) {
      registeredModules.push(module);
    },

    showAlert: function(el, alertText) {
      var alertEl = el.find('.feedback.alert');
      if (alertEl.length == 0) {
        el.append('<div class="feedback alert f_sm"></div>');
        alertEl = el.find('.feedback.alert');
      }
      alertEl.html(alertText);
    },
  };
}();
