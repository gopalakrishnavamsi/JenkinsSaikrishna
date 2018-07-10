({
  getDocuSignAccount: function (component, event, helper) {
    var getAccount = component.get('c.getAccount');
    var accountNumber = component.get('v.section.steps[0].accountNumber');
    var emailAddress = component.get('v.section.steps[0].emailAddress');
    component.set('v.accountNumber', accountNumber);
    component.set('v.emailAddress', emailAddress);

    component.set('v.showLoginSpinner', true);
    getAccount.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var account = response.getReturnValue();
        if (account.isTrial) {
          component.set('v.trialMessage', account.trialStatus.message);
          component.set('v.trialIsExpired', account.trialStatus.isExpired);
        }
        component.set('v.isTrial', account.isTrial);
        component.set('v.loggedIn', true);
        component.set('v.showLoginSpinner', false);
      } else {
        helper.setError(component, response);
      }
    });
    $A.enqueueAction(getAccount);
  },

  setContinueButtonState: function (component, event, helper) {
    component.set('v.continueButtonDisabled', !component.get('v.loggedIn'));
  },

  getInputValidity: function (component, inputAuraId, buttonAuraId) {
    var inputs = component.find(inputAuraId, buttonAuraId);
    var isValid = true;

    inputs = Array.isArray(inputs) ? inputs : [inputs]; // Safety first

    inputs.forEach(function (input, index) {
      if (typeof(input.focus) !== 'undefined') input.focus(); // Force error states

      if (typeof(input.get) !== 'undefined' && !input.get('v.validity').valid) {
        isValid = false;
      }
    });

    component.find(buttonAuraId).focus(); // Force error states; only expecting one component

    return isValid;
  },

  login: function (component, event, helper) {
    component.set('v.showToast', false);
    if (helper.getInputValidity(component, 'password-input', 'login-button')) {
      component.set('v.showLoginSpinner', true);
      var loginToDocuSign = component.get('c.login');
      var accountNumber = component.get('v.accountNumber');

      loginToDocuSign.setParams({
        dsUsername: component.get('v.emailAddress'),
        dsPassword: component.get('v.password'),
        dsEnvironment: component.get('v.environment'),
        dsUrl: component.get('v.otherUrl'),
        dsAccountNumber: $A.util.isEmpty(accountNumber) ? null : accountNumber
      });

      loginToDocuSign.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          var result = response.getReturnValue();
          if (result.status === 'SelectAccount' && !$A.util.isEmpty(result.accountOptions)) {
            component.set('v.associatedAccounts', accountOptions);
            component.set('v.showAccountSelectionModal', true);
            component.set('v.showLoginSpinner', false);
          } else {
            component.set('v.accountNumber', result.accountOptions[0].accountNumber);
            helper.saveData(component, event, helper);
            helper.getDocuSignAccount(component, event, helper);
          }
        } else {
          helper.setError(component, response);
        }
      });
      $A.enqueueAction(loginToDocuSign);
    }

  },

  saveData: function (component, event, helper) {
    var accountNumber = component.get('v.accountNumber');
    var emailAddress = component.get('v.emailAddress');
    var loggedIn = component.get('v.loggedIn');

    component.set('v.section.steps[0].accountNumber', accountNumber);
    component.set('v.section.steps[0].emailAddress', emailAddress);
    component.set('v.section.steps[0].loggedIn', loggedIn);
    if (!loggedIn) {
      component.set('v.section.steps[0].isComplete', false);
      component.set('v.section.status', 'notStarted');
    }
    //Fire Save event that triggers backend save on SetupAssistant
    var save = component.getEvent('saveToBackend');
    save.fire();
  },

  setError: function (component, response) {
    if (component && response) {
      var errors = response.getError();
      var errMsg = errors;
      if (!$A.util.isEmpty(errors)) {
        errMsg = errors[0].message;
      }
      console.error(errMsg);
      component.set('v.message', errMsg);
      component.set('v.mode', 'error');
      component.set('v.showLoginSpinner', false);
      component.set('v.showToast', true);
    }
  }
});
