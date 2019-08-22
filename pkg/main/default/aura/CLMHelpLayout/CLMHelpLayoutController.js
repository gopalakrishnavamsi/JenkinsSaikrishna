({
    handleEvent: function (component, event) {
        var fromComponent = event.getParam('fromComponent');
        var toComponent = event.getParam('toComponent');
        var type = event.getParam('type');
        var data = event.getParam('data');
        if (toComponent === 'CLMHelpLayout' && fromComponent !== 'CLMHelpLayout') {
            if (type === 'navigation') {
                component.set('v.currentTabId',data.value);
            }
        }
    }
})