({
  cancelClicked: function (component, event, helper) {
    helper.navigateToObjectHome(component);
  },
  deleteClicked: function (component, event, helper) {
    helper.deleteTemplate(component);
  }
});
