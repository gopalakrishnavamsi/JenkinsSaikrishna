({
  onInitialize: function (component, event, helper) {
    helper.getConfiguration(component);
  },

  onChangeObject: function (component, event, helper) {
    // TODO: If isDirty, confirm before changing
    helper.getLayouts(component);
  },

  makeDirty: function (component, event, helper) {
    component.set('v.isDirty', helper.isDirty(component.get('v.layouts')));
  },

  publishActions: function (component, event, helper) {
    helper.updateLayouts(component);
  }
});
