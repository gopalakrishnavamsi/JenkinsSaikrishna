({
  ACTIONUPDATE: 'update',
  SUCCESS: 'success',
  ERROR: 'error',
  createComponent: function (component, componentName, parameter, callback) {
    var _self = this;
    $A.createComponent(
      componentName,
      parameter,
      function (newComp, status) {
        if (status === 'SUCCESS') {
          callback.call(this, newComp);
        }
        else if (status === 'ERROR') {
          _self.fireToast(component, stringUtils.format($A.get('$Label.c.ComponentCreationFailed'), componentName), 'error');
        }
      });
  },

  callServer: function (component, serverMethod, params, callback, errorCallback) {
    var _self = this;
    var action = component.get(serverMethod);
    if (params) {
      action.setParams(params);
    }
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        callback.call(this, response.getReturnValue());
      } else if (state === 'ERROR') {
        var errors = response.getError();

        if (errors && errors[0] && errors[0].message) {
          _self.fireToast(component, errors[0].message, this.ERROR);
        }
        errorCallback.call(this, response.getError());

      }
    });
    $A.enqueueAction(action);
  },

  fireComponentEvent: function (component, eventName, attributes) {
    var _self = this;
    var componentEvent = component.getEvent(eventName);
    if (componentEvent) {
      componentEvent.setParams(attributes);
      componentEvent.fire();
    } else {
      _self.fireToast(component, stringUtils.format($A.get('$Label.c.NoEventFound'), eventName), this.ERROR);
    }
  },

  fireApplicationEvent: function (component, params, eventName) {
    var _self = this;
    var appEvent = $A.get('e.' + component.get('v.namespace') + ':' + eventName);
    if (appEvent) {
      appEvent.setParams(params);
      appEvent.fire();
    } else {
      _self.fireToast(component, stringUtils.format($A.get('$Label.c.NoEventFound'), eventName), this.ERROR);
    }
  },

  fireToast: function (component, title, variant) {
    this.fireApplicationEvent(component, {
      data: {
        title: title,
        variant: variant
      },
      toComponent: 'CLMSetupLayout',
      fromComponent: 'CLMUtility',
      type: 'toast'
    }, 'CLMEvent');
  },

});