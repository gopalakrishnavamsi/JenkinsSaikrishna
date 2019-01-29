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

  setLoading: function (component, isLoading) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: isLoading === true
    });
    evt.fire();
  },

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

    inputs.forEach(function (input, index) {
      if (typeof(input.focus) !== 'undefined') input.focus(); // Force error states

      if (typeof(input.get) !== 'undefined' && !input.get('v.validity').valid) {
        isValid = false;
      }
    });

    component.find(buttonAuraId).focus(); // Force error states; only expecting one component

    return isValid;
  },

  beginOAuth: function (component) {
    this.hideToast(component);
    this.setLoading(component, true);

    var beginOAuth = component.get('v.beginOAuth');
    beginOAuth(component,
      component.get('v.environment') || 'Production',
      component.get('v.otherUrl') || null);
  },

  setLoggedIn: function(component, loginInformation) {
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
    if (response && response.status && loginInformation) {
      this.setLoggedIn(component, loginInformation);
    } else {
      this.showToast(component, response.message, 'error');
    }
    this.setLoading(component, false);
  },

  selectAccount: function (component) {
    this.hideToast(component);
    this.setLoading(component, true);

    var sa = component.get('c.selectAccount');
    sa.setParams({
      environment: component.get('v.environment'),
      otherUrl: component.get('v.otherUrl'),
      selectedAccountNumber: component.get('v.selectedAccountNumber')
    });
    sa.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        this.setLoggedIn(component, response.getReturnValue());
      } else {
        this.showToast(component, _getErrorMessage(response), 'error');
      }
      this.setLoading(component, false);
    });
    $A.enqueueAction(sa);
  },

  logout: function (component) {
    this.hideToast(component);
    this.setLoading(component, true);

    var logout = component.get('c.logout');
    logout.setParams({
      resetUsers: true
    });
    logout.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.login', response.getReturnValue());
        component.set('v.isLoggedIn', false);
        component.set('v.selectedAccountNumber', null);
        component.set('v.login.isTrial', false);
        component.set('v.isTrialExpired', false);
      } else {
        this.showToast(component, _getErrorMessage(response), 'error');
      }
      this.setLogin(component, false);
      this.setLoading(component, false);
    });
    $A.enqueueAction(logout);
  },

  prepareTrial: function (component) {
    this.hideToast(component);
    this.setLoading(component, true);

    var pt = component.get('c.prepareTrial');
    pt.setParams({
      email: component.get('v.login.email')
    });
    pt.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var trialPrep = response.getReturnValue();
        component.set('v.countries', trialPrep.countries);
        component.set('v.marketing', trialPrep.marketing);
        component.set('v.trialAccount', trialPrep.account);
        component.set('v.userCountryCode', trialPrep.account.user.countryCode);
      } else {
        this.showToast(component, _getErrorMessage(response), 'error');
      }
      this.setLoading(component, false);
    });
    $A.enqueueAction(pt);
  },

  startTrial: function (component) {
    this.hideToast(component);

    if (this.getInputValidity(component, 'trial-input', 'trial-button')) {
      this.setLoading(component, true);
      var trial = component.get('v.trialAccount');
      trial.user.email = component.get('v.login.email');

      var st = component.get('c.startTrial');
      st.setParams({
        trialJson: JSON.stringify(trial)
      });
      st.setCallback(this, function (response) {
        var status = response.getState();
        if (status === 'SUCCESS') {
          var account = response.getReturnValue();
          component.set('v.login.isTrial', true);
          component.set('v.selectedAccountNumber', account.accountNumber);
          component.set('v.environment', 'Production');
          component.set('v.otherUrl', null);
          component.set('v.signedUpForTrial', true);
        } else {
          this.showToast(component, _getErrorMessage(response), 'error');
        }
        this.setLoading(component, false);
      });
      $A.enqueueAction(st);
    }
  }
});
