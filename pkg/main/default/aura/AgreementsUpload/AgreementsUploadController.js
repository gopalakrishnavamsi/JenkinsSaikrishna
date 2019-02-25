
({
    onInit: function(component, event, helper) {
        var agreementVersions = [{name: "FreshSoftware-Quote.docx", currentVersion: "Current - 1/1/2019"},
                                 {name: "FreshSoftware-Quote.docx", currentVersion: "Original - 1/1/2019"}];
        component.set('v.agreementVersions', agreementVersions);
    },

    cancelButtonClicked: function(component, event, helper) {
        helper.close(component, event, helper);
    },

    uploadButtonClicked: function(component, event, helper) {

    },

    uploadScriptsLoaded: function(component, event, helper) {
        var options = [{iconPath: $A.get('$Resource.scmwidgetsspritemap')}];
        const widget = new SpringCM.Widgets.Upload(options);
        SpringCM.Widgets.Upload.render('#uploadWidget');
    }

})
