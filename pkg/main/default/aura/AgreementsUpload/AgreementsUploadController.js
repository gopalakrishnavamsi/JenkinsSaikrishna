({
  onInit: function (component) {
    var agreementVersions = [{
      name: "FreshSoftware-Quote.docx", currentVersion: "Current - 1/1/2019"
    }, {name: "FreshSoftware-Quote.docx", currentVersion: "Original - 1/1/2019"}];
    component.set('v.agreementVersions', agreementVersions);
  },

  cancelButtonClicked: function (component, event, helper) {
    helper.close(component);
  },

  uploadButtonClicked: function (component, event, helper) {
    helper.showToast(component, 'A new version of "Fresh Software-Quote.docx" has been uploaded.', 'success');
    helper.close(component, event, helper);
  },

  uploadScriptsLoaded: function () {
    var options = {
      "iconPath": $A.get('$Resource.scmwidgetsspritemap'),
      "apiToken": "124124124124",
      "apiBaseDomain": "https://apiuploadqana11.springcm.com"
    };
    var uploadWidget = new SpringCM.Widgets.Upload(options);
    uploadWidget.render("#upload-wrapper");
    helper.setUploadEvent(component);
  }

});
