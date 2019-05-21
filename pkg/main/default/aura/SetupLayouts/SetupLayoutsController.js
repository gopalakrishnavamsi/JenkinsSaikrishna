({
  onCancel: function(component) {
    component.set('v.showExitModal', true);
  },

  onConfirmCancel: function(component) {
    var navToSection = component.getEvent('exitClicked');
    component.set('v.showExitModal', false);
    navToSection.setParams({
      section: 'landing'
    });
    navToSection.fire();
  },

  onContinue: function(component) {
    var finishClicked = component.getEvent('finishClicked');
    finishClicked.setParams({
      showNextStepsPopup: true
    });
    finishClicked.fire();
  }
});
