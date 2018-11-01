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

  getSettings: function (component, helper) {
    helper.setLoading(component, true);
    var gs = component.get('c.getSettings');
    gs.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        component.set('v.settings', response.getReturnValue());
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
      helper.setLoading(component, false);
    });
    $A.enqueueAction(gs);
  },

  saveSettings: function (component, helper) {
    helper.setLoading(component, true);
    var ss = component.get('c.saveSettings');
    ss.setParams({
      settingsJson: JSON.stringify(component.get('v.settings'))
    });
    ss.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        component.set('v.settings', response.getReturnValue());
        helper.exit(component);
        helper.showToast(component, $A.get('$Label.c.SettingsSaved'), 'success');
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
      helper.setLoading(component, false);
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