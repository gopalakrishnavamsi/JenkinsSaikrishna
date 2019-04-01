({
  fileUpload: function (component, event, helper) {
    component.set('v.fileTooLarge', false);
    var recordId = component.get('v.recordId');
    var files = event.getSource().get('v.files');
    var file = files[0];
    var fr = new FileReader();

    fr.onloadend = $A.getCallback(function () {
      var fileSizeLimit = 1000 * 1000 * 3;

      if (file.size > fileSizeLimit) {
        component.set('v.fileTooLarge', true);
        return;
      }

      var dataURL = fr.result;
      var content = dataURL.match(/,(.*)$/)[1];

      helper.upload(component, file, content, recordId);
    });

    fr.readAsDataURL(file);
  }
});
