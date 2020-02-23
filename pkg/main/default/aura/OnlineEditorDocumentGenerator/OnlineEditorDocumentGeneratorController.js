({
  onChangeIsAuthorized: function (component, event, helper) {
    helper.initDocumentGenerator(component);
  },
  cancelClicked: function (component) {
    navUtils.navigateToSObject(component.get('v.recordId'));
  },
  sendForSignatureClicked: function (component) {
    var sendForSignature = component.get('v.sendForSignature');
    sendForSignature();
  }
});