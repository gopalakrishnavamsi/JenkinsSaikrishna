({
  setLogin: function (component, isLoggedIn) {
    var evt = component.getEvent('loginEvent');
    evt.setParams({
      isLoggedIn: isLoggedIn === true
    });
    evt.fire();
  },

  getInputValidity: function (component, inputAuraId, buttonAuraId) {
    var inputs = component.find(inputAuraId, buttonAuraId);
    var isValid = true;

    inputs = Array.isArray(inputs) ? inputs : [inputs]; // Safety first

    inputs.forEach(function (input) {
      if (typeof (input.focus) !== 'undefined') input.focus(); // Force error states

      if (typeof (input.get) !== 'undefined' && !input.get('v.validity').valid) {
        isValid = false;
      }
    });

    component.find(buttonAuraId).focus(); // Force error states; only expecting one component

    return isValid;
  },

  beginOAuth: function (component) {
    var uiHelper = component.get('v.uiHelper');
    uiHelper.hideToast();
    uiHelper.setLoading(true);

    var beginOAuth = component.get('v.beginOAuth');
    beginOAuth(component, component.get('v.environment') || 'Production', component.get('v.otherUrl') || null);
  },

  beginSpringOAuth: function (component) {
    var uiHelper = component.get('v.uiHelper');
    uiHelper.hideToast();
    uiHelper.setLoading(true);

    var beginSpringOAuth = component.get('v.beginSpringOAuth');
    beginSpringOAuth(component);
  },

  addTrialGenProduct: function (component) {

      var uiHelper = component.get('v.uiHelper');
      uiHelper.hideToast();
      uiHelper.setLoading(true);

       uiHelper.invokeAction(component.get('c.addTrialGen'), null, function (response) {
        if (response && response.status.toLowerCase() === 'success') {
              uiHelper.showToast('success');
            } else {
              uiHelper.showToast('error');
            }
       }, null, function () {
              uiHelper.setLoading(component, false);
            });
      uiHelper.setLoading(component, false);
    },

  setLoggedIn: function (component, loginInformation) {
    var hasAccounts = !$A.util.isEmpty(loginInformation.accounts);
    var isLoggedIn = hasAccounts && loginInformation.status === 'Success';
    if (loginInformation.status === 'SelectAccount' && hasAccounts) {
      component.set('v.showAccountSelectionModal', true);
    }
    component.set('v.login', loginInformation);
    component.set('v.isLoggedIn', isLoggedIn);
    // TODO: Fix trial accounts
    component.set('v.login.isTrial', false);
    component.set('v.isTrialExpired', false);
    if (isLoggedIn) {
      component.set('v.selectedAccountNumber', loginInformation.accounts[0].accountNumber);
      this.setLogin(component, true);
    }
  },

  endOAuth: function (component, response, loginInformation) {
    var uiHelper = component.get('v.uiHelper');
    if (response && response.status && loginInformation) {
      this.setLoggedIn(component, loginInformation);
    } else {
      uiHelper.showToast(response.message, 'error');
    }
    uiHelper.setLoading(component, false);
  },

  endSpringOAuth: function (component, response, loginInformation) {
    var uiHelper = component.get('v.uiHelper');
    if (loginInformation && loginInformation.status !== 'Fail') {
      uiHelper.showToast(loginInformation.message, 'success');
    } else {
      uiHelper.showToast(loginInformation.message, 'error');
    }
    uiHelper.setLoading(component, false);
  },

  selectAccount: function (component) {
    var self = this;
    var uiHelper = component.get('v.uiHelper');
    uiHelper.invokeAction(component.get('c.selectAccount'), {
      environment: component.get('v.environment'),
      otherUrl: component.get('v.otherUrl'),
      selectedAccountNumber: component.get('v.selectedAccountNumber')
    }, function (loginInformation) {
      self.setLoggedIn(component, loginInformation);
    });
  },

  logout: function (component) {
    var self = this;
    component.get('v.uiHelper').invokeAction(component.get('c.logout'), {resetUsers: true}, function (loginInformation) {
      component.set('v.login', loginInformation);
      component.set('v.isLoggedIn', false);
      component.set('v.selectedAccountNumber', null);
      component.set('v.login.isTrial', false);
      component.set('v.isTrialExpired', false);
      self.setLogin(component, false);
    });
  },

  prepareTrial: function (component) {
    component.get('v.uiHelper').invokeAction(component.get('c.prepareTrial'), {email: component.get('v.login.email')}, function (trialPrep) {
      component.set('v.countries', trialPrep.countries);
      component.set('v.marketing', trialPrep.marketing);
      component.set('v.trialAccount', trialPrep.account);
      component.set('v.userCountryCode', trialPrep.account.user.countryCode);
    });
  },

  startTrial: function (component) {
    var uiHelper = component.get('v.uiHelper');
    uiHelper.hideToast();

    if (this.getInputValidity(component, 'trial-input', 'trial-button')) {
      var trial = component.get('v.trialAccount');
      trial.user.email = component.get('v.login.email');

      uiHelper.invokeAction(component.get('c.startTrial'), {trialJson: JSON.stringify(trial)}, function(account) {
        component.set('v.login.isTrial', true);
        component.set('v.selectedAccountNumber', account.accountNumber);
        component.set('v.environment', 'Production');
        component.set('v.otherUrl', null);
        component.set('v.signedUpForTrial', true);
      });
    }
  }
});
