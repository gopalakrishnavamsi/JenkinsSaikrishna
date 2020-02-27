({
  initDocumentGenerator: function (component) {
    component.set('v.loading', true);
    var products = component.get('v.products');
    var isExpired = false;
    var isActive = false;
    var self = this;
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
      component.set('v.loading', false);
      component.set('v.errMsg', $A.get('$Label.c.GenTrialExpired'));
    } else if (!isActive) {
      component.set('v.loading', false);
      component.set('v.errMsg', $A.get('$Label.c.GenNotConfigured'));
    } else {
      self.invokeAction(component, component.get('c.verifyDocuSignGenerator'), {},
        function (isGenerator) {
          if (isGenerator === true) {
            var renderOnlineEditorGenerator = component.get('v.renderOnlineEditorGenerator');
            renderOnlineEditorGenerator().then(function (isGenerated) {
              component.set('v.loading', false);
              component.set('v.isSendForSignatureEnabled', isGenerated);
            }).catch(function (err) {
              component.set('v.loading', false);
              component.set('v.errMsg', err);
            });
          }
        }
      );
    }
  }
});
