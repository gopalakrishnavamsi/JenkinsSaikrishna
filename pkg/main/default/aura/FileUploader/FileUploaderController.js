({
  onInitialize: function (component) {
    component.set('v.uiHelper', new UIHelper(function () {
      return component.getEvent('loadingEvent');
    }, function () {
      return component.getEvent('toastEvent');
    }));
  },

  onFileChange: function (component, event, helper) {
    var files = event.getSource().get('v.files');
    if (!$A.util.isEmpty(files)) {
      helper.uploadFile(component, files[0]);
    }
  }
});
