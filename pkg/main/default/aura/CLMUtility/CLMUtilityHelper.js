({
    'callServer': function(component, serverMethod, params, callback) {        
        var action = component.get(serverMethod);
        if (params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            var state = response.getState();                        
            if (state === 'SUCCESS') {                
                callback.call(this, response.getReturnValue());                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                callback.call(this, errors);
            }
        });
        $A.enqueueAction(action);        
    },
    'fireComponentEvent': function(component, eventName, attributes) {
        var componentEvent = component.getEvent(eventName);
        if (componentEvent) {
            componentEvent.setParams(attributes);
            componentEvent.fire();
        } else {
			this.fireErrorToast(component, eventName);
        }
    },
    'fireApplicationEvent': function(component, params, eventName) {        
        var appEvent = $A.get('e.c:' + eventName);
        if (appEvent) {
            appEvent.setParams(params);
            appEvent.fire();
        } else {
			this.fireErrorToast(component, eventName);
        }
    },    
    fireErrorToast: function(component, error){
        var toast = component.find('toast');
        if(toast){
            component.set('v.toastTitleText', 'No Application event found with name -' + error);
            component.set('v.toastVariant', 'error');
            toast.show();
            setTimeout($A.getCallback(function() {
                toast.close();
            }), 2000);        
        }                            
    }    
})