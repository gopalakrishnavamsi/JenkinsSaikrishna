({
  onInitialize: function (component, event, helper) {
    component.set('v.uiHelper', new UIHelper(function () {
      return component.getEvent('loadingEvent');
    }, function () {
      return component.getEvent('toastEvent');
    }));
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
