({
  onInitialize: function (component, event, helper) {
    component.set('v.uiHelper', new UIHelper(component.find('common-ui')));
    helper.getConfiguration(component);
  },

  onChangeObject: function (component, event, helper) {
    // TODO: If isDirty, confirm before changing
    helper.getLayouts(component);
  },

  makeDirty: function (component, event, helper) {
    component.set('v.isDirty', true);
  },

  publishActions: function (component, event, helper) {
    helper.updateLayouts(component);
  },

  onContinue: function (component, event, helper) {
    var evt = component.getEvent('finishClicked');
    evt.setParams({
      showNextStepsPopup: true
    });
    evt.fire();
  },

  onConfirmCancel: function (component, event, helper) {
    component.set('v.showExitModal', false);
    var evt = component.getEvent('exitClicked');
    evt.setParams({
      section: 'landing'
    });
    evt.fire();
  }
});
