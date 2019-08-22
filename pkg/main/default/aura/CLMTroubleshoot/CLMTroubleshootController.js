({
  navigateToSection: function (component, event, helper) {
    helper.fireApplicationEvent(component, {
      fromComponent: 'CLMTroubleshoot',
      toComponent: 'CLMSetupLayout',
      type: 'update',
      tabIndex: '4',
    }, 'CLMNavigationEvent');
  }
});