({
  viewAgreement: function (component, event, helper) {
    helper.launchAgreementPreview(component);
  },

  showTimeLine: function (component, event, helper) {
    helper.showHistoryTimeLine(component);
  },

  showInternalApprovalModal: function (component, event, helper) {
    helper.createInternalApprovalComponent(component, event, helper);
  },

  showExternalReviewModal: function (component, event, helper) {
    helper.createExternalReviewComponent(component, event, helper);
  },

  showDeleteModal: function (component, event, helper) {
    helper.createDeleteComponent(component, event, helper);
  },

  showUploadModal: function (component, event, helper) {
    helper.createUploadComponent(component, event, helper);
  },

  showDownloadModal: function (component, event, helper) {
    helper.createDownloadComponent(component, event, helper);
  },

  showRenameModal: function (component, event, helper) {
    helper.createRenameComponent(component, event, helper);
  },

  showShareLinkModal: function (component, event, helper) {
    helper.createShareLinkComponent(component, event, helper);
  }
});
