({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized')) {
      //Hide the error toast message
      var toastComponent = component.find('toast');
      $A.util.toggleClass(toastComponent, 'slds-hide');
      //Make call to load the agreements after succesful authorization
      helper.loadAgreements(component, event, helper);
    }
  },

  handleToastEvent: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
      if (params.mode === 'success') {
        setTimeout($A.getCallback(function () {
          helper.hideToast(component);
        }), 3000);
      }
    } else {
      helper.hideToast(component);
    }
  },

  importAgreements: function (component, event, helper) {
    helper.createImportComponent(component, event, helper);
  },

  handleLoadingEvent: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.isLoading === true) {
      helper.loadAgreements(component, event, helper);
    }
  }
});
