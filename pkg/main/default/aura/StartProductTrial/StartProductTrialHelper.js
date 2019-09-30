({
  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  startProductTrial: function (component, event, helper) {
    if (component.get('v.startGenTrial') === true) {
      helper.startGenTrial(component, event, helper);
    } else if (component.get('v.startNegotiateTrial') === true) {
      helper.startNegotiateTrial(component, event, helper);
    }
  },

  startGenTrial: function (component, event, helper) {
    component.set('v.loading', true);
    var genTrialAction = component.get('c.addTrialGen');
    var successModalMessage = $A.get('$Label.c.GenTrialStarted');

    genTrialAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(component, successModalMessage, 'success');
        component.set('v.loading', false);
        helper.reloadPage();
        helper.close(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        component.set('v.loading', false);
        helper.close(component);
      }
    });
    $A.enqueueAction(genTrialAction);
  },

  startNegotiateTrial: function (component, event, helper) {
    component.set('v.loading', true);
    var negotiateTrialAction = component.get('c.addTrialNegotiate');
    var successModalMessage = $A.get('$Label.c.NegotiateTrialStarted');

    negotiateTrialAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(component, successModalMessage, 'success');
        component.set('v.loading', false);
        helper.reloadPage();
        helper.close(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        component.set('v.loading', false);
        helper.close(component);
      }
    });
    $A.enqueueAction(negotiateTrialAction);
  },

  reloadPage: function () {
    setTimeout(
      $A.getCallback(function () {
        window.location.reload();
      }),
      2000
    );
  }
});