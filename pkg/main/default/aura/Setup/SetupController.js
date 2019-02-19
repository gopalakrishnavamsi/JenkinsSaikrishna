({
  onInitialize: function (component, event, helper) {
    helper.getState(component, event, helper);
  },

  handleStepChange: function (component, event, helper) {
    // Called by the event handler, accepts the stepName (String) param from the event
    // and calls the goToStep helper method that changes the view based on that String
    helper.goToStep(component, helper, event.getParam('section'), false);
  },

  goToNextStep: function (component, event, helper) {
    // Called by Landing button and each Section onComplete
    // Checks for the next section that isn't complete
    // Calls goToStep and passes in the next step. (either Landing or section id)
    helper.hideToast(component);
    var steps = component.get('v.steps');
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].status !== 'complete') {
        helper.goToStep(component, helper, steps[i].name);
        return;
      }
    }
    helper.goToStep(component, helper, 'landing', component.get('v.shouldShowNextSteps'));
  },

  handleLoginEvent: function (component, event, helper) {
    var steps = component.get('v.steps');
    var isLoggedIn = event.getParams().isLoggedIn;
    steps[0].status = isLoggedIn ? 'complete' : 'notStarted';
    steps[1].status = 'notStarted';
    component.set('v.steps', steps);
    component.set('v.nextStep', 'setupUsers');
    if (!isLoggedIn) component.set('v.shouldShowNextSteps', true);
  }
});
