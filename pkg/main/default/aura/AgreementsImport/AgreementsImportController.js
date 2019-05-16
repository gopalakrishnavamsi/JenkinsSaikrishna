({
  onInit: function(component) {
    component.set("v.currentStep", "1");
    component.set("v.disableSalesforceFileImport", true);
  },

  navigateToFileSelection: function(component, event, helper) {
    helper.getSalesforceFiles(component, event, helper);
  },

  navigateToUploadFilesfromPC: function(component, event, helper) {
    component.set("v.currentStep", "3");
    helper.uploadFile(component);
  },

  backButtonClicked: function(component) {
    component.set("v.currentStep", "1");
  },

  importButtonClicked: function(component, event, helper) {
    helper.publishAgreement(component, event, helper);
  },

  handleFileSelection: function(component, event, helper) {
    //checkbox checked
    if (event.getSource().get("v.checked")) {
      var selectedValue = event.getSource().get("v.value");
      helper.setSelectedFiles(component, selectedValue);
    }
    //checkbox unchecked
    else {
      component.set("v.disableSalesforceFileImport", true);
    }
  },

  uploadFileButtonClicked: function(component) {
    component.set("v.currentStep", "1");
  },

  uploadFileImportButtonClicked: function(component, event, helper) {
    helper.uploadContent(component, event, helper);
  },

  uploadScriptsLoaded: function() {
    // FIXME: Implement or remove.
  },

  cancelButtonClicked: function(component, event, helper) {
    helper.close(component);
  },

  clickDone: function(component, event, helper) {
    helper.completeImport(component, event, helper);
  }
});
