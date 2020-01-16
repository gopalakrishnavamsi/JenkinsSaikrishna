({
  init: function (component, event, helper) {
    helper.setConditionalRadio(component);
  },
  validate: function (component) {
    return new Promise(
      $A.getCallback(function (resolve /*, reject*/) {
        var config = component.get('v.config');

        config.objectMappings.forEach(function (objMapping) {
          objMapping.fieldMappings = objMapping.fieldMappings.filter(function (
            fieldMapping
          ) {
            if (fieldMapping.isChildRelation) {
              fieldMapping.childFieldMappings = fieldMapping.childFieldMappings.filter(
                function (childMapping) {
                  return !$A.util.isEmpty(childMapping.apiName);
                }
              );
            }

            return !$A.util.isEmpty(fieldMapping.apiName);
          });
        });

        resolve();
      })
    );
  },

  showOptionsModal: function (component, event, helper) {

    var optionModalParams = event.getParam('data');
    var fieldMapping = helper.getFieldMapping(component, optionModalParams);
    var clonedFieldMapping = Object.assign({}, fieldMapping);
    if (fieldMapping.dataType === 'DATETIME') {
      component.set('v.userLocaleDateFormat', $A.localizationService.formatDate(new Date($A.get('$Label.c.X2019_01_18'))));
      var formats = fieldMapping.format.split('|');//splitting datetime format using the | symbol because this symbol is not a valid seperator for date and time
      if (!component.get('v.definedDateFormats').includes(formats[0])) {
        component.set('v.dateDropDown', $A.get('$Label.c.Custom'));
        component.set('v.customDateInput', formats[0]);
        helper.formatDate(component);
      } else {
        component.set('v.datePreview', '');
        component.set('v.customDateInput', '');
        component.set('v.dateDropDown', formats[0]);
      }

      if (!component.get('v.definedTimeFormats').includes(formats[1])) {
        component.set('v.timeDropDown', $A.get('$Label.c.Custom'));
        component.set('v.customTimeInput', formats[1]);
        helper.formatTime(component);
      } else {
        component.set('v.customTimeInput', '');
        component.set('v.timePreview', '');
        component.set('v.timeDropDown', formats[1]);
      }


    }
    if (fieldMapping.dataType === 'DATE') {
      component.set('v.userLocaleDateFormat', $A.localizationService.formatDate(new Date($A.get('$Label.c.X2019_01_18'))));
      if (!component.get('v.definedDateFormats').includes(fieldMapping.format)) {
        component.set('v.dateDropDown', $A.get('$Label.c.Custom'));
        component.set('v.customDateInput', fieldMapping.format);
        helper.formatDate(component);
      } else {
        component.set('v.datePreview', '');
        component.set('v.customDateInput', '');
        component.set('v.dateDropDown', fieldMapping.format);
      }
    }

    if (fieldMapping.dataType === 'TIME') {
      if (!component.get('v.definedTimeFormats').includes(fieldMapping.format)) {
        component.set('v.timeDropDown', $A.get('$Label.c.Custom'));
        component.set('v.customTimeInput', fieldMapping.format);
        helper.formatTime(component);
      } else {
        component.set('v.customTimeInput', '');
        component.set('v.timePreview', '');
        component.set('v.timeDropDown', fieldMapping.format);
      }
    }

    if (fieldMapping.dataType === 'CURRENCY') {
      helper.formatCurrency(component, fieldMapping.format);
    }


    if (fieldMapping.dataType === 'PERCENT') {
      helper.formatPercent(component, fieldMapping.format);
    }

    component.set('v.optionModalParams', optionModalParams);
    component.set('v.clonedFieldMapping', clonedFieldMapping);
    component.find('merge-token-options').show();
  },

  // TODO: Clean up this function. Not clear what's actually being saved here. Config is not updated with anything, unused vars, etc.
  saveOptions: function (component, event, helper) {
    var config = component.get('v.config');
    var optionModalParams = component.get('v.optionModalParams');
    // eslint-disable-next-line no-unused-vars
    var fieldMapping = helper.getFieldMapping(component, optionModalParams);
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    if (component.get('v.datePreview') === 'Invalid Date' ||
      component.get('v.timePreview') === 'Invalid Time') {
      return;
    }

    if (component.get('v.clonedFieldMapping').dataType === 'TIME') {
      component.set('v.clonedFieldMapping.format', component.get('v.timeDropDown') === $A.get('$Label.c.Custom') ?
        $A.util.isEmpty(component.get('v.customTimeInput')) ? 'default' : component.get('v.customTimeInput') : component.get('v.timeDropDown'));
    }
    if (component.get('v.clonedFieldMapping').dataType === 'DATE') {
      component.set('v.clonedFieldMapping.format', component.get('v.dateDropDown') === $A.get('$Label.c.Custom') ?
        $A.util.isEmpty(component.get('v.customDateInput')) ? 'default' : component.get('v.customDateInput') : component.get('v.dateDropDown'));
    }
    if (component.get('v.clonedFieldMapping').dataType === 'DATETIME') {
      var timeFormat;
      var dateFormat;
      if (component.get('v.customTimeInput') !== '') {
        timeFormat = component.get('v.customTimeInput');
      } else {
        timeFormat = component.get('v.timeDropDown');
      }
      if (component.get('v.customDateInput') !== '') {
        dateFormat = component.get('v.customDateInput');
      } else {
        dateFormat = component.get('v.dateDropDown');
      }
      component.set('v.clonedFieldMapping.format', dateFormat + '|' + timeFormat);
    }
    if (clonedFieldMapping.isConditional && $A.util.isEmpty(clonedFieldMapping.conditionalValue)) {
      component.find('conditionalValue').showHelpMessageIfInvalid();
      return;
    }

    fieldMapping = Object.assign(fieldMapping, clonedFieldMapping);
    component.set('v.config', config);
    component.find('merge-token-options').hide();
  },

  formatDate: function (component, event, helper) {
    helper.formatDate(component);
  },

  formatTime: function (component, event, helper) {
    helper.formatTime(component);
  },

  formatCurrency: function (component, event, helper) {
    var currencyFormat = event.getSource().get('v.value');
    helper.formatCurrency(component, currencyFormat);
  },

  formatPercent: function (component, event, helper) {
    helper.formatPercent(component, component.find('percent').get('v.checked'));
  },

  convertToBoolean: function (component, event) {
    //html always returns the value as a string so we're going to convert it back to boolean
    var conditionalValue = event.getSource().get('v.value');
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    clonedFieldMapping.isConditional = conditionalValue === 'true';
    component.set('v.clonedFieldMapping', clonedFieldMapping);
  },

  addSigner: function (component) {
    var config = component.get('v.config');
    var signerMappings = config.signerMappings;

    signerMappings.push({
      fieldMappings: [
        {
          apiName: 's'
        }
      ]
    });

    component.set('v.config', config);
  },

  removeSigner: function (component, event) {
    var index = event.getSource().get('v.value');
    var config = component.get('v.config');
    var signerMappings = config.signerMappings;

    signerMappings.splice(index, 1);

    component.set('v.config', config);
  },

  addSignerField: function (component, event) {
    var index = event.getSource().get('v.value');
    var config = component.get('v.config');
    var signerMappings = config.signerMappings;

    signerMappings[index].fieldMappings.push({
      apiName: 's'
    });

    component.set('v.config', config);
  },

  removeSignerField: function (component, event) {
    var params = event.getParam('data');
    var config = component.get('v.config');
    var signerMappings = config.signerMappings;
    var fieldMappings = signerMappings[params.parentIndex].fieldMappings;
    fieldMappings.splice(params.index, 1);

    if (fieldMappings.length === 0) {
      signerMappings.splice(params.parentIndex, 1);
    }

    component.set('v.config', config);

    //recalc numbering in index fields due to removal of a signer.
    if (fieldMappings.length === 0) {
      var mappingComponents = component.find('fieldMapping');
      mappingComponents = Array.isArray(mappingComponents)
        ? mappingComponents
        : [mappingComponents];

      mappingComponents.forEach(function (cmp) {
        if (cmp && cmp.setTokenValue) {
          cmp.setTokenValue();
        }
      });
    }
  }
});
