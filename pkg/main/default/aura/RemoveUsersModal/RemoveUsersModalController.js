({
  cancelClicked: function (component, event, helper) {
    helper.close(component);
  },

  removeClicked: function (component, event, helper) {
    helper.invokeRemoveUsers(component, event, helper);
  }
});