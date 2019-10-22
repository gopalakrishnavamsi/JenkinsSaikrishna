({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized')) {
        var products = component.get('v.products');
        products.forEach(function (product) {
          if (product.name === 'clm' && product.status === 'active') {
            component.set('v.isClmEnabled', true);
            helper.getUrl(component, event, helper);            
          }
        });
      }        
  }
});
