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
    var isLoading = params && params.isLoading && !params.isAuthorizeEvent;
    helper.setLoading(component, isLoading);
  },

  onUserEvent: function (component, event, helper) {
    event.stopPropagation();
    var params = event.getParams();
    if ($A.util.isUndefinedOrNull(params)) return;

    if (params.action === 'addProperties') {
      helper.addEventProperties(component, params.properties);
    } else if (params.action === 'time') {
      helper.timeEvent(component, params.name);
    } else { // track
      switch (params.status) {
        case 'error':
          helper.trackError(params.name, params.properties || {}, params.error || '');
          break;
        case 'canceled':
          helper.trackCancel(params.name, params.properties || {});
          break;
        case 'success':
        default:
          helper.trackSuccess(params.name, params.properties || {});
          break;
      }
    }
  }
});
