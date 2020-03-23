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

  showToast: function (component, message, mode, detail) {
    var toast = this._getToast(component);
    if (toast) {
      toast.show(mode, message, detail);
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
  },

  invokeChainAction: function (component, action, params, onSuccess, onError, onComplete) {
    if (component && component.isValid()) {

      var setError = function (error, message) {
        if (onError) onError(error, message);
      };

      var setComplete = function (response) {
        if (onComplete) onComplete(response);
      };

      this._invokeAction(action, params, onSuccess, setError, setComplete);
    }
  },

  _getUserEvents: function (component) {
    if (!component || !component.isValid()) return null;
    return component.find('ds-user-events') || component.getSuper().find('ds-user-events');
  },

  addEventProperties: function (component, properties) {
    var userEvents = this._getUserEvents(component);
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    userEvents.addProperties(properties || {});
  },

  timeEvent: function (component, eventName) {
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    var userEvents = this._getUserEvents(component);
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    userEvents.time(eventName);
  },

  trackSuccess: function (component, eventName, properties) {
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    var userEvents = this._getUserEvents(component);
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    userEvents.success(eventName, properties || {});
  },

  trackError: function (component, eventName, properties, error) {
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    var userEvents = this._getUserEvents(component);
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    userEvents.error(eventName, properties || {}, error || '');
  },

  trackCancel: function (component, eventName, properties) {
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    var userEvents = this._getUserEvents(component);
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    userEvents.cancel(eventName, properties || {});
  }
});
