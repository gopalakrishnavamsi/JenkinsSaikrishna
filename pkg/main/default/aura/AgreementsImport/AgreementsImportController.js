({
  initialize: function (component, event, helper) {
    helper.initialize(component);
  },

  initializeSalesforceFileImport: function (component, event, helper) {
    helper.fetchSalesforceFiles(component, event, helper);
  },

  initializePcFileImport: function (component, event, helper) {
    helper.setupFileUploadWidget(component, event, helper);
  },

  salesforceFileImportTriggered: function (component, event, helper) {
    helper.importSalesforceFile(component, event, helper);
  },

  pcFileImportTriggered: function (component, event, helper) {
    helper.importFileFromPc(component, event, helper);
  },

  salesforceFileCheckboxToggle: function (component, event, helper) {
    //checkbox checked
    if (event.getSource().get('v.checked')) {
      var selectedValue = event.getSource().get('v.value');
      helper.setSelectedFiles(component, selectedValue);
    }
    //checkbox unchecked
    else {
      component.set('v.disableSalesforceFileImport', true);
    }
  },

  doneButtonClicked: function (component, event, helper) {
    helper.completeImport(component, event, helper);
  },

  navigateToFirstStep: function (component) {
    component.set('v.currentStep', '1');
  },

  cancelButtonClicked: function (component, event, helper) {
    helper.close(component);
  },

  backButtonClicked: function (component) {
    component.set('v.currentStep', '1');
  },

  navigateToSendForSignature: function (component, event, helper) {
    if (component.get('v.isESignatureEnabled')) {
      helper.navigateToSendForSignature(component, event, helper);
    }
  },

  sendForActivityAfterUpload: function (component, event, helper) {
    helper.sendForActivityAfterUpload(component, event);
  },

  // when agreement details data is loaded, initiate a workflow based on the activity type that was set post-import
  onAgreementDetailsChange: function (component, event, helper) {
    var agreementDetails = component.get('v.agreementDetails');
    var activity = component.get('v.activityAfterUpload');
    var allowActivity = !$A.util.isUndefinedOrNull(agreementDetails) && !$A.util.isUndefinedOrNull(activity);
    if (allowActivity) {
      helper.initiateActivityAfterUpload(component, activity);
    }
  }

});
