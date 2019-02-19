({
  setLoading: function (component, isLoading) {
    var event = component.getEvent('loadingEvent');
    if (event) {
      event.setParams({
        isLoading: isLoading === true
      });
      event.fire();
    }
  },

  showToast: function (component, message, mode) {
    var event = component.getEvent('toastEvent');
    if (event) {
      event.setParams({
        show: true, message: message, mode: mode
      });
      event.fire();
    }
  },

  hideToast: function (component) {
    var event = component.getEvent('toastEvent');
    if (event) {
      event.setParams({
        show: false
      });
      event.fire();
    }
  },

  getErrorMessage: function (response) {
    var message = '';
    if (response) {
      var errors = response.getError();
      message = errors;
      if (Array.isArray(errors) && errors.length > 0) {
        message = errors[0].message;
      }
    }
    return message;
  },

  invokeAction: function (component, action, params, onSuccess, onError, onComplete) {
    this.hideToast(component);
    this.setLoading(component, true);
    if (action) {
      if (params) action.setParams(params);
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          if (onSuccess) onSuccess(response.getReturnValue());
        } else {
          this.showToast(component, this.getErrorMessage(response), 'error');
          if (onError) onError(response.getError());
        }
        this.setLoading(component, false);
        if (onComplete) onComplete(response);
      });
      $A.enqueueAction(action);
    }
  }
});
