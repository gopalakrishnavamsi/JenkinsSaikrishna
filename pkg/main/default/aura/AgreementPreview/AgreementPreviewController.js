({
  onLoad: function (component, event, helper) {
    helper.getAgreementDetails(component);
  },

  handleToastEvent: function (component, event, helper) {
    helper.toastEvent(component, event, helper);
  },

  handleLoadingEvent: function (component, event, helper) {
    helper.loadingEvent(component, event, helper);
  }

});
