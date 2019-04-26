({
  onInit: function (component) {
    component.set('v.salesforceFileSelected', false);
    component.set('v.currentStep', '1');
  },

  navigateToFileSelection: function (component, event, helper) {
    helper.getSalesforceFiles(component, event, helper);
  },

  navigateToUploadFilesfromPC: function (component) {
    component.set('v.currentStep', '3');
    var options = {
      "iconPath": $A.get('$Resource.scmwidgetsspritemap'),
      "apiToken": "124124124124",
      "apiBaseDomain": "https://apiuploadqana11.springcm.com"
    };
    var uploadWidget = new SpringCM.Widgets.Upload(options);
    uploadWidget.render("#upload-wrapper");
  },

  backButtonClicked: function (component) {
    component.set('v.currentStep', '1');
  },

  importButtonClicked: function (component, event, helper) {
    helper.publishAgreement(component);
    helper.reloadAgreementsSpace(component);
    helper.close(component);
  },

  handleFileSelection: function (component, event, helper) {
    if (event.getSource().get("v.checked")) {
      var selectedValue = event.getSource().get("v.value");
      helper.setSelectedFiles(component, selectedValue);
    }
  },

  uploadFileButtonClicked: function (component) {
    component.set('v.currentStep', '1');
  },

  uploadFileImportButtonClicked: function () {
    // FIXME: Implement or remove.
  },

  uploadScriptsLoaded: function () {
    // FIXME: Implement or remove.
  },

  cancelButtonClicked: function (component, event, helper) {
    helper.close(component);
  }
});
