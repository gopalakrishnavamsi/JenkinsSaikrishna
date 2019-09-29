({
  exportAgreementToSalesforce: function (component, event, helper) {
    var agreement = component.get('v.agreementDetails');
    var sendForEsign = component.get('v.sendForEsign');
    var exportSalesforceAction = component.get('c.exportAgreementToSalesforce');
    exportSalesforceAction.setParams({
      sourceId: component.get('v.sourceId'),
      agreementId: agreement && agreement.id ? agreement.id.value : null
    });
    helper.showToast(component, $A.get('$Label.c.AgreementExportProcessing'), 'success');
    exportSalesforceAction.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        if (sendForEsign) {
          //Note : While apringcm export api return file id in response , fileid parameter should be passed instead of blank
          helper.sendForSignature(component, '');
        } else {
          helper.showToast(component, response.getReturnValue().message, 'success');
        }
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(exportSalesforceAction);
  },
  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  },

  sendForSignature: function (component, selectedFileId) {
    var helper = this;
    component.set('v.loading', true);
    var sendingAction = component.get('c.getSendingDeepLink');
    var sourceId = component.get('v.sourceId');
    sendingAction.setParams({
      sourceId: sourceId,
      fileIdsInCommaSeparated: selectedFileId
    });
    sendingAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        navUtils.navigateToUrl(response.getReturnValue());
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(sendingAction);
  }
});
