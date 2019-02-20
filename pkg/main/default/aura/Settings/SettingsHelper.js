({
  setLoading: function (component, isLoading) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: isLoading === true
    });
    evt.fire();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true, message: message, mode: mode
    });
    evt.fire();
  },

  hideToast: function (component) {
    var evt = component.getEvent('toastEvent');
    if (!$A.util.isUndefinedOrNull(evt)) {
      evt.setParams({
        show: false
      });
      evt.fire();
    }
  },

  useSystemSender: function(accountSettings) {
    return !$A.util.isUndefinedOrNull(accountSettings)
      && !$A.util.isUndefinedOrNull(accountSettings.systemSenderId)
      && !$A.util.isEmpty(accountSettings.systemSenderId.value);
  },

  getSettings: function (component) {
    this.setLoading(component, true);
    var gs = component.get('c.getSettings');
    gs.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var s = response.getReturnValue();
        component.set('v.settings', s.account);
        component.set('v.availableSystemSenders', s.availableSystemSenders);
        if (this.useSystemSender(s.account)) {
          component.set('v.systemSenderId', s.account.systemSenderId.value);
        } else {
          component.set('v.systemSenderId', null);
        }
      } else {
        this.showToast(component, _getErrorMessage(response), 'error');
      }
      this.setLoading(component, false);
    });
    $A.enqueueAction(gs);
  },

  saveSettings: function (component) {
    this.setLoading(component, true);
    var ss = component.get('c.saveSettings');
    var s = component.get('v.settings');
    var ssId = component.get('v.systemSenderId');
    if (!$A.util.isEmpty(ssId)) {
      s.systemSenderId = {value: ssId};
    } else {
      s.systemSenderId = null;
    }
    ss.setParams({
      settingsJson: JSON.stringify(s)
    });
    ss.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        component.set('v.settings', response.getReturnValue());
        this.exit(component);
        this.showToast(component, $A.get('$Label.c.SettingsSaved'), 'success');
      } else {
        this.showToast(component, _getErrorMessage(response), 'error');
      }
      this.setLoading(component, false);
    });
    $A.enqueueAction(ss);
  },

  exit: function (component) {
    var navToSection = component.getEvent('exitClicked');
    navToSection.setParams({
      section: "landing"
    });
    navToSection.fire();
  }
});
