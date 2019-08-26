({
  init: function (component, event, helper) {
    helper.init(component, event, helper);
  },

  selectStep: function (component, event, helper) {
    helper.selectStep(component, event, helper);
  },

  signUp: function (component, event, helper) {
    helper.signUp();
  },

  toggleAdvancedOptions: function (component, event, helper) {
    helper.toggleAdvancedOptions(component);
  },

  loginToProductionDocuSignEnvironment: function (component, event, helper) {
    component.set('v.environment', 'Production');
    helper.beginOAuth(component, event, helper);
  },

  loginToDemoDocuSignEnvironment: function (component, event, helper) {
    component.set('v.environment', 'Demo');
    helper.beginOAuth(component, event, helper);
  },

  loginToOtherDocuSignEnvironment: function (component, event, helper) {
    helper.beginOAuth(component, event, helper);
  },

  handleOAuthEvent: function (component, event, helper) {
    helper.handleOAuthEvent(component, event.getParam('response'), event.getParam('loginInformation'), helper);
  },

  handleLoadingEvent: function (component, event) {
    component.set('v.loading', event.getParam('isLoading'));
  },

  accountSelected: function (component, event, helper) {
    component.set('v.loading', true);
    helper.accountSelected(component, event, helper);
  },

  completeSetup: function (component, event, helper) {
    helper.completeSetup(component);
  },

  completePlatformOAuth: function (component, event, helper) {
    helper.beginSpringOAuth(component);
  },

  handleSpringOAuthEvent: function (component, event, helper) {
    helper.endSpringOAuth(component, event.getParam('response'), event.getParam('loginInformation'), helper);
  },

  gotoSelectAccountStep: function (component, event, helper) {
    helper.goToStep(component, 1);
  },

  gotoLoginStep: function (component, event, helper) {
    helper.goToStep(component, 0);
  }
});