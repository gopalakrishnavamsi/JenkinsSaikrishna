({
  setLoading: function (component, isLoading) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: isLoading === true
    });
    evt.fire();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true, message: message, mode: mode
    });
    evt.fire();
  },

  hideToast: function (component) {
    var evt = component.getEvent('toastEvent');
    if (!$A.util.isUndefinedOrNull(evt)) {
      evt.setParams({
        show: false
      });
      evt.fire();
    }
  },

  MAX_FILE_SIZE: 4718592, // 4.5 MB
  CHUNK_SIZE: 768000, // 750 KB
  BASE_64_PREFIX: 'base64,',

  uploadFile: function (component, file) {
    var self = this;
    self.hideToast(component);

    if (file.size > self.MAX_FILE_SIZE) {
      var errMsg = _format($A.get('$Label.c.FileSizeLimitReached_2'), _formatSize(self.MAX_FILE_SIZE), _formatSize(file.size));
      self.showToast(component, errMsg, 'error');
      return;
    }

    self.setLoading(component, true);

    var fr = new FileReader();
    fr.onload = $A.getCallback(function () {
      var base64Data = fr.result;
      base64Data = base64Data.substring(base64Data.indexOf(self.BASE_64_PREFIX) + self.BASE_64_PREFIX.length);
      self._uploadChunk(component, file, base64Data, 0, Math.min(base64Data.length, self.CHUNK_SIZE), null);
    });
    fr.readAsDataURL(file);
  },

  _uploadChunk: function (component, file, base64Data, start, end, contentVersionId) {
    var self = this;
    var saveChunk = component.get('c.saveChunk');
    saveChunk.setParams({
      contentVersionId: contentVersionId,
      linkedEntityId: component.get('v.recordId'),
      fileName: file.name,
      base64Data: encodeURIComponent(base64Data.substring(start, end))
    });
    saveChunk.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var cvId = response.getReturnValue();
        var s = end;
        var e = Math.min(base64Data.length, s + this.CHUNK_SIZE);
        if (s < e) {
          self._uploadChunk(component, file, base64Data, s, e, cvId);
        } else {
          var evt = component.getEvent('uploadEvent');
          evt.setParams({
            success: true, sourceId: cvId
          });
          evt.fire();
          this.setLoading(component, false);
        }
      } else {
        this.showToast(component, _getErrorMessage(response), 'error');
        this.setLoading(component, false);
      }
    });
    $A.enqueueAction(saveChunk);
  }
});
