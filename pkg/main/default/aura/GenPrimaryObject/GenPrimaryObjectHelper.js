({
  addObject: function(component, isPrimary) {
    var config = component.get('v.config');

    if ($A.util.isEmpty(config.objectMappings)) {
      config.objectMappings = [];
    }

    config.objectMappings.push({
      apiName: '',
      label: '',
      fieldMappings: [],
      isPrimary: isPrimary
    });

    component.set('v.config', config);
  },

  getUniqueLabel: function(component, label, index) {
    var config = component.get('v.config');
    var mappings = config.objectMappings;
    var labelCount = 1;

    mappings.forEach(function(objMap, loopIndex) {
      if (
        index !== loopIndex &&
        (objMap.label === label || objMap.label === label + labelCount)
      ) {
        labelCount++;
      }
    });

    return labelCount > 1 ? label + labelCount : label;
  }
});
