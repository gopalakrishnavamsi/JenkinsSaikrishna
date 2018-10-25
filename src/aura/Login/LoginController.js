({
  initialize: function (component, event, helper) {
    component.set('v.helpInfo', '');
    var env = component.get('v.login.environment');
    component.set('v.advancedOptionsExpanded', !$A.util.isEmpty(env) && env !== 'Production');
  },

  loginToDocuSign: function (component, event, helper) {
    helper.login(component, helper);
  },

  logoutOfDocuSign: function (component, event, helper) {
    component.set('v.showLogoutModal', false);

    setTimeout($A.getCallback(function () { // Wait for modal to hide
      helper.logout(component, helper);
    }), 300);
  },

  selectAccount: function (component, event, helper) {
    component.set('v.showAccountSelectionModal', false);
    helper.login(component, helper);
  },

  cancelSelectAccount: function (component, event, helperz) {
    component.set('v.showAccountSelectionModal', false);
  },

  getStarted: function (component, event, helper) {
    helper.startTrial(component, helper);
  },

  showLogoutModal: function (component, event, helper) {
    helper.hideToast(component);
    component.set('v.showLogoutModal', true);
  },

  hideLogoutModal: function (component, event, helper) {
    component.set('v.showLogoutModal', false);
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
        helper.prepareTrial(component, helper);
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
  },

  handleUserCountryChange: function (component, event, helper) {
    var marketing = component.get('v.marketing');
    if (!$A.util.isEmpty(marketing)) {
      var countryCode = component.get('v.userCountryCode');
      var countryMarketing = marketing.hasOwnProperty(countryCode) ? marketing[countryCode] : marketing['DEFAULT'];
      component.set('v.marketingOptInEnabled', countryMarketing.showOptIn === true);
      var user = component.get('v.trialAccount.user');
      user.countryCode = countryCode;
      user.marketingOptIn = countryMarketing.defaultOptIn === true;
      component.set('v.trialAccount.user', user);
    }
  }
});
