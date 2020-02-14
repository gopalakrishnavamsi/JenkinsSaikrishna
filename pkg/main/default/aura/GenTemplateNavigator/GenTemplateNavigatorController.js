({
  validateBrowser: function (component) {
    if (navUtils.isIE()) component.set('v.isIE', true);
  },

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
    helper.saveTemplate(component);
  },

  selectType: function (component, event) {
    component.set('v.selectedType', event.currentTarget.value);
  },

  cancel: function (component) {
    var isRedirectOnCancel = component.get('v.isRedirectOnCancel');
    if (isRedirectOnCancel) {
      var ns = component.get('v.namespace');
      if ($A.util.isEmpty(ns)) {
        ns = '';
      } else {
        ns += '__';
      }
      var event = $A.get('e.force:navigateToObjectHome');
      event.setParam('scope', ns + 'GenTemplate__c');
      event.fire();
    } else {
      component.find('genTemplateNavigator').destroy();
    }
  }
});
