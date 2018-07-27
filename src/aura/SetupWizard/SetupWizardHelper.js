({
  updateText: function (component, steps) {
    var progressionStatus = component.get('v.progressionStatus');

    if (steps.length === 1) {
      component.set('v.headerText', $A.get('$Label.c.CompleteConnection'));
    }

    if (progressionStatus === 'notStarted') {
      component.set('v.buttonText', $A.get('$Label.c.GetStarted'));
      component.set('v.headerText', $A.get('$Label.c.CompleteSetup'));
    } else if (progressionStatus === 'complete') {
      $A.util.addClass(component.find('landingButton'), 'strike-hide');
      component.set('v.headerText', $A.get('$Label.c.AllSet'));
    } else {
      component.set('v.buttonText', $A.get('$Label.c.ContinueSetup'));
    }

    if ((steps.length > 1) && (component.get('v.completedCounter') > 0)) {
      $A.util.removeClass(component.find('progressCounter'), 'slds-hide');
    } else {
      $A.util.removeClass(component.find('landingButton'), 'strike-hide');
      $A.util.addClass(component.find('progressCounter'), 'slds-hide');
    }

    //forces rerender to set button and text properly.
    component.set('v.steps', component.get('v.steps'));
  }
});
