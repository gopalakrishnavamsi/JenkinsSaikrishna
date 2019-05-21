({
  _useSystemSender: function(accountSettings) {
    return (
      !$A.util.isUndefinedOrNull(accountSettings) &&
      !$A.util.isUndefinedOrNull(accountSettings.systemSenderId) &&
      !$A.util.isEmpty(accountSettings.systemSenderId.value)
    );
  },

  getSettings: function(component) {
    var self = this;
    component
      .get('v.uiHelper')
      .invokeAction(component.get('c.getSettings'), null, function(s) {
        component.set('v.settings', s.account);
        component.set('v.availableSystemSenders', s.availableSystemSenders);
        if (self._useSystemSender(s.account)) {
          component.set('v.systemSenderId', s.account.systemSenderId.value);
        } else {
          component.set('v.systemSenderId', null);
        }
      });
  },

  saveSettings: function(component) {
    var self = this;
    var uiHelper = component.get('v.uiHelper');
    var settings = component.get('v.settings');
    var ssId = component.get('v.systemSenderId');
    if (!$A.util.isEmpty(ssId)) {
      settings.systemSenderId = { value: ssId };
    } else {
      settings.systemSenderId = null;
    }
    uiHelper.invokeAction(
      component.get('c.saveSettings'),
      { settingsJson: JSON.stringify(settings) },
      function(ss) {
        component.set('v.settings', ss);
        self.exit(component);
        uiHelper.showToast($A.get('$Label.c.SettingsSaved'), 'success');
      }
    );
  },

  exit: function(component) {
    var navToSection = component.getEvent('exitClicked');
    navToSection.setParams({
      section: 'landing'
    });
    navToSection.fire();
  }
});
