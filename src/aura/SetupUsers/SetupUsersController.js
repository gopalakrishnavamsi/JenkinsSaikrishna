({
  handleContinueClick: function (component, event, helper) {
    var finishClicked = component.getEvent('finishClicked');
    finishClicked.setParams({
      showNextStepsPopup: true
    });
    finishClicked.fire();
  },

  handleExitClick: function (component, event, helper) {
    component.set('v.showExitModal', true);
  },

  handleConfirmExitClick: function (component, event, helper) {
    var navToSection = component.getEvent('exitClicked');

    component.set('v.showExitModal', false);

    navToSection.setParams({
      section: "landing"
    });
    navToSection.fire();
  }
});
