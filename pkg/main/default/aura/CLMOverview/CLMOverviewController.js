({
  onPrimaryButtonClick: function (component, event, helper) {
    var buttonLabel = event.getParam('buttonLabel');
    if (buttonLabel === 'Get Help') {
      helper.fireApplicationEvent(component, {
        fromComponent: 'CLMHomeBody',
        toComponent: 'CLMSetupLayout',
        type: 'update',
        tabIndex: '8',
      }, 'CLMNavigationEvent');
    }
  }
}) 