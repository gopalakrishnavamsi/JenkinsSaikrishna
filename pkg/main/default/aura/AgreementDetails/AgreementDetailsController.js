({
  viewAgreement: function(component, event, helper) {
    console.log('viewing agreement');
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

  showRenameModal: function (component, event, helper) {
    helper.createRenameComponent(component, event, helper);
  },

  showShareLinkModal: function (component, event, helper) {
    helper.createShareLinkComponent(component, event, helper);
  },

  uploadScriptsLoaded: function (component, event, helper) {
    component.set('v.SpringService', SpringCM.Widgets);
  }
});
