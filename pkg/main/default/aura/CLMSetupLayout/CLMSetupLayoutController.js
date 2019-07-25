({
    onInit: function(component, event, helper) {       
        helper.insertComponent(component, 'c:CLMSidebar', false, false, 'v.sideBar');
        helper.updateUi(component, '1');
    },
    updateState: function(component, event, helper) {
        var tabIndex = event.getParam('tabIndex');
        var fromComponent = event.getParam('fromComponent');
        var toComponent = event.getParam('toComponent');
        var type = event.getParam('type');
        if (toComponent === 'CLMSetupLayout' && fromComponent !== 'CLMSetupLayout') {
            helper.updateUi(component, tabIndex);
        }
    }
})