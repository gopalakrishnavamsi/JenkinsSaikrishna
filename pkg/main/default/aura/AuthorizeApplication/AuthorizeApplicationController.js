({
  onInitialize: function (component, event, helper) {
    component.set('v.uiHelper', new UIHelper(function () {
      return component.getEvent('loadingEvent');
    }, function () {
      return component.getEvent('toastEvent');
    }));

    helper.getAuthStatus(component);
  },

  onAuthorize: function (component, event, helper) {
    helper.beginOAuth(component);
  }
});
