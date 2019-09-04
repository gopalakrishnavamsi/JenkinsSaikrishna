({
	buttonClick: function (component) {
		var link = component.get('v.firstButtonNavigation');
		if (link)
			window.open(link);
	},
	
	navigateToSection: function (component, event, helper) {
		var uri = component.get('v.hyperlinkedURI');
		if (uri[0] === 'tab') {
			helper.fireApplicationEvent(
				component,
				{
					fromComponent: 'CLMInformationHelpController',
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