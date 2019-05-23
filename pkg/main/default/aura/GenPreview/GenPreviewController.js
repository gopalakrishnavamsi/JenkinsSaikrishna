({
  setPreviewedDocs: function(component) {
    var config = component.get('v.config');
    config.hasPreviewedDocuments = true;
    component.set('v.config', config);
  },

  validate: function() {
    return new Promise(
      $A.getCallback(function(resolve) {
        resolve();
      })
    );
  }
});
