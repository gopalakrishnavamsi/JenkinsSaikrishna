({
  initialize: function (component, event, helper) {
    var namespace = component.get('v.namespace');
    var namespaceApi = namespace !== 'c' ? namespace + '__' : '';
    var frameSrc = '/apex/' + namespaceApi + 'fileUploader?id=' + component.get('v.recordId') + '&lcHost=' + component.get('v.lcHost');

    component.set('v.frameSrc', frameSrc);

    //Add message listener
    window.addEventListener("message", $A.getCallback(function (event) {
      var state = JSON.parse(JSON.stringify(event.data.state));
      if (state === 'LOADED') {
        //Set vfHost which will be used later to send message
        component.set('v.vfHost', JSON.parse(JSON.stringify(event.data.vfHost)));
      } else if (state === 'uploadFinished') {
        var messageType = JSON.parse(JSON.stringify(event.data.messageType));
        var message = JSON.parse(JSON.stringify(event.data.message));

        if (messageType === 'SUCCESS') {
          component.set('v.message', message);

        } else if (messageType === 'ERROR') {
          component.set('v.message', message);
        }
      }
    }));
  }
});
