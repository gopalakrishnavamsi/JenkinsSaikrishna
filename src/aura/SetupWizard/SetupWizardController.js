({
  initialize: function (component, event, helper) {
    helper.updateText(component, event);
  },

  handleAccountExpiration: function (component, event, helper) {
    var loggedIn = component.get('v.loggedIn');
    if (loggedIn) {
      var getDocuSignAccount = component.get('c.getAccount');
      getDocuSignAccount.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          var account = response.getReturnValue();
          if (account && account.isTrial) {
            component.set('v.trialIsExpired', account.trialStatus.isExpired);
          }
        } else {
          helper.setError(component, response);
        }
      });
      $A.enqueueAction(getDocuSignAccount);
    }
  },

  handleButtonClick: function (component, event, helper) {
    //When button is pressed, the event is fired which calls the parent function
    // goToNextSection
    var nextSectionEvt = component.getEvent('landingButtonClicked');
    nextSectionEvt.fire();
  },

  handleRowButtonClick: function (component, event, helper) {
    //When button is pressed, the event is fired which calls the parent function
    // navigateToSection
    var section = event.getSource().get("v.value");
    var navToSection = component.getEvent('rowButtonClicked');
    navToSection.setParams({
      "section": section
    });
    navToSection.fire();
  },

  handleProgressionStatusChange: function (component, event, helper) {
    var data = component.get('v.data');
    helper.updateText(component, data);
  },

  hideNextSteps: function (component, event, helper) {
    component.set('v.showNextSteps', false);
  }
});
