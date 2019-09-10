({
	navigateToSection: function (component, event, helper) {
		var tabIndex, eventHandlerComponent;
		if (component.get('v.hyperlinkedText') === $A.get('$Label.c.DocumentGeneration')) {
			tabIndex = 4;
			eventHandlerComponent = 'CLMSetupLayout';
		} else {
			tabIndex = 8;
			eventHandlerComponent = 'CLMHelpLayout'
		}
		helper.fireApplicationEvent(component, {
			fromComponent: 'CLMTroubleshoot',
			toComponent: eventHandlerComponent,
			type: 'update',
			tabIndex: tabIndex,
		}, 'CLMNavigationEvent');
	}
});