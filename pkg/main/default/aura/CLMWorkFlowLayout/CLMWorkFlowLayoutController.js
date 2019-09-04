({
	init: function (component, event, helper) {
		var steps = [];
		steps.push($A.get('$Label.c.WorkflowSteps1'));
		steps.push($A.get('$Label.c.WorkflowSteps2'));
		steps.push($A.get('$Label.c.WorkflowSteps3'));
		steps.push($A.get('$Label.c.WorkflowSteps4'));
		steps.push($A.get('$Label.c.WorkflowSteps5'));
		component.set('v.steps', steps);
		helper.callServer(component, 'c.getWorkflowButtonLink', false, function (result) {
			component.set('v.redirectCLM', result);
		});
	}
});