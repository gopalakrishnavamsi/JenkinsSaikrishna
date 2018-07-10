({
  initialize: function(component, event, helper) {
    helper.getData(component, event, helper);
  },

  handleSectionChange: function (component, event, helper) {
    //Called by the event handler, accepts the section(String) param from the event
    // and calls the goToSection helper method that changes the view based on that String
    var selectedSection = event.getParam('section');
    helper.goToSection(component, event, selectedSection);
  },

  goToNextSection: function (component, event, helper) {
    //Called by Landing button and each Section onComplete
    // Checks for the next section that isn't complete
    //  calls goToSection(s) and passes in the next section. (either Landing or section id)
    var sections = component.get('v.sections');
    var data = sections.setupData;
    var selectedSection;
    for (var i = 0; i < data.length; i++) {
      if (data[i].status !== 'complete') {
        selectedSection = data[i].name;
        helper.goToSection(component, event, selectedSection);
        return;
      }
    }
    selectedSection = 'Landing';
    var showNextSteps = event.getParam('showNextStepsPopup');
    helper.goToSection(component, event, selectedSection, showNextSteps);
  },

  handleSave: function (component, event, helper) {
    helper.save(component, event, helper);
  }
});
