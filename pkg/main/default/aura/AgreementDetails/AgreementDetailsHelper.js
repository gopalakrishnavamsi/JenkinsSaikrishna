({
  createUploadComponent: function (component) {
    //FIXME: create a reusable method for creating the components
    $A.createComponent("c:AgreementsUpload", {
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
    $A.createComponent("c:DeleteAgreement", {
      "showModal": true,
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
    $A.createComponent("c:AgreementsExternalReview", {
      "showModal": true,
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
    $A.createComponent("c:AgreementsRename", {
      "showModal": true,
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
  }
});
