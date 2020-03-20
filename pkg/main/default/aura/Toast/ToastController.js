({
  close: function (component) {
    component.set('v.showToast', false);
  },

  show: function (component, event) {
    var args = event.getParam('arguments');
    if (!$A.util.isEmpty(args)) {
      var mode = args['mode'];
      component.set('v.mode', mode);
      component.set('v.message', stringUtils.formatHtml(args['message']));
      component.set('v.detail', stringUtils.formatHtml(args['detail']));
      component.set('v.showToast', true);
      if (mode === 'success') {
        setTimeout($A.getCallback(function () {
          component.set('v.showToast', false);
        }), 3000);
      }
    }
  }
});
