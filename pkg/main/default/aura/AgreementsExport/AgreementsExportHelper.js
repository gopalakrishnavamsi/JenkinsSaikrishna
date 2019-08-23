({
    exportAgreementToSalesforce: function (component, event, helper) {
        var agreement = component.get('v.agreementDetails');
        var exportSalesforceAction = component.get('c.exportAgreementToSalesforce');
        exportSalesforceAction.setParams({
            sourceId: component.get('v.sourceId'),
            agreementId: agreement && agreement.id ? agreement.id.value : null
        });
        helper.showToast(component, $A.get('$Label.c.AgreementExportProcessing'), 'success');
        exportSalesforceAction.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                helper.showToast(component, response.getReturnValue().message, 'success');
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
    }
});
