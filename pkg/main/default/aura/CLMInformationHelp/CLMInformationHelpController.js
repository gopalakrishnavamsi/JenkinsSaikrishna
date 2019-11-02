({
	buttonClick: function (component, event, helper) {
		var invokedBy = component.get('v.invokedBy');
		if (invokedBy === 'Workflow-OpenObjectManager' || invokedBy === 'DocGen-OpenObjectManager') {
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
		} else if (invokedBy === 'DocGen-OpenDocuSignCLM') {
			helper.callServer(component, 'c.getDocGenButtonLink', false, function (result) {
				navUtils.navigateToUrl(result);
			});
		} else if (invokedBy === 'Workflow-OpenDocuSignCLM') {
			helper.callServer(component, 'c.getWorkflowButtonLink', false, function (result) {
				navUtils.navigateToUrl(result);
			});
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