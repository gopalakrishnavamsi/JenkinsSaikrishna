({
	init: function (component) {
		var steps = [];
		steps.push($A.get('$Label.c.WorkflowSteps1'));
		steps.push($A.get('$Label.c.WorkflowSteps2'));
		steps.push($A.get('$Label.c.WorkflowSteps3'));
		steps.push($A.get('$Label.c.WorkflowSteps4'));
		steps.push($A.get('$Label.c.WorkflowSteps5'));
		component.set('v.steps', steps);
	}
});