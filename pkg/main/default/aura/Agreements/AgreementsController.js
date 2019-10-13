({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized')) {
      //Hide the error toast message
      var toastComponent = component.find('toast');
      if (!$A.util.isUndefinedOrNull(toastComponent)) {
        $A.util.toggleClass(toastComponent, 'slds-hide');
      }
      var products = component.get('v.products');
      if (!$A.util.isUndefinedOrNull(products)) {
        products.forEach(function (product) {
          if (product.name === 'e_sign') {
            component.set('v.isESignatureEnabled', true);
          } else if (product.name === 'negotiate') {
            component.set('v.isNegotiateEnabled', true);
          }
        });
        //Make call to load the agreements after successful authorization
        if (!component.get('v.isAgreementLoaded')) {
          helper.loadAgreements(component, event, helper);
        }
      }
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
    if (params && params.isLoading === true && !component.get('v.isAgreementLoaded')) {
      helper.loadAgreements(component, event, helper);
    }
  },

  reloadAgreements: function (component, event, helper) {
    helper.loadAgreements(component, event, helper);
  }
});
