({
    onInit: function (component, event, helper) {
        component.set('v.currentStep', '1');
    },

    navigateToFileSelection: function (component, event, helper) {
        helper.getSalesforceFiles(component, event, helper);
    },

    navigateToUploadFilesfromPC: function (component, event, helper) {
        component.set('v.currentStep', '3');
        var options = {
            "iconPath": $A.get('$Resource.scmwidgetsspritemap'),
            "apiToken": "124124124124",
            "apiBaseDomain": "https://apiuploadqana11.springcm.com"
        };
        var uploadWidget = new SpringCM.Widgets.Upload(options);
        uploadWidget.render("#upload-wrapper");
    },

    backButtonClicked: function (component, event, helper) {
        component.set('v.currentStep', '1');
    },

    importButtonClicked: function (component, event, helper) {
    },

    handleFileSelection: function (component, event, helper) {
    },

    uploadFileButtonClicked: function (component, event, helper) {
        component.set('v.currentStep', '1');
    },

    uploadFileImportButtonClicked: function (component, event, helper) {

    },

    uploadScriptsLoaded: function (component, event, helper) {

    },

    cancelButtonClicked: function (component, event, helper) {
        console.log('Cancel Button clicked');
        helper.close(component, event, helper);
    },
})