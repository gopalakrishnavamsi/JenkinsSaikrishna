({
    initialize: function (component, event, helper) {
        var namespace = component.get('v.namespace');
        var namespaceApi = namespace !== 'c' ? namespace + '__' : '';
        var frameSrc = '/apex/' + namespaceApi + 'fileUploader?id=' + component.get('v.recordId') + '&lcHost=' + component.get('v.lcHost');
        component.set('v.frameSrc', frameSrc);
        helper.setVfHost(component);

        //Add message listener
        window.addEventListener("message", $A.getCallback(function (event) {
            var origin = JSON.parse(JSON.stringify(event.origin));
            //check the origin to prevent malicious event capturing
            if (origin != component.get('v.vfHost')) {
                return;
            }
            //if origin and component attribute set by helper to visualforce domain match then proceed
            else {
                var state = JSON.parse(JSON.stringify(event.data.state));
                if (state === 'uploadFinished') {
                    var messageType = JSON.parse(JSON.stringify(event.data.messageType));
                    var message = JSON.parse(JSON.stringify(event.data.message));
                    if (messageType === 'SUCCESS') {
                        component.set('v.message', message);
                    }
                    else if (messageType === 'ERROR') {
                        component.set('v.message', message);
                    }
                }
                else if (state === 'LOADED'){
                    var message = JSON.parse(JSON.stringify(event.data.message));
                    component.set('v.message', message);
                }
            }
        }));
    }
});
