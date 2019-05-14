({

	onLoad: function(component, event, helper) {
		var uiHelper = component.get('v.uiHelper');
		var action = component.get('c.getDocumentURL');
		var agreement = component.get('v.agreement');
		action.setParams({
			documentId: agreement.id.value
		});
		action.setCallback(this, function(response) {
			if (response.getState() === 'SUCCESS') helper.loadWidget(component, agreement.id.value, response.getReturnValue(), agreement.name, agreement.historyItems);
			if (response.getState() === 'ERROR') uiHelper.showToast(uiHelper.getErrorMessage(response), uiHelper.ToastMode.ERROR);
		});

		$A.enqueueAction(action);
	}
  
});