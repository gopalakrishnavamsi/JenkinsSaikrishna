({
  initialize: function (component, event, helper) {
    component.set('v.helpInfo', '');
    var loggedIn = component.get('v.loggedIn');

    if (loggedIn) {
      helper.getDocuSignAccount(component, event, helper);
    }

    helper.setContinueButtonState(component, event, helper);
  },

  handleSelectedSectionActiveStepChange: function (component, event, helper) {
    if (component.get('v.selectedSection') === "systemConnections" && component.get('v.activeStep') === 0) {
      helper.setContinueButtonState(component, event, helper);
    }
  },

  handleLoginChange: function (component, event, helper) {
    helper.setContinueButtonState(component, event, helper);
  },

  loginToDocuSign: function (component, event, helper) {
    helper.login(component, event, helper);
  },

  logoutOfDocuSign: function (component, event, helper) {
    component.set('v.showLogoutModal', false);

    setTimeout($A.getCallback(function () { // Wait for modal to hide
      component.set('v.showLoginSpinner', true);
      var logout = component.get('c.logout');

      logout.setParams({
        resetUsers: true
      });

      logout.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          component.set('v.loggedIn', false);
          component.set('v.isTrial', false);
          component.set('v.trialIsExpired', false);
          component.set('v.accountNumber', null);
          component.set('v.emailAddress', null);
          component.set('v.password', null);
          component.set('v.associatedAccounts', []);
          helper.saveData(component, event, helper);
          component.set('v.showLoginSpinner', false);

          setTimeout($A.getCallback(function () {
            component.find('login-input').focus();
          }), 1);
        } else {
          helper.setError(component, response);
        }
      });
      $A.enqueueAction(logout);
    }), 300);
  },

  selectAccount: function (component, event, helper) {
    component.set('v.showAccountSelectionModal', false);
    helper.login(component, event, helper);
  },

  cancelSelectAccount: function (component, event, helper) {
    component.set('v.showAccountSelectionModal', false);
  },

  getStarted: function (component, event, helper) {
    component.set('v.showToast', false);
    if (helper.getInputValidity(component, 'trial-input', 'trial-button')) {
      component.set('v.showLoginSpinner', true);
      var startTrial = component.get('c.startTrial');

      startTrial.setParams({
        email: component.get('v.emailAddress')
      });

      startTrial.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          var account = response.getReturnValue();
          component.set('v.isTrial', true);
          component.set('v.accountNumber', account.accountNumber);
          helper.saveData(component, event, helper);
          component.set('v.showLoginSpinner', false);
          component.set('v.signedUpForTrial', true);
        } else {
          helper.setError(component, response);
        }
      });
      $A.enqueueAction(startTrial);
    }
  },

  showLogoutModal: function (component, event, helper) {
    component.set('v.showToast', false);
    component.set('v.showLogoutModal', true);
  },

  hideLogoutModal: function (component, event, helper) {
    component.set('v.showLogoutModal', false);
  },

  handleAccountChange: function (component, event, helper) {
    component.set('v.section.steps[0].accountNumber', component.get('v.accountNumber'));
    component.set('v.section.steps[0].isTrial', component.get('v.isTrial'));
  },

  handlePasswordKeyup: function (component, event, helper) {
    var key = event.which || event.keyCode || 0;

    if (key === 13) {
      helper.login(component, event, helper);
    }
  },

  swapLogInState: function (component, event, helper) {
    var showingTrialFields = component.get('v.showTrialFields');

    component.set('v.showTrialFields', !showingTrialFields);

    setTimeout($A.getCallback(function () {
      if (showingTrialFields) {
        component.find('login-input').focus();
      } else {
        component.find('trial-input').focus();
      }
    }), 1);
  },

  continueToLogIn: function (component, event, helper) {
    component.set('v.showTrialFields', false);
    component.set('v.signedUpForTrial', false);

    setTimeout($A.getCallback(function () {
      component.find('password-input').focus();
    }), 1);
  },

  navigateToUpgrade: function (component, event, helper) {
    var navEvt = $A.get('e.force:navigateToURL');
    if (!$A.util.isEmpty(navEvt)) {
      navEvt.setParams({
        'url': 'https://www.docusign.com/solutions/salesforce'
      });
      navEvt.fire();
    }
  },

  toggleAdvancedOptions: function (component, event, helper) {
    component.set('v.advancedOptionsExpanded', !component.get('v.advancedOptionsExpanded'));
  }
});
