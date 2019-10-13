({
  onChangeIsAuthorized: function (component, event, helper) {
    var hideSpinner = false;
    if (component.get('v.isAuthorized')) {
      var products = component.get('v.products');
      products.forEach(function (product) {
        if (product.name === 'e_sign') {
          component.set('v.isEsignEnabled', true);
        } else if (product.name === 'negotiate') {
          component.set('v.isNegotiateEnabled', true);
        }
      });
      if (component.get('v.isNegotiateEnabled')) {
        helper.getAgreementDetails(component);
      } else {
        hideSpinner = true;
      }
    } else {
      hideSpinner = true;
    }
    if (hideSpinner) {
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
