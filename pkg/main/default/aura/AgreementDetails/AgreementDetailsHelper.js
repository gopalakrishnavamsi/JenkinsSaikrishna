({
  initAgreementActionManager: function (component) {
    //Saving instance of uiHelper
    var uiHelper = new UIHelper(
      function () {
        return component.getEvent('loadingEvent');
      },
      function () {
        return component.getEvent('toastEvent');
      }
    );
    component.set('v.uiHelper', uiHelper);
    //Agreement Action Manager
    var manager = new AgreementActionManager(
      'detailModalContent',
      component.get('v.namespace')
    );
    component.set('v.agreementActionManager', manager);
  },

  createUploadComponent: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      var sourceId = component.get('v.sourceId');
      actions.upload(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  createDownloadComponent: function (component, downloadWithRedlines) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      actions.download(agreement, component, downloadWithRedlines);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  createDeleteComponent: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      actions.delete(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  createInternalApprovalComponent: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      var sourceId = component.get('v.sourceId');
      actions.internalApproval(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  createExternalReviewComponent: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      var sourceId = component.get('v.sourceId');
      actions.externalReview(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  createRenameComponent: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      actions.rename(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  createShareLinkComponent: function (component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      var sourceId = component.get('v.sourceId');
      actions.share(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  showHistoryTimeLine: function (component) {
    var showTimeLine = component.get('v.showTimeLine');
    if (!showTimeLine) {
      component.set('v.showTimeLine', true);
      component.set('v.activityLinkLabel', 'Hide Activity');
      var agreementDetails = component.get('v.agreementDetails');
      component.set('v.agreementHistoryItems', agreementDetails.historyItems);
      var agreementHistoryItems = component.get('v.agreementHistoryItems');
      var historyItems = [];
      Object.assign(historyItems, agreementHistoryItems);
      var options = {
        language: $A.get('$Locale.langLocale') ? $A.get('$Locale.langLocale').toLowerCase() : undefined,
        iconPath: $A.get('$Resource.scmwidgetsspritemap')
      };
      var historyWidget = new SpringCM.Widgets.History(options);
      var historyContainerId =
        '#historyContainer' + component.get('v.agreementIndex');
      historyWidget.render(historyContainerId).setHistoryItems(historyItems);
    } else {
      component.set('v.showTimeLine', false);
      component.set('v.activityLinkLabel', 'Show Activity');
    }
  },

  launchAgreementPreview: function (component) {
    var agreement = component.get('v.agreementDetails');
    var action = component.get('c.redirectToAgreementPreview');
    action.setParams({
      sourceId: component.get('v.sourceId'),
      agreementId: agreement && agreement.id ? agreement.id.value : null
    });
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS')
        navUtils.navigateToUrl(response.getReturnValue());
    });
    $A.enqueueAction(action);
  },

  exportAgreementToSalesforce: function (component, sendForEsign) {
    try {
      var actions = component.get('v.agreementActionManager');
      var sourceId = component.get('v.sourceId');
      var agreement = component.get('v.agreementDetails');
      actions.exportToSalesforce(agreement, sourceId, sendForEsign, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  }
});
