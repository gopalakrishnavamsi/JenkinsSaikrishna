({
    onPrimaryButtonClick: function(component, event) {
        var buttonLabel = event.getParam('buttonLabel');
        if (buttonLabel === $A.get('$Label.c.ConfigureLayouts') || $A.get('$Label.c.ConfigureButtons')) {
            if (!navUtils.isLightningOrMobile()) {
                window.open($A.get('$Label.c.LEXObjectManagerURL'));
            } else {
                window.open($A.get('$Label.c.ClassicObjectManagerURL'));
            }
        }
    },
    onSecondaryButtonClick: function(component, event, helper) {
        helper.fireApplicationEvent(component, {
            fromComponent: 'CLMHomeEBody',
            toComponent: 'CLMSetupLayout',
            type: 'update',
            tabIndex: '8',
        }, 'CLMNavigationEvent');
    }
})