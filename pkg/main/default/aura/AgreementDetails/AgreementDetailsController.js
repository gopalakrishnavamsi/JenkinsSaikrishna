({
  onLoad: function(component, event, helper) {
    helper.initAgreementActionManager(component);
  },

  viewAgreement: function (component, event, helper) {
    helper.launchAgreementPreview(component);
  },

  showTimeLine: function (component, event, helper) {
    helper.showHistoryTimeLine(component);
  },

  showInternalApprovalModal: function (component, event, helper) {
    helper.createInternalApprovalComponent(component);
  },

  showExternalReviewModal: function (component, event, helper) {
    helper.createExternalReviewComponent(component);
  },

  showDeleteModal: function (component, event, helper) {
    helper.createDeleteComponent(component);
  },

  showUploadModal: function (component, event, helper) {
    helper.createUploadComponent(component);
  },

  showDownloadModal: function (component, event, helper) {
    helper.createDownloadComponent(component);
  },

  showRenameModal: function (component, event, helper) {
    helper.createRenameComponent(component);
  },

  showShareLinkModal: function (component, event, helper) {
    helper.createShareLinkComponent(component);
  },

  showAddToSalesforceModal: function (component, event, helper) {
    helper.exportAgreementToSalesforce(component);
  },

});
