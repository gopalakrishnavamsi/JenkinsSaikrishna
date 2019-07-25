({
    toggleSection: function(component, event, helper) {
        var acc = component.find('objMapping');
        for (var cmp in acc) {
            $A.util.toggleClass(acc[cmp], 'slds-show');
            $A.util.toggleClass(acc[cmp], 'slds-hide');
        }
    },
    gotoIntegrationHome: function(component, event, helper) {
        helper.fireApplicationEvent(component, {
            fromComponent: 'CLMMapObjectExpand',
            toComponent: 'CLMSetupLayout',
            type: 'update',
            tabIndex: '3',
        }, 'CLMNavigationEvent');
    }
})