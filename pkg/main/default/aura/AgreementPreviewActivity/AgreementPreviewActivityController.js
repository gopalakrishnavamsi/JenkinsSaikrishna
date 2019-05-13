({
	
	onLoad: function(component, event, helper) {
		//Checking if an instance of SpringCM Widgets has been loaded.
		if (!SpringCM || !SpringCM.Widgets || !SpringCM.Widgets.History) return;
		var historyItems = component.get('v.AgreementHistory');
		if (!historyItems) return;
		try {
			var historyWidget = new SpringCM.Widgets.History({
				iconPath: $A.get('$Resource.scmwidgetsspritemap')
			});
			historyWidget.render('#fileActivity');
			historyWidget.setHistoryItems(Object.assign([], historyItems));		
			component.set('v.Widget', historyWidget);
		} catch(err) {
			console.log('err:' , err);
		}

	}

})