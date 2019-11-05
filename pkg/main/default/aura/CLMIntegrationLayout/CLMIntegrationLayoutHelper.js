({
  insertComponent: function (component, componentName, parameter) {
    $A.createComponent(componentName, parameter, function (newComp, status) {
      if (status === 'SUCCESS') {
        component.set('v.editComponent', newComp);
      }
    });
  },

  openHelpPage: function (component) { 
    this.fireApplicationEvent(
      component,
      {
        fromComponent: 'CLMIntegrationLayout',
        toComponent: 'CLMSetupLayout',
        type: 'update',
        tabIndex: '8'
      },
      'CLMNavigationEvent'
    );
  }
});
