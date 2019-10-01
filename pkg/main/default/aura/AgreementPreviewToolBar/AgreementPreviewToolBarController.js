({
  rename: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.rename(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  delete: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.delete(agreement, component);
      component.set('v.isAgreementDeleted', true);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  internalApproval: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      var sourceId = component.get('v.sourceId');
      actions.internalApproval(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  externalReview: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      var sourceId = component.get('v.sourceId');
      actions.externalReview(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  upload: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      var sourceId = component.get('v.sourceId');
      actions.upload(agreement, sourceId, component);

    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  share: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var sourceId = component.get('v.sourceId');
      var agreement = component.get('v.agreement');
      actions.share(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  download: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.download(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  addToSalesforce: function (component, event, helper) {
    var sendForEsign = false;
    helper.exportAgreementToSalesforce(component, sendForEsign);
  },

  backToSourceRecord: function (component) {
    $A.get('e.force:navigateToSObject').setParams({'recordId': component.get('v.sourceId')}).fire();
  },

  sendForSignature: function (component, event, helper) {
    var sendForEsign = true;
    helper.exportAgreementToSalesforce(component, sendForEsign);
  }

});
