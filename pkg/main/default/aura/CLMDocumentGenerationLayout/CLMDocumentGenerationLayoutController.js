({
	init: function (component, event, helper) {
		var steps = [];
		steps.push($A.get('$Label.c.DocumentStep1'));
		steps.push($A.get('$Label.c.DocumentStep2'));
		steps.push($A.get('$Label.c.DocumentStep3'));
		component.set('v.steps', steps);
		helper.callServer(component, 'c.getDocGenButtonLink', false, function (result) {
			component.set('v.redirectCLM', result);
		});
	}
})