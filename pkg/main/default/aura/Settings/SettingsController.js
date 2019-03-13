({
  onInitialize: function (component, event, helper) {
    component.set('v.uiHelper', new UIHelper(component));
    helper.getSettings(component);
  },

  onCancel: function (component) {
    component.set('v.showExitModal', true);
  },

  onConfirmCancel: function (component, event, helper) {
    component.set('v.showExitModal', false);
    helper.exit(component);
  },

  onSave: function (component, event, helper) {
    helper.saveSettings(component);
  }
});
