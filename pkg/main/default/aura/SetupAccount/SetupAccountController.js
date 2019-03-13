({
  initialize: function (component, event, helper) {
    helper.setContinueButtonState(component);
  },

  handleContinueClick: function (component) {
    component.getEvent('finishClicked').fire();
  },

  handleExitClick: function (component) {
    component.set('v.showExitModal', true);
  },

  handleConfirmExitClick: function (component) {
    component.set('v.showExitModal', false);
    var navToSection = component.getEvent('exitClicked');
    navToSection.setParams({
      section: 'landing'
    });
    navToSection.fire();
  },

  handleLoginChange: function (component, event, helper) {
    helper.setContinueButtonState(component);
  }
});
