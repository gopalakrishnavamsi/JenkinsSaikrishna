({
  selectedPrimary: function (component) {
    var template = component.get('v.template');
    var labelByApiName = component.get('v.labelByApiName');
    var objectMappings = template.objectMappings;
    var objLabel = labelByApiName[objectMappings.name];
    var fieldMappingsString = '[{"type":"ROOT","path":[],"key":"' + objectMappings.name + '","fields":[],"depth":1}]';
    template.sourceObject = objLabel;
    template.generated = template.generated.map(function (file) {
      file.rule = null;
      return file;
    });
    objectMappings.label = objLabel;
    objectMappings.fieldMappings = JSON.parse(fieldMappingsString);

    component.set('v.template', template);
  },

  validate: function (component) {
    return new Promise($A.getCallback(function (resolve, reject) {
      var template = component.get('v.template');
      var missingLabels = false;
      if ($A.util.isUndefinedOrNull(template.objectMappings.label)) {
        missingLabels = true;
      }

      if (missingLabels) {
        reject();
      } else {
        resolve();
      }
    }));
  }
});
