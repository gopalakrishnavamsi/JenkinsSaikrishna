({
  formatFileSize: function (component) {
    var file = component.get('v.file');
    var contentSize = file.size;
    var unit = '';

    if ((contentSize / 1000000) > 1) {
      contentSize = (contentSize / 1000000).toFixed(1);
      unit = 'MB';
    } else if ((contentSize / 1000) > 1) {
      contentSize = Math.round(contentSize / 1000);
      unit = 'KB';
    } else {
      contentSize = Math.round(contentSize);
      unit = 'B';
    }

    component.set('v.fileSize', contentSize + unit);
  },
  focusFileName: function (component) {
    setTimeout($A.getCallback(function () {
      var fileName = component.find('generatedName');
      if (!$A.util.isEmpty(fileName) && fileName.isValid()) {
        fileName.focus();
      }
    }), 10);
  }
});
