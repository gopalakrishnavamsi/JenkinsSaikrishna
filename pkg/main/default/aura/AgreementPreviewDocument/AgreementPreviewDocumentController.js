({

	onLoad: function(component, event, helper) {
		var action = component.get('c.getDocumentURL');
		var agreement = component.get('v.Agreement');
		action.setParams({
			documentId: agreement.id.value
		});
		action.setCallback(this, function(response) {
			if (response.getState() === 'SUCCESS') helper.loadWidget(component, agreement.id.value, response.getReturnValue(), agreement.name, agreement.historyItems);
		});

		$A.enqueueAction(action);
	}
  
});