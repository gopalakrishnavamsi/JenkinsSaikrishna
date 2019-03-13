({
    doInit: function (component, event, helper) {
        //set the namespace attribute
        var action = component.get('c.getNameSpace');
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.namespace', response.getReturnValue());
            }
            else if (state === "ERROR") {
            }
        });
        $A.enqueueAction(action);
    },

    handleToastEvent: function (component, event, helper) {
        var params = event.getParams();
        if (params && params.show === true) {
            helper.showToast(component, params.message, params.mode);
            if (params.mode === 'success') {
                setTimeout($A.getCallback(function () {
                    helper.hideToast(component);
                }), 3000);
            }
        } else {
            helper.hideToast(component);
        }
    },

    importAgreements: function (component, event, helper) {
        helper.createImportComponent(component, event, helper);
    }
})