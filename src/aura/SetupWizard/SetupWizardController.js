({
  initialize: function (component, event, helper) {
    helper.updateText(component, event);
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
    var section = event.getSource().get('v.value');
    var navToSection = component.getEvent('rowButtonClicked');
    navToSection.setParams({
      section: section
    });
    navToSection.fire();
  },

  handleProgressionStatusChange: function (component, event, helper) {
    helper.updateText(component, component.get('v.steps'));
  },

  hideNextSteps: function (component, event, helper) {
    component.set('v.showNextSteps', false);
  }
});
