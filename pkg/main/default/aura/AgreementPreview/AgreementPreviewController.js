({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized') && component.get('v.negotiateProduct')) {
      helper.getAgreementDetails(component);
    } else {
      var showSetupComponent = component.get('v.showSetupComponent');
      showSetupComponent();
    }
  },

  handleToastEvent: function (component, event, helper) {
    helper.toastEvent(component, event, helper);
  },

  handleLoadingEvent: function (component, event, helper) {
    helper.loadingEvent(component, event);
  },

  handleReloadEvent: function (component, event, helper) {
    helper.reLoadingEvent(component);
  }

});
