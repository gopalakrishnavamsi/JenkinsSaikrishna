({
  initialize: function (component, event, helper) {
    helper.updateText(component, event);
  },

  handleButtonClick: function (component) {
    //When button is pressed, the event is fired which calls the parent function
    // goToNextSection
    component.getEvent('landingButtonClicked').fire();
  },

  handleRowButtonClick: function (component, event) {
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

  hideNextSteps: function (component) {
    component.set('v.showNextSteps', false);
  },

  onClickSettings: function(component) {
    var navToSection = component.getEvent('rowButtonClicked');
    navToSection.setParams({
      section: 'settings'
    });
    navToSection.fire();
  }
});
