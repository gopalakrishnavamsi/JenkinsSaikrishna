({
  downloadAgreement: function(component, event, helper) {
    var agreement = component.get("v.agreementDetails");
    var limitedAccessToken = component.get("c.generateDownloadToken");
    limitedAccessToken.setParams({
      objectId: agreement.id.value
    });
    limitedAccessToken.setCallback(this, function(response) {
      var state = response.getState();
      var result = response.getReturnValue();
      if (state === "SUCCESS") {
        try {
          var downloadWidget = SpringCM.Widgets.Download.downloadDocument(
            result.apiBaseUrl,
            result.token,
            result.accountId.value,
            agreement.id.value,
            agreement.name
          );
          downloadWidget
            .then(function() {
              helper.showToast(
                component,
                $A.get("$Label.c.SuccessDownloadingFile") +
                  " " +
                  agreement.name,
                "success"
              );
            })
            .catch(function() {
              helper.showToast(
                component,
                $A.get("$Label.c.ErrorDownloadingFile"),
                "error"
              );
            });
        } catch (error) {
          helper.showToast(component, error, "error");
        }
      } else {
        var errorMessage = $A.get("$Label.c.ErrorMessage");
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get("$Label.c.UnknownError");
        }
        helper.showToast(component, errorMessage, "error");
      }
    });
    $A.enqueueAction(limitedAccessToken);
  },
  showToast: function(component, message, mode) {
    var fireToastEvent = component.getEvent("toastEvent");
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  }
});
