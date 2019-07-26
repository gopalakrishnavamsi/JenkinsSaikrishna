({
    goto: function(component, event, helper) {
        var id = event.currentTarget.id;
        var allSteps = component.get('v.steps');
        var currentStep = component.get('v.currentStep');
        var currentStepValue = ''
        allSteps.forEach(function(step){
            if (step.index === currentStep){
                currentStepValue=step
            }
        });
        
        var nextStepValue =''; 
        allSteps.forEach(function(step){
            if (step.index === id){
                nextStepValue=step;
            }
        }); 

        if (nextStepValue && currentStepValue) {
            component.set('v.currentStep', nextStepValue.index);
            helper.fireApplicationEvent(component, {
                navigateFrom: currentStepValue,
                navigateTo: nextStepValue,
                fromComponent: 'CLMBreadcrumbs',
                toComponent: 'ANY'
            }, 'CLMBreadcrumbsEvent');
        }
    },
    updateStep: function(component, event) {
        var navigateTo = event.getParam('navigateTo');
        var fromComponent = event.getParam('fromComponent');
        var toComponent = event.getParam('toComponent');
        if (toComponent === 'CLMBreadcrumbs' && fromComponent !== 'CLMBreadcrumbs') {
            if (navigateTo.index !== undefined) {
                var allSteps = component.get('v.steps');
                //verifying if we have valid index value
                var currentStepValue = '';
                allSteps.forEach(function(step){
                    if (step.index === navigateTo.index){
                        currentStepValue=step;
                    }
                });
                component.set('v.currentStep', currentStepValue);
            }
        }
    }
})