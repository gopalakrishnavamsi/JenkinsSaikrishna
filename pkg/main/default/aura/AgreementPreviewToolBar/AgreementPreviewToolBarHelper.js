({
  exportAgreementToSalesforce: function (component, sendForEsign) {
    try {
      var actions = component.get('v.agreementActionManager');
      var sourceId = component.get('v.sourceId');
      var agreement = component.get('v.agreement');
      actions.exportToSalesforce(agreement, sourceId, sendForEsign, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  }
});