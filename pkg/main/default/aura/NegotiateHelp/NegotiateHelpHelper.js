({
  init: function (component) {
    var helpSteps = [ { stepNumber: 1, stepDetail: $A.get('$Label.c.NegotiateHelpText1')}, 
                      { stepNumber: 2, stepDetail: $A.get('$Label.c.NegotiateHelpText2')}, 
                      { stepNumber: 3, stepDetail: $A.get('$Label.c.NegotiateHelpText3')},
                      { stepNumber: 4, stepDetail: $A.get('$Label.c.NegotiateHelpText4')}
                    ];
    component.set('v.helpSteps', helpSteps);
  }
});