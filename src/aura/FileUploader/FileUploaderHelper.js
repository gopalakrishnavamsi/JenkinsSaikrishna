({
    setVfHost: function (component) {
        var getVfHost = component.get('c.getVisualForceHost');
        getVfHost.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.vfHost', 'https://'+response.getReturnValue());
            }
            else {
                console.log('Error '+ response.getError());
            }
        });
        $A.enqueueAction(getVfHost);
    }
})