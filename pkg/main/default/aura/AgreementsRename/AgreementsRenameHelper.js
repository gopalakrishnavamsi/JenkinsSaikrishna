({
  close: function(component) {
    component.destroy();
  },

  showToast: function(component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  reloadAgreementsSpace: function(component) {
    component.getEvent('reloadEvent').fire();
  },

  renameAgreement: function(component) {
    component.set('v.loading', true);
    var agreementDetails = component.get('v.agreementDetails');
    var action = component.get('c.renameAgreement');
    var self = this;
    action.setParams({
      documentId: agreementDetails.id.value,
      documentName: agreementDetails.name + '.' + agreementDetails.extension
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result === true) {
          var renameMessage = stringUtils.format($A.get('$Label.c.AgreementRenamed_1'), agreementDetails.name);
          self.showToast(component, renameMessage, 'success');
          component.set('v.loading', false);
          self.reloadAgreementsSpace(component);
          self.close(component);
        } else {
          self.showToast(
            component,
            $A.get('$Label.c.AgreementRenameErrorMessage'),
            'error'
          );
          self.reloadAgreementsSpace(component);
          self.close(component);
        }
      } else {
        self.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  }
});
