({
    show: function(component, event, helper){
        component.find('deleteAgreementModal').show();
    },

    hide: function(component, event, helper) {
        component.find('deleteAgreementModal').hide();
    },

    showToast: function (component, message, mode) {
        var evt = component.getEvent('toastEvent');
        evt.setParams({
          show: true, message: message, mode: mode
        });
        evt.fire();
    }
})