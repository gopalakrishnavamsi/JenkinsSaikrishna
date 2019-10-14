({
  onInitialize: function (component, event, helper) {
    helper.getConfiguration(component, event, helper);
  },

  onChangeObject: function (component, event, helper) {
    // TODO: If isDirty, confirm before changing
    helper.getLayouts(component, event, helper);
  },

  makeDirty: function (component, event, helper) {
    component.set('v.isDirty', helper.isDirty(component.get('v.layouts')));
  },

  publishActions: function (component, event, helper) {
    helper.updateLayouts(component, event, helper);
  }
});
