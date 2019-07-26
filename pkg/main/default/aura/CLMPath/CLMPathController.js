({
    gotStep: function(component, event, helper) {
        var allSteps = component.get('v.steps');
        var currentStep = component.get('v.currentStep');
        var id = event.getSource().get('v.value');
        var currentStepValue = '';
        allSteps.forEach(function(step){
            if(step.index === currentStep){
                currentStepValue=step;
            }
        });       
        var nextStepValue = '';
        allSteps.forEach(function(step){
            if( step.index === id){
                nextStepValue=step;
            }
        });        
        if (nextStepValue && currentStepValue) {
            component.set('v.currentStep', nextStepValue.index);
            helper.fireApplicationEvent(component, {
                navigateFrom: currentStepValue,
                navigateTo: nextStepValue,
                fromComponent: 'CLMPath',
                toComponent: 'ANY'
            }, 'CLMPathEvent');
        }
    },
    updateStep: function(component, event) {
        var navigateTo = event.getParam('navigateTo');
        var fromComponent = event.getParam('fromComponent');
        var toComponent = event.getParam('toComponent');
        if (toComponent === 'CLMPath' && fromComponent !== 'CLMPath') {
            if (navigateTo.index !== undefined) {
                var allSteps = component.get('v.steps');
                //verifying do we have valid index value
                var currentStepValue = '';
                allSteps.forEach(function(step){
                    if(step.index === navigateTo.index)   {
                        currentStepValue=step;
                    }
                });
                component.set('v.currentStep', currentStepValue.index);
            }
        }
    }
})