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
        helper.fireToast(component, stringUtils.getErrorMessage(response), helper.ERROR);
			}
		});
		$A.enqueueAction(action);
	}
});