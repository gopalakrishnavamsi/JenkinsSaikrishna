({
  exportAgreementToSalesforce: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var sourceId = component.get('v.sourceId');
      var agreement = component.get('v.agreement');
      actions.exportToSalesforce(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  loadAgreementStatusTypes: function (component) {
    var action = component.get('c.getAgreementStatusTypes');
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.AgreementStatusTypes', response.getReturnValue());
      }
    });
    $A.enqueueAction(action);
  },

  navigateToSendingUrl: function (component) {
    var sendingAction = component.get('c.getSendingDeepLink');
    var sourceId = component.get('v.sourceId');
    var agreement = component.get('v.agreement');
    sendingAction.setParams({
      sourceId: sourceId,
      files: [stringUtils.formatSCMFile(agreement.id.value, agreement.name, agreement.extension)]
    });
    sendingAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        navUtils.navigateToUrl(response.getReturnValue());
      } else {
        var uiHelper = component.get('v.uiHelper');
        uiHelper.showToast(stringUtils.getErrorMessage(response), uiHelper.ToastMode.ERROR);
      }
    });
    $A.enqueueAction(sendingAction);
  }
});