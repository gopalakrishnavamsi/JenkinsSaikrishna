({
  upload: function(component, file, base64Data, recordId) {
    var action = component.get('c.saveChunk');

    component.getEvent('uploadStart').fire();

    action.setParams({
      contentVersionId: null,
      linkedEntityId: recordId,
      fileName: file.name,
      base64Data: base64Data
    });

    action.setCallback(this, function(response) {
      var endEvt = component.getEvent('uploadedFile');
      var state = response.getState();

      if (state === 'SUCCESS') {
        var responseFile = response.getReturnValue();
        endEvt.setParams({
          data: {
            file: responseFile,
            success: true
          }
        });
      } else if (state === 'ERROR') {
        endEvt.setParams({
          data: {
            file: null,
            success: false
          }
        });
      }

      endEvt.fire();
    });

    $A.enqueueAction(action);
  }
});
