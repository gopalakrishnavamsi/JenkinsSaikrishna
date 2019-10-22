({
  closeScopedNotification: function (component, e, helper) {
    component.set('v.isVisible', false);
    helper.fireApplicationEvent(
      component,
      {
        fromComponent: 'CLMScopedNotifications',
        toComponent: 'CLMSetupLayout',
        type: 'closeNotification'
      },
      'CLMEvent'
    );
  },
  handleScopedNotification: function (component, event) {
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');
    if (
      toComponent === 'CLMScopedNotifications' &&
      fromComponent !== 'CLMScopedNotifications'
    ) {
      if (type === 'hide') {
        component.set('v.isVisible', false);
      } else if (type === 'show') {
        component.set('v.isVisible', true);
      }
    }
  }
});
