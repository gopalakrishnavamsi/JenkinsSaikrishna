({
  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true, message: message, mode: mode
    });
    evt.fire();
  },

  reloadAgreementsSpace: function (component) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: true
    });
    evt.fire();
  },

  renameAgreement: function (component) {
    component.set('v.loading', true);
    var agreementDetails = component.get('v.agreementDetails');
    var action = component.get('c.renameAgreement');
    var self = this;
    action.setParams({
      documentId: agreementDetails.id.value,
      documentName: agreementDetails.name
    });
    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        if (result === true) {
          var renameMessage = agreementDetails.name + ' ' + $A.get('$Label.c.AgreementRenamed');
          self.showToast(component, renameMessage, 'success');
          component.set('v.loading', false);
          self.reloadAgreementsSpace(component);
          self.close(component);
        } else {
          self.showToast(component, $A.get('$Label.c.AgreementRenameErrorMessage'), 'error');
          self.reloadAgreementsSpace(component);
          self.close(component);
        }
      } else if (state === "ERROR") {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        self.showToast(component, errorMessage, 'error');
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  },

});
