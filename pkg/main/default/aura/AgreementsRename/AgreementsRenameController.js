({
  cancelButtonClicked: function (component, event, helper) {
    helper.close(component, event, helper);
  },

  renameButtonClicked: function (component, event, helper) {
    helper.renameAgreement(component, event, helper);
  }
});
