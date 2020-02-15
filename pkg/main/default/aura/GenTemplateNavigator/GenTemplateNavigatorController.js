({
  validateBrowser: function (component) {
    if (navUtils.isIE()) component.set('v.isIE', true);
  },

  onChangeIsAuthorized: function (component, event, helper) {
    var products = component.get('v.products');
    var isExpired = false;
    var isActive = false;
    if (!$A.util.isEmpty(products)) {
      for (var i = 0; i < products.length; i++) {
        var product = products[i];
        if (product.name === 'gen') {
          isActive = product.status === 'active';
          isExpired = product.isExpired;
          break;
        }
      }
    }
    component.set('v.isGenTrialExpired', isExpired);
    component.set('v.isGenEnabled', isActive);
    if (isExpired) {
      component.set('v.errMsg', $A.get('$Label.c.GenTrialExpired'));
    } else if (!isActive) {
      component.set('v.errMsg', $A.get('$Label.c.GenNotConfigured'));
    } else {
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
