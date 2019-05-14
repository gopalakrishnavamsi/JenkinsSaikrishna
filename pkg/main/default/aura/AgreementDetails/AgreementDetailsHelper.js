({
  createUploadComponent: function (component) {
    //FIXME: create a reusable method for creating the components
    $A.createComponent("c:AgreementsUploadNewVersion", {
      "showModal": true,
    }, function (componentBody) {
      if (component.isValid()) {
        var targetCmp = component.find('uploadModal');
        var body = targetCmp.get("v.body");
        targetCmp.set("v.body", []);
        body.push(componentBody);
        targetCmp.set("v.body", body);
      }
    });
  },

  createDeleteComponent: function (component) {
    var agreementDetails = component.get('v.agreementDetails');
    $A.createComponent("c:AgreementsDelete", {
      "showModal": true,
      "agreementDetails": agreementDetails
    }, function (componentBody) {
      if (component.isValid()) {
        var targetCmp = component.find('deleteModal');
        var body = targetCmp.get("v.body");
        targetCmp.set("v.body", []);
        body.push(componentBody);
        targetCmp.set("v.body", body);
      }
    });
  },

  createInternalApprovalComponent: function (component) {
    $A.createComponent("c:AgreementsInternalReview", {
      "showModal": true,
    }, function (componentBody) {
      if (component.isValid()) {
        var targetCmp = component.find('internalApprovalModal');
        var body = targetCmp.get("v.body");
        targetCmp.set("v.body", []);
        body.push(componentBody);
        targetCmp.set("v.body", body);
      }
    });
  },

  createExternalReviewComponent: function (component) {
    var agreementDetails = component.get('v.agreementDetails');
    $A.createComponent("c:AgreementsExternalReview", {
      "showModal": true,
      "agreementDetails": agreementDetails
    }, function (componentBody) {
      if (component.isValid()) {
        var targetCmp = component.find('externalReviewModal');
        var body = targetCmp.get("v.body");
        targetCmp.set("v.body", []);
        body.push(componentBody);
        targetCmp.set("v.body", body);
      }
    });
  },

  createRenameComponent: function (component) {
    var agreementDetails = component.get('v.agreementDetails');
    $A.createComponent("c:AgreementsRename", {
      "showModal": true,
      "agreementDetails": agreementDetails
    }, function (componentBody) {
      if (component.isValid()) {
        var targetCmp = component.find('renameModal');
        var body = targetCmp.get("v.body");
        targetCmp.set("v.body", []);
        body.push(componentBody);
        targetCmp.set("v.body", body);
      }
    });
  },

  createShareLinkComponent: function (component) {
    $A.createComponent("c:AgreementsShareLink", {
      "showModal": true,
    }, function (componentBody) {
      if (component.isValid()) {
        var targetCmp = component.find('shareLinkModal');
        var body = targetCmp.get("v.body");
        targetCmp.set("v.body", []);
        body.push(componentBody);
        targetCmp.set("v.body", body);
      }
    });
  },

  showHistoryTimeLine: function (component) {
    var showTimeLine = component.get("v.showTimeLine");
    if (!showTimeLine) {
      component.set("v.showTimeLine", true);
      component.set('v.activityLinkLabel', "Hide Activity");
      var agreementDetails = component.get('v.agreementDetails');
      component.set('v.agreementHistoryItems', agreementDetails.historyItems);
      var agreementHistoryItems = component.get('v.agreementHistoryItems');
      var historyItems = [];
      Object.assign(historyItems, agreementHistoryItems);
      var options = {"iconPath": $A.get('$Resource.scmwidgetsspritemap')};
      var historyWidget = new SpringCM.Widgets.History(options);
      var historyContainerId = '#historyContainer' + component.get('v.agreementIndex');
      historyWidget.render(historyContainerId).setHistoryItems(historyItems);

    } else {
      component.set("v.showTimeLine", false);
      component.set('v.activityLinkLabel', "Show Activity");
    }
  },

  launchAgreementPreview: function(component, event) {
    var agreement = component.get('v.agreementDetails');
    var action = component.get('c.redirectToAgreementPreview');
    action.setParams({
      sourceId: component.get('v.sourceId'),
      agreementId: agreement && agreement.id ? agreement.id.value : null
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') navUtils.navigateToUrl(response.getReturnValue());
    });
    $A.enqueueAction(action);
  }
});
