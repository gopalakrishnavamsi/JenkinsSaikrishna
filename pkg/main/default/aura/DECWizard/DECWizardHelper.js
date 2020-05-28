({
  processAfterAuthorization: function (component) {
    var self = this;
    var products = component.get('v.products');
    var permission = component.get('v.permission');
    var isExpired = false;
    var isActive = false;
    if (!permission.isDocuSignAdministrator) {
      self.showToast(component, $A.get('$Label.c.MustBeDocuSignAdministrator'), 'error');
      component.set('v.loading', false);
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
      component.set('v.showWizard', true);
    }
  }
});