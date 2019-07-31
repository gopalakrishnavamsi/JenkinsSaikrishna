({
    exportAgreementToSalesforce: function (component, event, helper) {
        var agreement = component.get('v.agreementDetails');
        var exportSalesforceAction = component.get('c.exportAgreementToSalesforce');
        exportSalesforceAction.setParams({
            sourceId: component.get('v.sourceId'),
            agreementId: agreement && agreement.id ? agreement.id.value : null
        });
        helper.showToast(component, $A.get('$Label.c.AgreementExportProcessing'),'success');
        exportSalesforceAction.setCallback(this, function (response) {
            var state = response.getState();
            var result = response.getReturnValue();
            if (state === 'SUCCESS') {
                helper.showToast(component, result.message,'success');
            } else {
                var errorMessage = $A.get('$Label.c.ErrorMessage');
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMessage += errors[0].message;
                    }
                } else {
                    errorMessage += $A.get('$Label.c.UnknownError');
                }
                helper.showToast(component, errorMessage, 'error');
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
})
