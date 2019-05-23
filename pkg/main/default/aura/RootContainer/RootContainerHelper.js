({
  setLoading: function (component, isLoading) {
    if (component && component.isValid()) {
      var dsLoading = component.find('ds-loading') || component.getSuper().find('ds-loading');
      if (dsLoading) {
        isLoading === true ? dsLoading.show() : dsLoading.hide();
      }
    }
  },

  _getToast: function (component) {
    if (!component || !component.isValid()) return null;
    return component.find('ds-toast') || component.getSuper().find('ds-toast');
  },

  showToast: function (component, message, mode) {
    var toast = this._getToast(component);
    if (toast) {
      toast.set('v.message', message);
      toast.set('v.mode', mode);
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

  _cloneAction: function (component, action) {
    var result = null;
    if (component && component.isValid() && action) {
      result = component.get('c.' + action.getName());
    }
    return result;
  },

  _invokeAction: function (action, params, onSuccess, onError, onComplete) {
    if (action) {
      if (params) action.setParams(params);
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS' && onSuccess) {
          onSuccess(response.getReturnValue());
        } else if (onError) {
          onError(response.getError(), this.getErrorMessage(response));
        }
        if (onComplete) onComplete(response);
      });
      $A.enqueueAction(action);
    }
  },

  invokeAction: function (component, action, params, onSuccess, onError, onComplete) {
    if (component && component.isValid()) {
      var self = this;

      this.hideToast(component);
      this.setLoading(component, true);

      var setError = function (error, message) {
        self.showToast(component, message, 'error');
        if (onError) onError(error, message);
      };

      var setComplete = function (response) {
        self.setLoading(component, false);
        if (onComplete) onComplete(response);
      };

      this._invokeAction(action, params, onSuccess, setError, setComplete);
    }
  }
});
