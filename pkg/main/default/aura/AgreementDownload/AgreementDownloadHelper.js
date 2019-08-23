({
  downloadAgreement: function (component, event, helper) {
    var agreement = component.get('v.agreementDetails');
    var limitedAccessToken = component.get('c.generateDownloadToken');
    limitedAccessToken.setParams({
      objectId: agreement.id.value
    });
    limitedAccessToken.setCallback(this, function (response) {
      var state = response.getState();
      var result = response.getReturnValue();
      if (state === 'SUCCESS') {
        try {
          var downloadWidget = SpringCM.Widgets.Download.downloadDocument(
            result.apiDownloadBaseUrl,
            result.token,
            result.accountId.value,
            agreement.id.value,
            agreement.name
          );
          downloadWidget
            .then(function () {
              helper.showToast(
                component,
                stringUtils.format('{0} {1}', $A.get('$Label.c.SuccessDownloadingFile'), agreement.name),
                'success'
              );
            })
            .catch(function () {
              helper.showToast(
                component,
                $A.get('$Label.c.ErrorDownloadingFile'),
                'error'
              );
            });
        } catch (error) {
          helper.showToast(component, error, 'error');
        }
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(limitedAccessToken);
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
