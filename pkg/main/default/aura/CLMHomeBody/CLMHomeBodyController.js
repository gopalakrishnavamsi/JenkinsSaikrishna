({
    onPrimaryButtonClick: function(component, event, helper) {
        var cardTitle = event.getParam('cardTitle');
        var buttonType = event.getParam('buttonType');
        var buttonLabel = event.getParam('buttonLabel');
        if (buttonLabel === $A.get("$Label.c.ConfigureLayouts") || $A.get("$Label.c.ConfigureButtons")) {
            if (!navUtils.isLightningOrMobile()) {
                window.open($A.get("$Label.c.LEXObjectManagerURL"));
            } else {
                window.open($A.get("$Label.c.ClassicObjectManagerURL"));
            }
        }
    },
    onSecondaryButtonClick: function(component, event, helper) {
        var cardTitle = event.getParam('cardTitle');
        var buttonType = event.getParam('buttonType');
        var buttonLabel = event.getParam('buttonLabel');

        helper.fireApplicationEvent(component, {
            fromComponent: 'CLMHomeEBody',
            toComponent: 'CLMSetupLayout',
            type: 'update',
            tabIndex: '8',
        }, 'CLMNavigationEvent');
    }
})