({
  init: function (component) {
    var config = component.get('v.config');
    if (!$A.util.isUndefinedOrNull(config.objectMappings)) {
      var fieldMappingsString = '[{"type":"ROOT","path":[],"key":"Account","fields":[],"depth":1}]';
      config.sourceObject = 'Account';
      config.objectMappings = {
        version: 2,
        name: 'Account',
        label: 'Account',
        fieldMappings: JSON.parse(fieldMappingsString),
      };

      component.set('v.config', config);
    }
  },

  selectedPrimary: function (component) {
    var config = component.get('v.config');
    var labelByApiName = component.get('v.labelByApiName');
    var objectMappings = config.objectMappings;
    var objLabel = labelByApiName[objectMappings.name];
    var fieldMappingsString = '[{"type":"ROOT","path":[],"key":"' + objectMappings.name + '","fields":[],"depth":1}]';
    config.sourceObject = objLabel;
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