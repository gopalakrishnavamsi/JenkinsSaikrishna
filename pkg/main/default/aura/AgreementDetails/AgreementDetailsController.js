({
  onLoad: function (component, event, helper) {
    helper.initializeResources(component, helper);
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
    var downloadWithRedlines = false;
    helper.createDownloadComponent(component, downloadWithRedlines);
  },

  showDownloadWithRedlinesModal: function (component, event, helper) {
    var downloadWithRedlines = true;
    helper.createDownloadComponent(component, downloadWithRedlines);
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

  sendForSignature: function (component, event, helper) {
    helper.navigateToSendingUrl(component);
  }
});
