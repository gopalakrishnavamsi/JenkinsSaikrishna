({
    onPrimaryButtonClick: function(component, event, helper) {
        var primaryClicked = component.getEvent('CLMHelpPrimaryButtonClicked');
        var buttonName = event.getSource().get('v.label');
        primaryClicked.setParams({
            cardTitle: component.get('v.title'),
            buttonType: 'primary',
            buttonLabel: buttonName
        });
        primaryClicked.fire()
    },
    onSecondayButtonClick: function(component, event, helper) {
        var secondaryClicked = component.getEvent('CLMHelpSecondaryButtonClicked');
        var buttonName = event.getSource().get('v.label');
        secondaryClicked.setParams({
            cardTitle: component.get('v.title'),
            buttonType: 'secondary',
            buttonLabel: buttonName
        });
        secondaryClicked.fire()
    },
})