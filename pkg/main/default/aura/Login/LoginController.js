({
  initialize: function (component, event, helper) {
    component.set('v.helpInfo', '');
    var env = component.get('v.environment');
    component.set('v.advancedOptionsExpanded', !$A.util.isEmpty(env) && env !== 'Production');
    var login = component.get('v.login');
    if (!$A.util.isUndefinedOrNull(login) && !$A.util.isEmpty(login.accounts)) {
      component.set('v.selectedAccountNumber', login.accounts[0].accountNumber);
    }
  },

  loginToDocuSign: function (component, event, helper) {
    helper.beginOAuth(component);
  },

  logoutOfDocuSign: function (component, event, helper) {
    component.set('v.showLogoutModal', false);

    setTimeout($A.getCallback(function () { // Wait for modal to hide
      helper.logout(component);
    }), 300);
  },

  selectAccount: function (component, event, helper) {
    component.set('v.showAccountSelectionModal', false);
    helper.selectAccount(component);
  },

  cancelSelectAccount: function (component, event, helperz) {
    component.set('v.showAccountSelectionModal', false);
  },

  getStarted: function (component, event, helper) {
    helper.startTrial(component);
  },

  showLogoutModal: function (component, event, helper) {
    helper.hideToast(component);
    component.set('v.showLogoutModal', true);
  },

  hideLogoutModal: function (component, event, helper) {
    component.set('v.showLogoutModal', false);
  },

  swapLogInState: function (component, event, helper) {
      var navEvt = $A.get('e.force:navigateToURL');
      if (!$A.util.isEmpty(navEvt)) {
           navEvt.setParams({
           'url': 'https://go.docusign.com/PARTNERS/SALESFORCE/?TGR=ESSENTIALS-COBRANDED'
           }
           });
       navEvt.fire();
      }
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
        'url': 'https://go.docusign.com/cobranded/salesforce/essentials/'
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
  },

  handleOAuthEvent: function (component, event, helper) {
    helper.endOAuth(component, event.getParam('response'), event.getParam('loginInformation'));
  }
});
