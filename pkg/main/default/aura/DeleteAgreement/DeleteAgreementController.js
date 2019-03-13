({
    backButtonClicked: function (component, event, helper) {
        helper.close(component, event, helper);
    },

    nextButtonClicked: function (component, event, helper) {
        //display toast notification
        helper.showToast(component, 'File "Sample-File-01" was deleted.', 'success');
        helper.close(component, event, helper);
    }
})