({
  setLoading: function (component, isLoading) {
    var dsLoading = component.find('ds-loading') || component.getSuper().find('ds-loading');
    if (dsLoading) {
      isLoading === true ? dsLoading.show() : dsLoading.hide();
    }
  },

  _getToast: function (component) {
    return component.find('ds-toast') || component.getSuper().find('ds-toast');
  },

  showToast: function (component, message, mode) {
    var toast = this._getToast(component);
    if (toast) {
      component.set('v.message', message);
      component.set('v.mode', mode);
      toast.show();
      if (mode === 'success') {
        setTimeout($A.getCallback(function () {
          toast.close();
        }), 3000);
      }
    }
  },

  hideToast: function (component) {
    var toast = this._getToast(component);
    if (toast) {
      toast.close();
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
    var self = this;
    this.hideToast(component);
    this.setLoading(component, true);
    if (action) {
      if (params) action.setParams(params);
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          if (onSuccess) onSuccess(response.getReturnValue());
        } else {
          self.showToast(component, this.getErrorMessage(response), 'error');
          if (onError) onError(response.getError());
        }
        self.setLoading(component, false);
        if (onComplete) onComplete(response);
      });
      $A.enqueueAction(action);
    }
  }
});
