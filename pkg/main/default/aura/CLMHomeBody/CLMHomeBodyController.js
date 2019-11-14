({
	onPrimaryButtonClick: function (component, event, helper) {
		var buttonLabel = event.getParam('buttonLabel');
		var title = event.getParam('cardTitle');
		if (buttonLabel === $A.get('$Label.c.Manage')) {
			if (title === $A.get('$Label.c.UserManagement')) {
				helper.fireApplicationEvent(component, {
					fromComponent: 'CLMHomeBody',
					toComponent: 'CLMSetupLayout',
					type: 'update',
					tabIndex: '6',
				}, 'CLMNavigationEvent');
			} else { 
				helper.fireApplicationEvent(component, {
					fromComponent: 'CLMHomeBody',
					toComponent: 'CLMSetupLayout',
					type: 'update',
					tabIndex: '7',
				}, 'CLMNavigationEvent');
			}
		}
		else if (buttonLabel === $A.get('$Label.c.HomeGetHelp')) {
			helper.fireApplicationEvent(component, {
				fromComponent: 'CLMHomeBody',
				toComponent: 'CLMSetupLayout',
				type: 'update',
				tabIndex: '8',
			}, 'CLMNavigationEvent');
		}
		else if (buttonLabel === $A.get('$Label.c.ConfigureLayouts') || buttonLabel === $A.get('$Label.c.ConfigureButtons')) {
			var action = component.get('c.getCurrentUserExperience');
			action.setCallback(this, function (response) {
				var state = response.getState();
				if (state === 'SUCCESS') {
					var theme = response.getReturnValue();

					if (theme === 'Theme4d' || theme === 'Theme4t' || theme === 'Theme4u') {
						navUtils.navigateToUrl($A.get('$Label.c.LEXObjectManagerURL'));
					} else {
						navUtils.navigateToUrl($A.get('$Label.c.ClassicObjectManagerURL'));
					}

				} else {
					$A.log($A.get('$Label.c.CallbackFailed'));
				}
			});
			$A.enqueueAction(action);
		}
	},

	onSecondaryButtonClick: function (component, event, helper) {
		helper.fireApplicationEvent(component, {
			fromComponent: 'CLMHomeBody',
			toComponent: 'CLMSetupLayout',
			type: 'update',
			tabIndex: '8',
		}, 'CLMNavigationEvent');
	}
});
