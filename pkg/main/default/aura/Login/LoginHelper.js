({
  init: function (component, event, helper) {
    //load the steps for slds-path component
    var steps = [$A.get('$Label.c.LoginToDocuSign'), $A.get('$Label.c.SelectAccountOption'), $A.get('$Label.c.AuthorizeButton')];
    component.set('v.steps', steps);

    //get current login details
    var config;
    var loginInformation = component.get('v.login');
    var hasAccounts = !$A.util.isUndefinedOrNull(loginInformation) && !$A.util.isEmpty(loginInformation.accounts);
    var isLoggedIn = hasAccounts && loginInformation.status === 'Success';
    var isPlatformAuthorized = loginInformation.isPlatformAuthorized;
    component.set('v.isLoggedIn', isLoggedIn);
    component.set('v.isPlatformAuthorized', isPlatformAuthorized);

    //logged in to DocuSign account but platform authorization not yet completed
    if (isLoggedIn && !isPlatformAuthorized) {
      //populate the account details
      var accountOptions = [];
      component.set('v.selectedAccountNumber', loginInformation.accounts[0].accountNumber.toString());
      accountOptions.push({
        'label': stringUtils.format($A.get('$Label.c.AccountDisplay_2'), loginInformation.accounts[0].name, loginInformation.accounts[0].accountNumber),
        'value': loginInformation.accounts[0].accountNumber.toString()
      });
      component.set('v.multipleAccountsFound', false);
      component.set('v.accountOptions', accountOptions);
      config = {'stepsCompleted': 1};
      component.set('v.config', config);
      helper.gotoAuthorizationStep(component, helper, false);
    }

    //User not yet logged in so show first step
    else if (!isLoggedIn) {
      config = {'stepsCompleted': 0};
      component.set('v.config', config);
      component.set('v.isCompleted', false);
      component.set('v.currentStep', config.stepsCompleted);
    }
  },

  gotoAuthorizationStep: function (component, helper, reloadPage) {
    component.set('v.loading', true);
    //reloadPage is set to true when the user logs in to a account in the first step and completes DocuSign Authentication.
    //The page needs to be refreshed here in order to prevent Remoting Exception 
    if (reloadPage) {
      window.location.reload();
    }
    else {
      helper.checkPlatformAuthorizationSettings(component)
        .then($A.getCallback(function (response) {
          component.set('v.platformAuthorizationSettingsFound', response);
          helper.goToStep(component, 2);
          component.set('v.loading', false);
        }))
        .catch(function (error) {
          helper.showToast(component, error, 'error');
          component.set('v.loading', false);
        });
    }
  },

  gotoAccountSelectionStep: function (component, helper) {
    helper.goToStep(component, 1);
  },

  goToStep: function (component, selectedStep) {
    var isCompleted = component.get('v.isCompleted');

    if (!isCompleted) {
      var config = component.get('v.config');

      if (selectedStep > config.stepsCompleted) {
        config.stepsCompleted++;
        component.set('v.config', config);
      }
    }
    component.set('v.currentStep', selectedStep);
  },

  selectStep: function (component, event, helper) {
    var config = component.get('v.config');
    var maxStepsAllowed = config.stepsCompleted + 1;
    var selectedStep = parseInt(event.currentTarget.dataset.step, 10);
    if (selectedStep <= maxStepsAllowed) {
      helper.goToStep(component, selectedStep);
    }
  },

  checkPlatformAuthorizationSettings: function (component) {
    var checkAction = component.get('c.doPlatformAuthorizationSettingsExist');
    return new Promise($A.getCallback(function (resolve, reject) {
      checkAction.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      }));
      $A.enqueueAction(checkAction);
    }));
  },

  toggleAdvancedOptions: function (component) {
    component.set('v.advancedOptionsExpanded', !component.get('v.advancedOptionsExpanded'));
  },

  beginOAuth: function (component, event, helper) {
    component.set('v.loading', true);
    helper.logout(component)
      .then(function (loginInformation) {
          component.set('v.login', loginInformation);
          component.set('v.isLoggedIn', false);
          component.set('v.selectedAccountNumber', null);
          var beginOAuth = component.get('v.beginOAuth');
          beginOAuth(component, component.get('v.environment'), component.get('v.otherUrl') || null);
        }
      )
      .catch(function (error) {
          helper.showToast(component, error, 'error');
          component.set('v.loading', false);
        }
      );
  },

  handleOAuthEvent: function (component, response, loginInformation, helper) {
    if (response && response.status && loginInformation) {
      helper.setLoggedIn(component, loginInformation);
      helper.gotoAccountSelectionStep(component, helper);
    } else {
      helper.showToast(component, response.message, 'error');
    }
    component.set('v.loading', false);
  },

  setLoggedIn: function (component, loginInformation) {
    var hasAccounts = !$A.util.isUndefinedOrNull(loginInformation) && !$A.util.isEmpty(loginInformation.accounts);
    var isLoggedIn = hasAccounts && loginInformation.status === 'Success';

    component.set('v.login', loginInformation);
    component.set('v.isLoggedIn', isLoggedIn);

    var accountOptions = [];
    //single account and settings have been saved
    if (isLoggedIn) {
      component.set('v.selectedAccountNumber', loginInformation.accounts[0].accountNumber.toString());
      accountOptions.push({
        'label': stringUtils.format($A.get('$Label.c.AccountDisplay_2'), loginInformation.accounts[0].name, loginInformation.accounts[0].accountNumber),
        'value': loginInformation.accounts[0].accountNumber.toString()
      });
      component.set('v.multipleAccountsFound', false);
      component.set('v.accountOptions', accountOptions);
    }

    //multiple accounts found. user should choose one of the account
    if (hasAccounts && loginInformation.status === 'SelectAccount') {
      component.set('v.multipleAccountsFound', true);
      loginInformation.accounts.forEach(function (account) {
        if (account.isDefault) {
          component.set('v.selectedAccountNumber', account.accountNumber.toString());
        }
        accountOptions.push({
          'label': stringUtils.format($A.get('$Label.c.AccountDisplay_2'), account.name, account.accountNumber),
          'value': account.accountNumber.toString()
        });
      });
      component.set('v.accountOptions', accountOptions);
    }
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  },

  accountSelected: function (component, event, helper) {
    var isLoggedIn = component.get('v.isLoggedIn');

    if (!isLoggedIn) {
      var setAccountAction = component.get('c.setAccount');

      setAccountAction.setParams({
        environment: component.get('v.environment'),
        otherUrl: component.get('v.otherUrl'),
        accountNumber: parseInt(component.get('v.selectedAccountNumber'), 10)
      });

      setAccountAction.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var loginInformation = response.getReturnValue();
          helper.setLoggedIn(component, loginInformation);
          component.set('v.loading', false);
          helper.gotoAuthorizationStep(component, helper, true);
        } else {
          helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        }
      }));
      $A.enqueueAction(setAccountAction);
    } else {
      component.set('v.loading', false);
      helper.gotoAuthorizationStep(component, helper, true);
    }
  },

  logout: function (component) {
    var logoutAction = component.get('c.logout');
    logoutAction.setParams({
      resetUsers: true
    });
    return new Promise($A.getCallback(function (resolve, reject) {
      logoutAction.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var loginInformation = response.getReturnValue();
          resolve(loginInformation);
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(logoutAction);
    }));
  },

  completeSetup: function (component) {
    component.getEvent('reloadEvent').fire();
    component.destroy();
  },

  beginSpringOAuth: function (component) {
    component.set('v.loading', true);
    var beginSpringOAuth = component.get('v.beginSpringOAuth');
    beginSpringOAuth(component);
  },

  endSpringOAuth: function (component, response, loginInformation, helper) {
    if (loginInformation && loginInformation.status !== 'Fail') {
      helper.showToast(component, loginInformation.message, 'success');
      window.setTimeout($A.getCallback(function () {
        component.getEvent('reloadEvent').fire();
        component.destroy();
      }), 3000);
    } else {
      helper.showToast(component, loginInformation.message, 'error');
    }
    component.set('v.loading', false);
  }
});