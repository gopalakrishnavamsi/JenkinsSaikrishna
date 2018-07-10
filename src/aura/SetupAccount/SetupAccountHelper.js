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
        if ('domain' in steps[i] && !$A.util.isEmpty(steps[i].domain)) {
          component.set('v.domain', steps[i].domain);
        }
        if ('domainInput' in steps[i] && !$A.util.isEmpty(steps[i].domainInput)) {
          component.set('v.domainInput', steps[i].domainInput);
          component.set('v.continueButtonDisabled', false);
        }

        if (steps[i].isComplete === true) {
          component.set('v.continueButtonDisabled', false);
          if (data.steps[i].cmpName === 'salesforceToThirdParty') {
            if (typeof data.steps[i].loggedIn !== 'undefined') {
              if (data.steps[i].loggedIn === true) {
                component.set('v.loggedIn', true);
              }
            }
          }
          if (data.steps[i].cmpName === 'thirdPartyToSalesforce') {
            if (typeof data.steps[i].inboundAuthed !== 'undefined') {
              if (data.steps[i].inboundAuthed === true) {
                component.set('v.inboundAuthed', true);
              }
            }
          }
        }
      }
      this.calculateActiveStep(component, event, helper);
    }
  },
});
