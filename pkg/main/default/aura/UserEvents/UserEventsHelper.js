({
  setUIHelper: function (component) {
    component.set('v.uiHelper', new UIHelper(function () {
      return component.getEvent('loadingEvent');
    }, function () {
      return component.getEvent('toastEvent');
    }));
  },

  setUserEvents: function (component) {
    var uiHelper = component.get('v.uiHelper');
    if ($A.util.isUndefinedOrNull(uiHelper)) return;

    uiHelper.invokeAction(component.get('c.getUserProperties'), null, function (userProperties) {
      var ue = new UserEvents(
        userProperties.application,
        userProperties.version,
        userProperties.environment,
        userProperties.accountIdHash,
        userProperties.userIdHash);
      component.set('v.userEvents', ue);
      component.set('v.Status', ue.Status);

      var readyEvent = component.getEvent('userEventsReadyEvent');
      readyEvent.setParam('userEvents', ue);
      readyEvent.fire();
    });
  }
});
