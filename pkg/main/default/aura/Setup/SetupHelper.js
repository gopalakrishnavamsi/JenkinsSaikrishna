({
  showToast: function (component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.find('toast').show();
  },

  hideToast: function (component) {
    component.find('toast').close();
  },

  setLoading: function (component, loading) {
    component.set('v.loading', loading === true);
  },

  getState: function (component, event, helper) {
    helper.setLoading(component, true);

    var getLogin = component.get('c.getLogin');

    getLogin.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var login = response.getReturnValue();
        var isLoggedIn = login && login.status === 'Success';
        var status = isLoggedIn ? 'complete' : 'notStarted';
        component.set('v.login', login);
        component.set('v.isLoggedIn', isLoggedIn);
        component.set('v.login.selectedAccountNumber', !isLoggedIn || $A.util.isUndefinedOrNull(login) || $A.util.isEmpty(login.accounts) ? null : login.accounts[0].accountNumber);
        // TODO: Fix trials
        component.set('v.isTrialExpired', false);//login.isTrial && login.trialStatus && login.trialStatus.isExpired === true);
        var steps = [{
          name: 'setupAccount',
          title: $A.get('$Label.c.ConnectToDocuSign'),
          headerText: $A.get('$Label.c.ConnectToDocuSign'),
          subText: $A.get('$Label.c.ConnectDocuSignToSalesforce'),
          status: status
        }, {
          name: 'setupUsers',
          title: $A.get('$Label.c.ManageUsers'),
          headerText: $A.get('$Label.c.ManageUsers'),
          subText: $A.get('$Label.c.ConnectDocuSignUser'),
          status: status
        }];
        component.set('v.steps', steps);
        component.set('v.shouldShowNextSteps', !login.isLoggedIn);
        helper.updateProgression(component, steps);
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
      helper.setLoading(component, false);
    });
    $A.enqueueAction(getLogin);
  },

  goToStep: function (component, helper, stepName, showNextSteps) {
    // goToSection takes a string containing a section ID as a parameter
    //  and sets the attribute selectedSection to that string, which changes the active
    //   component on the page.
    component.set('v.currentStep', stepName);
    var steps = component.get('v.steps');
    helper.updateProgression(component, steps);

    if (stepName === 'setupAccount') {
      component.set('v.nextStep', steps[1].status === 'complete' ? 'landing' : 'setupUsers');
    } else if (stepName === 'setupUsers') {
      steps[1].status = 'complete';
      component.set('v.steps', steps);
      component.set('v.nextStep', 'landing');
    } else {
      component.set('v.nextStep', null);
    }

    if (showNextSteps === true) {
      window.setTimeout($A.getCallback(function () {
        component.set('v.showNextSteps', true);
      }), 0);
    }
  },

  updateProgression: function (component, steps) {
    var progressionStatus = "";
    var completedCounter = 0;
    var inProgressFlag = false;

    for (var i = 0; i < steps.length; i++) {
      if (steps[i].status === 'complete') {
        completedCounter++;
      } else if (steps[i].status === 'inProgress') {
        inProgressFlag = true;
      }
    }

    if (inProgressFlag === true) {
      progressionStatus = 'inProgress';
    } else if (completedCounter > 0) {
      if (completedCounter === steps.length) {
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
