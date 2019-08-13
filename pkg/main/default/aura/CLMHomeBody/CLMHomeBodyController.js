({
    onPrimaryButtonClick: function (component, event) {
        var buttonLabel = event.getParam('buttonLabel');
        var action = component.get('c.getCurrentUserExperience');
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var theme = response.getReturnValue();   
                if (buttonLabel === $A.get('$Label.c.ConfigureLayouts') || buttonLabel === $A.get('$Label.c.ConfigureButtons')) {
                    if (theme === 'Theme4d' || theme === 'Theme4t' || theme === 'Theme4u') {
                        window.open($A.get('$Label.c.LEXObjectManagerURL'));
                    } else {          
                        window.open($A.get('$Label.c.ClassicObjectManagerURL'));
                    }
                }     
            }else{
                $A.log('Callback failed.');
            }
        });
        $A.enqueueAction(action);
    },
    
    onSecondaryButtonClick: function (component, event, helper) {
        helper.fireApplicationEvent(component, {
            fromComponent: 'CLMHomeEBody',
            toComponent: 'CLMSetupLayout',
            type: 'update',
            tabIndex: '8',
        }, 'CLMNavigationEvent');
    }
})