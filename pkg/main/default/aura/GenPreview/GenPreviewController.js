({
  setPreviewedDocs: function (component) {
    var config = component.get('v.config');
    config.hasPreviewedDocuments = true;
    component.set('v.config', config);
  },

  validate: function (component) {
    return new Promise($A.getCallback(function (resolve, reject) {
      resolve();
    }));
  }
});