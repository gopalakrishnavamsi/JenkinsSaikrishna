({
  cancelClicked: function (component, event, helper) {
    helper.redirectToCancelUrl(component);
  },
  deleteClicked: function (component, event, helper) {
    helper.deleteTemplate(component);
  }
});