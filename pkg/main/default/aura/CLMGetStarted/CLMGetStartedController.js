({
    gotoHome: function(component, event, helper) {
        //fire event to display CLMCardModel
        helper.fireApplicationEvent(component, {
            fromComponent: 'CLMGetStarted',
            toComponent: 'CLMSetupLayout',
            type: 'update',
            tabIndex: '2',
        }, 'CLMNavigationEvent');
    }
})