({
  init: function (component, event, helper) {
    var file = component.get('v.file');
    helper.formatFileSize(component);
    if (file.isNew) {
      helper.focusFileName(component);
    }
  },

  previewFile: function (component) {
    var file = component.get('v.file');
    var isClassic = component.get('v.isClassic');

    if (isClassic) {
      window.open('/' + file.contentDocumentId, '_blank');
    } else {
      var openEvt = $A.get('e.lightning:openFiles');
      //safety check
      if ($A.util.isEmpty(openEvt)) {
        window.open('/' + file.contentDocumentId, '_blank');
      } else {
        openEvt.fire({
          recordIds: [file.contentDocumentId],
        });
      }
    }
  }
});
