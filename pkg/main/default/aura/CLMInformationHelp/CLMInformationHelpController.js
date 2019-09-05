({
	buttonClick: function (component) {
		var link = component.get('v.firstButtonNavigation');
		var buttonName = component.get('v.firstButtonName');
		if (buttonName === $A.get('$Label.c.OpenObjectManagerButton')) {
			var action = component.get('c.getCurrentUserExperience');
			action.setCallback(this, function (response) {
				var state = response.getState();
				if (state === 'SUCCESS') {
					var theme = response.getReturnValue();
					if (
						theme === 'Theme4d' ||
						theme === 'Theme4t' ||
						theme === 'Theme4u'
					) {
						navUtils.navigateToUrl($A.get('$Label.c.LEXObjectManagerURL'));
					} else {
						navUtils.navigateToUrl($A.get('$Label.c.ClassicObjectManagerURL'));
					}
				} else {
					helper.fireToast(component, stringUtils.getErrorMessage(response), helper.ERROR);
				}
			});
			$A.enqueueAction(action);
		} else {
			if (link)
				navUtils.navigateToUrl(link);
		}
	},

	navigateToSection: function (component, event, helper) {
		var uri = component.get('v.hyperlinkedURI');
		if (uri[0] === 'tab') {
			helper.fireApplicationEvent(
				component,
				{
					fromComponent: 'CLMInformationHelp',
					toComponent: 'CLMSetupLayout',
					type: 'update',
					tabIndex: uri[1]
				},
				'CLMNavigationEvent'
			);
		}
		else if (uri[0] === 'url') {
			navUtils.navigateToUrl(uri[1]);
		}
	}
})