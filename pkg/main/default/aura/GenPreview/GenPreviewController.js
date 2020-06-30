({
  setPreviewedDocs: function(component) {
    var template = component.get('v.template');
    template.hasPreviewedDocuments = true;
    component.set('v.template', template);
  },

  validate: function() {
    return new Promise(
      $A.getCallback(function(resolve) {
        resolve();
      })
    );
  }
});
