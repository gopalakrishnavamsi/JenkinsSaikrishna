({
  onFileChange: function(component, event, helper) {
    var files = event.getSource().get('v.files');
    if (!$A.util.isEmpty(files)) {
      helper.uploadFile(component, files[0]);
    }
  }
});