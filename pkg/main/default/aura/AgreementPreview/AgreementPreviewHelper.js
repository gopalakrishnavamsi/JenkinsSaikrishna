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
          })
          .catch(function(error) {
            uiHelper.showToast(error, uiHelper.ToastMode.ERROR);
          });
      } else if (state === 'ERROR') {
        uiHelper.showToast(uiHelper.getErrorMessage(response), uiHelper.ToastMode.ERROR);
        component.set('v.showToolBarAndPreview', false);
      }
      component.set('v.loading', false);
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

  reLoadingEvent: function(component) {
    var isAgreementDeleted = component.get('v.isAgreementDeleted');
    if (isAgreementDeleted) {
       $A.get('e.force:navigateToSObject').setParams({'recordId': component.get('v.sourceId')}).fire();
    } else {
      setTimeout(
        $A.getCallback(function () {
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
