({
    backButtonClicked: function(component, event, helper) {
        helper.hide(component, event, helper);
    },

    nextButtonClicked: function(component, event, helper) {
        //If successful hide the component
        helper.hide(component, event, helper);
        //display toast notification
        helper.showToast(component, 'File "Sample-File-01" was deleted.', 'success');
    }
})