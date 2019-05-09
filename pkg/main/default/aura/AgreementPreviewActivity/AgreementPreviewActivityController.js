({
	
	onLoad: function(component, event, helper) {
		var Widgets = component.get('v.SpringService');
		var historyItems = component.get('v.AgreementHistory');
		historyItems.prototype = Array.prototype;
		var historyWidget = new Widgets.History({
			iconPath: $A.get('$Resource.scmwidgetsspritemap')
		});
		historyWidget.render('#fileActivity').setHistoryItems(historyItems);		
		component.set('v.Widget', historyWidget);
	}

})