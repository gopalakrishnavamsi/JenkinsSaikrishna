({
  getData: function (component, event, helper) {
    var stateData = component.get('v.sections');
    if ($A.util.isEmpty(stateData) || $A.util.isEmpty(stateData.setupData)) {
      stateData = {
        setupData: [{
          name: "systemConnections",
          headerText: $A.get('$Label.c.ConnectToDocuSign'),
          subText: $A.get('$Label.c.ConnectDocuSignToSalesforce'),
          status: "notStarted",
          steps: [{
            stepName: "salesforceToThirdParty",
            type: "",
            accountNumber: null,
            isTrial: false,
            emailAddress: null,
            loggedIn: false,
            isComplete: false
          }]
        }, {
          name: "manageUsers",
          headerText: $A.get('$Label.c.ManageUsers'),
          subText: $A.get('$Label.c.ConnectDocuSignUser'),
          status: "notStarted",
          steps: [{
            stepName: "userManagement", type: "Blank", isComplete: false
          }]
        }], loggedIn: false
      };
    }
    component.set('v.sections', stateData);
    component.set('v.loggedIn', stateData.loggedIn);
    helper.updateProgression(component, stateData);
  },

  goToSection: function (component, event, selectedSection, showNextSteps) {
    // goToSection takes a string containing a section ID as a parameter
    //  and sets the attribute selectedSection to that string, which changes the active
    //   component on the page.

    component.set('v.selectedSection', selectedSection);
    if (showNextSteps) {
      window.setTimeout($A.getCallback(function () {
        component.set('v.showNextSteps', true);
      }), 0);
    }
  },

  save: function (component, event, helper) {
    //Saves to the backend, calls helper.updateProgression to set landing text areas
    var stateData = component.get('v.sections');
    stateData.loggedIn = component.get('v.loggedIn');

    //resets setupData on logout
    if (!stateData.loggedIn) {
      stateData.setupData[1].status = 'notStarted';
      stateData.setupData[1].steps[0].isComplete = false;
    }
    component.set('v.sections', stateData);
    helper.updateProgression(component, stateData);
    var action = component.get("c.saveState");
    action.setParams({
      'state': JSON.stringify(stateData)
    });
    action.setCallback(this, function (res) {
      var response = res.getReturnValue();
      console.log('**************** Response: ', response);
    });
    $A.enqueueAction(action);
  },

  updateProgression: function (component, stateData) {
    var progressionStatus = "";
    var completedCounter = 0;
    var inProgressFlag = false;
    var data = stateData.setupData;

    for (var i = 0; i < data.length; i++) {
      if (data[i].status === 'complete') {
        completedCounter++;
      } else if (data[i].status === 'inProgress') {
        inProgressFlag = true;
      }
    }

    if (inProgressFlag === true) {
      progressionStatus = 'inProgress';
    } else if (completedCounter > 0) {
      if (completedCounter === data.length) {
        progressionStatus = 'complete';
      } else {
        progressionStatus = 'inProgress';
      }
    } else {
      progressionStatus = 'notStarted';
    }

    component.set('v.completedCounter', completedCounter);
    component.set('v.progressionStatus', progressionStatus);
  }
});
