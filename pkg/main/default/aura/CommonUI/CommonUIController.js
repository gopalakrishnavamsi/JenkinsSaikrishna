({
  onToast: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
      if (params.mode === 'success') {
        setTimeout($A.getCallback(function () {
          helper.hideToast(component);
        }), 3000);
      }
    } else {
      helper.hideToast(component);
    }
  },

  onLoading: function (component, event, helper) {
    var params = event.getParams();
    helper.setLoading(component, params && params.isLoading === true);
  }
});
