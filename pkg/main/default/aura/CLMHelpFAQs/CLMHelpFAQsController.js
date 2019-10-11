({
  toggleSection: function (component, event) {
    var label = event.currentTarget.id;
    var acc = component.find(label);
    for (var cmp in acc) {
      $A.util.toggleClass(acc[cmp], 'slds-show');
      $A.util.toggleClass(acc[cmp], 'slds-hide');
    }
  },
  
  navigateToHelpPage: function(component, event, helper) {
    helper.fireApplicationEvent(component, {
      fromComponent: 'CLMHelpFAQsController',
      toComponent: 'CLMSetupLayout',
      type: 'update',
      tabIndex: '8',
    }, 'CLMNavigationEvent');
  }
});