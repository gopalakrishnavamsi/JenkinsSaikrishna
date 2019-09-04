({
	onInit: function (component, event, helper) {
		var action = component.get('c.getEOSUrl');
		action.setParams(
			{
				recordId: component.get('v.recordId')
			});
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.eosDetails', response.getReturnValue());
			} else {
				var errors = stringUtils.getErrorMessage(response);
				if (errors && errors[0] && errors[0].message) {
					helper.fireToast(component, errors[0].message, helper.ERROR);
				}
			}
		});
		$A.enqueueAction(action);
	}
});