({
  onInitialize: function (component, event, helper) {
    helper.getState(component, event, helper);
  },

  reloadSetup: function (component, event, helper) {
    helper.getState(component, event, helper);
  },

  handleToastEvent: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode, params.toastPayload);
      if (params.mode === 'success') {
        setTimeout($A.getCallback(function () {
          helper.hideToast(component);
        }), 3000);
      }
    } else {
      helper.hideToast(component);
    }
  },

  triggerLogout: function (component, event, helper) {
    helper.triggerLogout(component, event, helper);
  }

});
