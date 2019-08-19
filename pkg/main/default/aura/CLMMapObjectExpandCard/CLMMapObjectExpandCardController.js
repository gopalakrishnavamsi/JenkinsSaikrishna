({
  onInit: function (component, event, helper) {
    helper.callServer(component, 'c.getNamespace', false, function (result) {
      component.set('v.namespace', result);
    });
  },

  toggleSection: function (component) {
    var acc = component.find('objMapping');
    for (var cmp in acc) {
      $A.util.toggleClass(acc[cmp], 'slds-show');
      $A.util.toggleClass(acc[cmp], 'slds-hide');
    }
  },
  gotoIntegrationHome: function (component, event, helper) {
    helper.fireApplicationEvent(component, {
      fromComponent: 'CLMMapObjectExpand',
      toComponent: 'CLMSetupLayout',
      type: 'update',
      tabIndex: '3',
    }, 'CLMNavigationEvent');
  }
})
