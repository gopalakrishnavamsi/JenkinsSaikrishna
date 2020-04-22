({
  onChangeIsAuthorized: function (component, event, helper) {
    helper.initDocumentGenerator(component);
  },
  cancelClicked: function (component, event, helper) {
    var onCancel = component.get('v.onCancel');
    if (onCancel) onCancel();
    helper.deleteDocument(component);
    navUtils.navigateToSObject(component.get('v.recordId'));
  },
  sendForSignatureClicked: function (component, event, helper) {
    component.set('v.loading', true);
    var sendForSignature = component.get('v.sendForSignature');
    helper.deleteDocument(component);
    sendForSignature();
  },
  downloadAsWordFileClicked: function (component, event, helper) {
    helper.processDownloadAsWordFile(component);
  }
});
