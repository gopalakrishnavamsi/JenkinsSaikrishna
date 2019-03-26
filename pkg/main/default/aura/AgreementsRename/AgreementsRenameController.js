({
  onInit: function (component) {
    var agreementDetails = {name: "FreshSoftware-Quote.docx"};
    component.set('v.agreementDetails', agreementDetails);
  },

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
