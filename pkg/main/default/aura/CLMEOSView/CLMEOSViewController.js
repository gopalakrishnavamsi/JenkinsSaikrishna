({
	onChangeIsAuthorized: function (component, event, helper) {
		if (component.get('v.isAuthorized')) {
			helper.getUrl(component, event, helper);
		}
	}
});
