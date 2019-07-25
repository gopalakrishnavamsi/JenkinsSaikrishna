({
    fireComponentEvent: function(component, event, helper) {
        var index = event.currentTarget.id;
        component.set('v.currentIndex', index);
        helper.fireApplicationEvent(component, {
            fromComponent: 'CLMSidebar',
            toComponent: 'CLMSetupLayout',
            type: 'update',
            tabIndex: index,
        }, 'CLMNavigationEvent');
    },
    updateState: function(component, event, helper) {
        var tabIndex = event.getParam('tabIndex');
        var fromComponent = event.getParam('fromComponent');
        var toComponent = event.getParam('toComponent');
        var type = event.getParam('type');
        if (toComponent === 'CLMSetupLayout' && fromComponent !== 'CLMSetupLayout') {
            component.set('v.currentIndex', tabIndex);
        }
    }
})