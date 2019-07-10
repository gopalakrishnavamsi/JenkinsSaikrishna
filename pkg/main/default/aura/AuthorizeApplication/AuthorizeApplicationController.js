({
  onInitialize: function (component, event, helper) {
    component.set('v.uiHelper', new UIHelper(function () {
      //removed load event call from here as this is before authorized
    }, function () {
      return component.getEvent('toastEvent');
    }));

    helper.getAuthStatus(component);
  },

  onAuthorize: function (component, event, helper) {
    helper.beginOAuth(component);
  }
});
