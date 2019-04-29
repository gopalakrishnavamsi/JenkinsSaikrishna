({
    cancelClicked: function (component, event, helper) {
        helper.close(component, event, helper);
    },

    deleteClicked: function (component, event, helper) {
        helper.deleteAgreement(component, event, helper);
    }
})