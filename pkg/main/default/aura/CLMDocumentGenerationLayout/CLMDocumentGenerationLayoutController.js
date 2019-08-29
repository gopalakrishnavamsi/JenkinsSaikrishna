({
	init: function (component) {
		var steps = [];
		steps.push($A.get('$Label.c.DocumentStep1'));
		steps.push($A.get('$Label.c.DocumentStep2'));
		steps.push($A.get('$Label.c.DocumentStep3'));
		component.set('v.steps', steps);
	}
})