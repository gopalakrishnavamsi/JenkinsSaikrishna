({
  calculateProgressAmount: function (component, event, helper) {
    var data = component.get('v.section');
    var totalSteps = data.steps.length;
    var activeStep = component.get('v.activeStep');
    var progressAmount = (100 / (totalSteps - 1)) * activeStep;
    component.set('v.progressAmount', progressAmount <= 100 ? progressAmount : 100);
  },

  finishSection: function (component, event, helper) {
    var data = component.get('v.section');
    data.status = 'complete';
    component.set('v.activeStep', 0);
    this.calculateProgressAmount(component, event, helper);
    this.initiateSave(component, event, helper);
    var finishClicked = component.getEvent('finishClicked');
    finishClicked.setParams({
      "showNextStepsPopup": component.get('v.showNextSteps')
    });
    finishClicked.fire();
  },

  initiateSave: function (component, event, helper) {
    //Fire Save event that triggers backend save on SetupAssistant
    var saveToBackend = component.getEvent('saveToBackend');
    saveToBackend.fire();
  },

  calculateActiveStep: function (component, event, helper) {
    var data = component.get('v.section');
    for (var i = 0; i < data.steps.length; i++) {
      if (!data.steps[i].isComplete) {
        component.set('v.activeStep', i);
        break;
      }
    }
    this.calculateProgressAmount(component, event, helper);
  },

  setInitialState: function (component, event, helper) {
    var data = component.get('v.section');
    if (!$A.util.isEmpty(data)) {
      var steps = data.steps;
      for (var i = 0; i < steps.length; i++) {
      }
      this.calculateActiveStep(component, event, helper);
      this.setContinueButtonState(component, event, helper);
    }
  },

  setContinueButtonState: function (component, event, helper) {
    var section = component.get('v.section');
    var steps = section.steps;
    var activeStep = component.get('v.activeStep');

    if (typeof steps !== 'undefined') {
      if (typeof steps[activeStep] !== 'undefined') {
        if (steps[activeStep].type === 'Blank') {
          component.set('v.continueButtonDisabled', false);
        }
      }
    }
  }
});
