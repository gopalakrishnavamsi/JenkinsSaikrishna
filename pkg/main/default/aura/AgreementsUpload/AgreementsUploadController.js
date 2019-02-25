
({
    onInit: function(component, event, helper) {
        var agreementVersions = [{name: "FreshSoftware-Quote.docx", currentVersion: "Current - 1/1/2019"},
                                 {name: "FreshSoftware-Quote.docx", currentVersion: "Original - 1/1/2019"}];
        component.set('v.agreementVersions', agreementVersions);
        console.log('Entered init');
    },

    cancelButtonClicked: function(component, event, helper) {
        console.log('Cancel button clicked');
        helper.close(component, event, helper);
    },

    uploadButtonClicked: function(component, event, helper) {

    },

    uploadScriptsLoaded: function(component, event, helper) {
        console.log('Scripts uploaded');
        var options = [{iconPath: $A.get('$Resource.scmwidgetsspritemap')}];
        const widget = new SpringCM.Widgets.Upload(options);
        SpringCM.Widgets.Upload.render('#uploadWidget');
    }

})
