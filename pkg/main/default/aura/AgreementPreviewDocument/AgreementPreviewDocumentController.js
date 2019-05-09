({

	onLoad: function(component, event, helper) {
		var Widgets = component.get('v.SpringService');
		var previewWidget = new Widgets.Preview({
			iconPath: $A.get('$Resource.scmwidgetsspritemap')
		});
	}
  
});