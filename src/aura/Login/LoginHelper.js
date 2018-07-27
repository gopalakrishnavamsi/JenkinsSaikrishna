({
  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true, message: message, mode: mode
    });
    evt.fire();
  },

  hideToast: function (component) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: false
    });
    evt.fire();
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

  login: function (component, helper) {
    helper.hideToast(component);

    if (helper.getInputValidity(component, 'password-input', 'login-button')) {
      var loginToDocuSign = component.get('c.login');
      var accountNumber = component.get('v.login.accountNumber');

      loginToDocuSign.setParams({
        dsUsername: component.get('v.login.email'),
        dsPassword: component.get('v.password'),
        dsEnvironment: component.get('v.login.environment'),
        dsUrl: component.get('v.login.otherUrl'),
        dsAccountNumber: $A.util.isEmpty(accountNumber) ? null : accountNumber
      });

      loginToDocuSign.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          var result = response.getReturnValue();
          if (result.status === 'SelectAccount' && !$A.util.isEmpty(result.accountOptions)) {
            component.set('v.associatedAccounts', result.accountOptions);
            component.set('v.showAccountSelectionModal', true);
          } else {
            component.set('v.login.loggedIn', true);
            component.set('v.login.accountNumber', result.accountOptions[0].accountNumber);
          }
        } else {
          helper.showToast(component, _getErrorMessage(response), 'error');
        }
      });
      $A.enqueueAction(loginToDocuSign);
    }
  },

  logout: function (component, helper) {
    helper.hideToast(component);

    var logout = component.get('c.logout');

    logout.setParams({
      resetUsers: true
    });

    logout.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var cur = component.get('v.login');
        component.set('v.login', {
          isLoggedIn: false,
          email: cur.email,
          accountNumber: null,
          environment: cur.environment,
          otherUrl: cur.otherUrl,
          isTrial: false,
          trialStatus: null
        });
        component.set('v.password', null);
        component.set('v.associatedAccounts', []);
        setTimeout($A.getCallback(function () {
          component.find('login-input').focus();
        }), 1);
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(logout);
  },

  startTrial: function (component, helper) {
    helper.hideToast(component);

    if (helper.getInputValidity(component, 'trial-input', 'trial-button')) {
      var st = component.get('c.startTrial');

      st.setParams({
        email: component.get('v.login.email')
      });

      st.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          var account = response.getReturnValue();
          component.set('v.login.isTrial', true);
          component.set('v.login.accountNumber', account.accountNumber);
          component.set('v.signedUpForTrial', true);
        } else {
          helper.showToast(component, _getErrorMessage(response), 'error');
        }
      });
      $A.enqueueAction(st);
    }
  }
});
