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
  sendForSignatureClicked: function (component) {
    component.set('v.loading', true);
    var sendForSignature = component.get('v.sendForSignature');
    sendForSignature(stringUtils.formatSCMFile(component.get('v.scmFileGuid'), component.get('v.fileName'), 'html'));
  },
  downloadAsWordFileClicked: function (component, event, helper) {
    helper.processDownloadAsWordFile(component);
  }
});
