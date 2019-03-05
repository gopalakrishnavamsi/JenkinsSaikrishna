({
  handleContinueClick: function (component) {
    var finishClicked = component.getEvent('finishClicked');
    finishClicked.setParams({
      showNextStepsPopup: true
    });
    finishClicked.fire();
  },

  handleExitClick: function (component) {
    component.set('v.showExitModal', true);
  },

  handleConfirmExitClick: function (component) {
    var navToSection = component.getEvent('exitClicked');

    component.set('v.showExitModal', false);

    navToSection.setParams({
      section: "landing"
    });
    navToSection.fire();
  }
});
