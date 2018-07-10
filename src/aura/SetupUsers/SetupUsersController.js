({
  initialize: function (component, event, helper) {
    helper.setInitialState(component, event, helper);
  },

  handleBackClick: function (component, event, helper) {
    var activeStep = component.get('v.activeStep');
    if (activeStep > 0) {
      component.set('v.activeStep', --activeStep);
      helper.calculateProgressAmount(component, event, helper);
      helper.setContinueButtonState(component, event, helper);
    }
  },

  handleContinueClick: function (component, event, helper) {
    var activeStep = component.get('v.activeStep');
    var data = component.get('v.section');
    var steps = data.steps;
    var totalSteps = steps.length;
    if (steps[activeStep].isComplete !== true) {
      steps[activeStep].isComplete = true;
      component.set('v.showNextSteps', true);
    }

    /*if(data.status != 'complete'){
        data.status = 'inProgress';
    }*/
    helper.finishSection(component, event, helper);
    /*if(activeStep < totalSteps){
        steps[activeStep].isComplete = true;

        if(data.status != 'complete'){
            data.status = 'inProgress';
        }
        helper.initiateSave(component, event, helper);
        component.set('v.activeStep', ++activeStep);
        component.set('v.section', data);
        helper.calculateProgressAmount(component, event, helper);
        helper.setContinueButtonState(component, event, helper);

    } else{
        helper.finishSection(component, event, helper);
    }*/
  },

  handleExitClick: function (component, event, helper) {
    component.set('v.showExitModal', true);
  },

  handleConfirmExitClick: function (component, event, helper) {
    var navToSection = component.getEvent('exitClicked');

    component.set('v.showExitModal', false);

    navToSection.setParams({
      "section": "Landing"
    });
    navToSection.fire();
  },

  handleSelectedSectionChange: function (component, event, helper) {
    helper.setContinueButtonState(component, event, helper);
  }
});
