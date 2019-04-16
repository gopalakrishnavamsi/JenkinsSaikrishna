({
  init: function (component) {
    var config = component.get('v.config');
    if ($A.util.isEmpty(config.objectMappings)) {
      config.sourceObject = 'Account';
      config.objectMappings = [{
        apiName: 'Account',
        label: 'Account',
        objLabel: 'Account',
        fieldMappings: [],
        isPrimary: true
      }];

      component.set('v.config', config);
    }
  },

  addObject: function (component, event, helper) {
    var config = component.get('v.config');
    var label = helper.getUniqueLabel(component, 'Account', config.objectMappings.length);

    config.objectMappings.push({
      apiName: 'Account',
      label: label,
      fieldMappings: [],
    });

    component.set('v.config', config);
  },

  removeObject: function (component, event) {
    var config = component.get('v.config');
    var index = parseInt(event.getSource().get('v.value'), 10);

    config.objectMappings.splice(index, 1);
    component.set('v.config', config);
  },

  selectedPrimary: function (component) {
    var config = component.get('v.config');
    var labelByApiName = component.get('v.labelByApiName');
    var primaryObjMapping = config.objectMappings[0];
    var objLabel = labelByApiName[primaryObjMapping.apiName];

    config.sourceObject = objLabel;

    primaryObjMapping.objLabel = objLabel;
    primaryObjMapping.label = objLabel;
    primaryObjMapping.fieldMappings = [];

    component.set('v.config', config);
  },

  selectedAdditionalObject: function (component, event, helper) {
    var config = component.get('v.config');
    var labelByApiName = component.get('v.labelByApiName');
    var index = parseInt(event.getSource().get('v.name'), 10);
    var selectedMapping = config.objectMappings[index];
    var selectedObjLabel = labelByApiName[selectedMapping.apiName];

    selectedMapping.objLabel = selectedObjLabel;
    selectedMapping.label = helper.getUniqueLabel(component, selectedObjLabel, index);
    selectedMapping.fieldMappings = [];

    component.set('v.config', config);
  },

  checkForDuplicate: function (component, event, helper) {
    var config = component.get('v.config');
    var index = event.getSource().get('v.name');
    var selectedMapping = config.objectMappings[index];

    selectedMapping.label = helper.getUniqueLabel(component, selectedMapping.label, index);
    component.set('v.config', config);
  },

  validate: function (component) {
    return new Promise($A.getCallback(function (resolve, reject) {
      var config = component.get('v.config');
      var missingLabels = false;

      config.objectMappings.forEach(function (objMapping) {
        if ($A.util.isEmpty(objMapping.label)) {
          missingLabels = true;
        }
      });

      if (missingLabels) {
        reject();
      } else {
        resolve();
      }
    }));
  }
});