({
  onLoad: function (component) {
    var uiHelper = new UIHelper(
      function () {
        return component.getEvent('loadingEvent');
      },
      function () {
        return component.getEvent('toastEvent');
      }
    );
    component.set('v.uiHelper', uiHelper);
  },

  cancelClicked: function (component, event, helper) {
    helper.cancel(component, event, helper);
  },

  deleteClicked: function (component, event, helper) {
    helper.delete(component, event, helper);
  }

});
