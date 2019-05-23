({
  getAgreementDetails: function(component) {
    var agreementId = component.get('v.agreementId');
    var action = component.get('c.getNameSpace');
    var uiHelper = new UIHelper(
      function() {
        return component.getEvent('loadingEvent');
      },
      function() {
        return component.getEvent('toastEvent');
      }
    );
    component.set('v.uiHelper', uiHelper);
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var manager = new AgreementActionManager(
          'modalContent',
          response.getReturnValue()
        );
        manager
          .getAgreement(component, agreementId)
          .then(function(agreement) {
            component.set('v.agreement', agreement);
            component.set('v.agreementActionManager', manager);
            component.set('v.loading', false);
          })
          .catch(function(error) {
            uiHelper.showToast(uiHelper.ToastMode.ERROR, error);
          });
      } else if (state === 'ERROR')
        uiHelper.showToast(
          uiHelper.ToastMode.ERROR,
          uiHelper.getErrorMessage(response)
        );
    });
    $A.enqueueAction(action);
  },

  showToast: function(component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.set('v.showToast', true);
  },

  hideToast: function(component) {
    component.find('toast').close();
  },

  loadingEvent: function(component, event) {
    var params = event.getParams();
    if (params && params.isLoading === true) {
      setTimeout(
        $A.getCallback(function() {
          window.location.reload();
        }),
        2000
      );
    }
  },

  toastEvent: function(component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
      if (params.mode === 'success') {
        setTimeout(
          $A.getCallback(function() {
            helper.hideToast(component);
          }),
          3000
        );
      }
    } else {
      helper.hideToast(component);
    }
  }
});
