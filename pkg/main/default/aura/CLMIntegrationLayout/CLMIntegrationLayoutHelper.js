({
  insertComponent: function (component, componentName, parameter) {
    $A.createComponent(componentName, parameter, function (newComp, status) {
      if (status === 'SUCCESS') {
        component.set('v.editComponent', newComp);
      }
    });
  }
});