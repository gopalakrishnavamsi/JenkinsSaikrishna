({
	navigateToSection: function (component, event, helper) {
		var tabIndex;
		if (component.get('v.hyperlinkedText') === $A.get('$Label.c.DocumentGeneration')) {
			tabIndex = '4';
		} else {
			tabIndex = '8';
		}
		helper.fireApplicationEvent(component, {
			fromComponent: 'CLMTroubleshoot',
			toComponent: 'CLMSetupLayout',
			type: 'update',
			tabIndex: tabIndex,
		}, 'CLMNavigationEvent');
	}
});