({
  createEnvelopeConfig: function (component) {
    var self = this;
    component.set('v.loading', true);
    component.set('v.showModal', false);
    var config = component.get('v.envelopeConfig');
    var configParameters = JSON.stringify(config);
    self.invokeAction(
      component,
      component.get('c.createEnvelopeConfiguration'),
      {
        envelopeConfigurationJSON: configParameters
      },
      function (newConfig) {
        var navigateToNewEnvelopeConfigUrl = component.get('v.navigateToNewEnvelopeConfigUrl');
        navigateToNewEnvelopeConfigUrl(newConfig.id);
        component.find('decNavigatorModal').destroy();
      },
      function () {
        component.set('v.loading', false);
        component.set('v.showModal', true);
      }
    );
  },
  processAfterAuthorization: function (component) {
    var self = this;
    var products = component.get('v.products');
    var permission = component.get('v.permission');
    var isExpired = false;
    var isActive = false;
    if (!permission.isDocuSignAdministrator) {
      component.set('v.loading', false);
      self.showToast(component, $A.get('$Label.c.MustBeDocuSignAdministrator'), 'error');
      return;
    }
    if (!$A.util.isEmpty(products)) {
      for (var i = 0; i < products.length; i++) {
        var product = products[i];
        if (product.name === 'e_sign' && product.status === 'active') {
          isActive = product.status === 'active';
          isExpired = product.isExpired;
          break;
        }
      }
    }
    if (isExpired) {
      self.showToast(component, $A.get('$Label.c.ExpiredTrialAccount'), 'error');
    } else if (!isActive) {
      self.showToast(component, $A.get('$Label.c.AccountNotConfigured'), 'error');
    } else {
      component.set('v.showModal', true);
    }
    component.set('v.loading', false);
  }
});