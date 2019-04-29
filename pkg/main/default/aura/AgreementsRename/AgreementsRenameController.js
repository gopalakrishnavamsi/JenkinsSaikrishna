({
  cancelButtonClicked: function (component, event, helper) {
    helper.close(component, event, helper);
  },

  renameButtonClicked: function (component, event, helper) {
    var renamedName = component.get('v.agreementDetails.name');
    var renameMessage = renamedName + ' has been renamed.';
    helper.showToast(component, renameMessage, 'success');
    helper.close(component, event, helper);
  }
});
