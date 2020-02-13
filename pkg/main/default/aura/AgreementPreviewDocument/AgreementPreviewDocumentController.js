({
  onLoad: function (component, event, helper) {
    helper.onLoad(component, event, helper);
  },

  initializeResources: function (component, event, helper) {
    helper.loadAgreementStatusTypes(component, helper);
  }
});