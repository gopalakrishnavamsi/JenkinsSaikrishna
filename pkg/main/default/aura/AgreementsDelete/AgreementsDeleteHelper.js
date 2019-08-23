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

  deleteAgreement: function(component) {
    component.set('v.loading', true);
    var agreementDetails = component.get('v.agreementDetails');
    var action = component.get('c.deleteAgreement');
    var self = this;
    action.setParams({
      documentId: agreementDetails.id.value
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result === true) {
          var deleteMessage =
            stringUtils.format(
              $A.get('$Label.c.AgreementDeleted'), agreementDetails.name
            );
          self.showToast(component, deleteMessage, 'success');
          component.set('v.loading', false);
          self.reloadAgreementsSpace(component);
          self.close(component);
        } else {
          self.showToast(
            component,
            $A.get('$Label.c.AgreementDeleteErrorMessage'),
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
