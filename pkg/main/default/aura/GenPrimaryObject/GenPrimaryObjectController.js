({
  selectedPrimary: function (component) {
    var config = component.get('v.config');
    var labelByApiName = component.get('v.labelByApiName');
    var objectMappings = config.objectMappings;
    var objLabel = labelByApiName[objectMappings.name];
    var fieldMappingsString = '[{"type":"ROOT","path":[],"key":"' + objectMappings.name + '","fields":[],"depth":1}]';
    config.sourceObject = objLabel;
    config.generated = config.generated.map(function (file) {
      file.rule = null;
      return file;
    });
    objectMappings.label = objLabel;
    objectMappings.fieldMappings = JSON.parse(fieldMappingsString);

    component.set('v.config', config);
  },

  validate: function (component) {
    return new Promise($A.getCallback(function (resolve, reject) {
      var config = component.get('v.config');
      var missingLabels = false;
      if ($A.util.isUndefinedOrNull(config.objectMappings.label)) {
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