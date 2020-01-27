({
  onChangeIsAuthorized: function (component, event, helper) {
    var products = component.get('v.products');
    if (!$A.util.isUndefinedOrNull(products)) {
      products.forEach(function (product) {
        if (product.name === 'gen') {
          component.set('v.isGenEnabled', product.status === 'active');
          component.set('v.isGenTrialExpired', product.isExpired);
        }
      });
      helper.initSetup(component);
    }
  },
  createTemplate: function (component, event, helper) {
    helper.saveTemplate(component, event, helper);
  },
  selectType: function (component, event) {
    component.set('v.selectedType', event.currentTarget.value);
  },
  cancel: function (component, event, helper) {
    var isRedirectOnCancel = component.get('v.isRedirectOnCancel');
    if (isRedirectOnCancel) {
      helper.redirectToCancelUrl(component);
    } else {
      component.find('genTemplateNavigator').destroy();
    }
  }
});