({
  _useSystemSender: function(accountSettings) {
    return (
      !$A.util.isUndefinedOrNull(accountSettings) &&
      !$A.util.isUndefinedOrNull(accountSettings.systemSenderId) &&
      !$A.util.isEmpty(accountSettings.systemSenderId.value)
    );
  },

  getSettings: function(component, event, helper) {
    component.set('v.loading', true);
    var getSettingsAction = component.get('c.getSettings');
    getSettingsAction.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var settings = response.getReturnValue();
        component.set('v.settings', settings.account);
        component.set('v.availableSystemSenders', settings.availableSystemSenders);
        if (helper._useSystemSender(settings.account)) {
          component.set('v.systemSenderId', settings.account.systemSenderId.value);
        } else {
          component.set('v.systemSenderId', null);
        }
      }
      else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    }));
    $A.enqueueAction(getSettingsAction);
  },

  saveSettings: function(component, event, helper) {
    component.set('v.loading', true);
    var settings = component.get('v.settings');
    var ssId = component.get('v.systemSenderId');
    if (!$A.util.isEmpty(ssId)) {
      settings.systemSenderId = { value: ssId };
    } else {
      settings.systemSenderId = null;
    }
    var saveSettingsAction = component.get('c.saveSettings');
    saveSettingsAction.setParams({
      settingsJson: JSON.stringify(settings)
    });
    saveSettingsAction.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.settings', response.getReturnValue());
      } 
      else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');  
      }
      component.set('v.loading', false);
    }));
    $A.enqueueAction(saveSettingsAction);
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  }
});
