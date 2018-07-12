({
  onInit: function (component, event, helper) {
    var namespace = component.get('v.namespace');
    var namespaceApi = namespace !== 'c' ? namespace + '__' : '';
    var frameSrc = '/apex/' + namespaceApi + 'fileUploader?id=' + component.get('v.recordId') + '&lcHost=' + component.get('v.lcHost');

    component.set('v.frameSrc', frameSrc);

    //Add message listener
    window.addEventListener("message", $A.getCallback(function (event) {
      if (event.data.state === 'LOADED') {
        //Set vfHost which will be used later to send message
        component.set('v.vfHost', event.data.vfHost);
      }
      if (event.data.state === 'uploadFinished') {
        var messageType = event.data.messageType;
        var message = event.data.message;

        if (messageType === 'SUCCESS') {
          component.set('v.message', message);

        } else if (messageType === 'ERROR') {
          component.set('v.message', message);
        }
      }
    }));
  }
});
