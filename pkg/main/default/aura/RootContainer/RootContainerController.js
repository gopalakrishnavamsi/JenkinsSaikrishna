({
  onToast: function (component, event, helper) {
    event.stopPropagation();
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
    } else {
      helper.hideToast(component);
    }
  },

  onLoading: function (component, event, helper) {
    event.stopPropagation();
    var params = event.getParams();
    var showloadingSpinner = params && params.isLoading && !params.isAuthorizeEvent;
    helper.setLoading(component, showloadingSpinner);
  }
});
