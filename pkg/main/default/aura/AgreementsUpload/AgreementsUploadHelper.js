({
    close: function(component, event, helper) {
        console.log('In destroy');
        component.destroy();
    },

    showToast: function (component, message, mode) {
        var evt = component.getEvent('toastEvent');
        evt.setParams({
          show: true, message: message, mode: mode
        });
        evt.fire();
    }
})