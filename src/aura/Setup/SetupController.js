({
  initialize: function(component, event, helper) {
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
    var steps = component.get('v.steps');
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].status !== 'complete') {
        helper.goToStep(component, helper, steps[i].name);
        return;
      }
    }
    helper.goToStep(component, helper, 'landing', event.getParam('showNextStepsPopup'));
  },

  handleToastEvent: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
    } else {
      helper.hideToast(component);
    }
  },

  showLoading: function (component, event, helper) {
    helper.setLoading(component, true);
  },

  hideLoading: function (component, event, helper) {
    helper.setLoading(component, false);
  }
});
