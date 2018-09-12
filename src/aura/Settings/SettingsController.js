({
  initialize: function (component, event, helper) {
    helper.hideToast(component);
    helper.getSettings(component, helper);
  },

  onCancel: function(component, event, helper) {
    component.set('v.showExitModal', true);
  },

  onConfirmCancel: function(component, event, helper) {
    component.set('v.showExitModal', false);
    helper.exit(component);
  },

  onSave: function (component, event, helper) {
    helper.saveSettings(component, helper);
  }
});
