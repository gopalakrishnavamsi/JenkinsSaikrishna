({
  clickedPrimary: function (component) {
    var primaryClicked = component.getEvent('strike_evt_modalPrimaryButtonClicked');
    primaryClicked.fire();
  },
  clickedSecondary: function (component) {
    var secondaryClicked = component.getEvent('strike_evt_modalSecondaryButtonClicked');
    secondaryClicked.fire();

  },
  disabledPrimaryButton: function (component) {
    component.set('v.primaryButtonDisabled', 'true');
  },
  enablePrimaryButton: function (component) {
    component.set('v.primaryButtonDisabled', 'false');
  },

  handleEvent: function (component, event) {
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');

    if (toComponent === 'CLMModelFooterButton' && fromComponent !== 'CLMModelFooterButton') {
      if (type === 'disable') {
        component.set('v.primaryButtonDisabled', 'true');

      } else if (type === 'enable') {
        component.set('v.primaryButtonDisabled', 'false');
      }

    }
  }
});