({
  init: function(component, event, helper) {
    helper.setConditionalRadio(component);
  },
  validate: function(component) {
    return new Promise(
      $A.getCallback(function(resolve /*, reject*/) {
        var config = component.get('v.config');

        config.objectMappings.forEach(function(objMapping) {
          objMapping.fieldMappings = objMapping.fieldMappings.filter(function(
            fieldMapping
          ) {
            if (fieldMapping.isChildRelation) {
              fieldMapping.childFieldMappings = fieldMapping.childFieldMappings.filter(
                function(childMapping) {
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

  showOptionsModal: function(component, event, helper) {
    var optionModalParams = event.getParam('data');
    var fieldMapping = helper.getFieldMapping(component, optionModalParams);
    var clonedFieldMapping = Object.assign({}, fieldMapping);

    if (
      fieldMapping.dataType === 'DATE' ||
      fieldMapping.dataType === 'DATETIME'
    ) {
      helper.formatDate(component, fieldMapping.dateFormat);
    }

    if (fieldMapping.dataType === 'CURRENCY') {
      helper.formatCurrency(component, fieldMapping.currencyFormat);
    }

    component.set('v.optionModalParams', optionModalParams);
    component.set('v.clonedFieldMapping', clonedFieldMapping);
    component.find('merge-token-options').show();
  },

  // TODO: Clean up this function. Not clear what's actually being saved here. Config is not updated with anything, unused vars, etc.
  saveOptions: function(component /*, event, helper*/) {
    // var config = component.get('v.config');
    // var optionModalParams = component.get('v.optionModalParams');
    // var fieldMapping = helper.getFieldMapping(component, optionModalParams);
    var clonedFieldMapping = component.get('v.clonedFieldMapping');

    if (
      clonedFieldMapping.isConditional &&
      $A.util.isEmpty(clonedFieldMapping.conditionalValue)
    ) {
      component.find('conditionalValue').showHelpMessageIfInvalid();
      return;
    }

    // fieldMapping = Object.assign(fieldMapping, clonedFieldMapping);
    // component.set('v.config', config);
    component.find('merge-token-options').hide();
  },

  formatDate: function(component, event, helper) {
    var dateFormat = event.getSource().get('v.value');
    helper.formatDate(component, dateFormat);
  },

  formatCurrency: function(component, event, helper) {
    var currencyFormat = event.getSource().get('v.value');
    helper.formatCurrency(component, currencyFormat);
  },

  convertToBoolean: function(component, event) {
    //html always returns the value as a string so we're going to convert it back to boolean
    var conditionalValue = event.getSource().get('v.value');
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    component.set('v.mergeFieldDefaultDisplay', conditionalValue);
    clonedFieldMapping.isConditional = conditionalValue === 'true';
    component.set('v.clonedFieldMapping', clonedFieldMapping);
  },

  addSigner: function(component) {
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

  removeSigner: function(component, event) {
    var index = event.getSource().get('v.value');
    var config = component.get('v.config');
    var signerMappings = config.signerMappings;

    signerMappings.splice(index, 1);

    component.set('v.config', config);
  },

  addSignerField: function(component, event) {
    var index = event.getSource().get('v.value');
    var config = component.get('v.config');
    var signerMappings = config.signerMappings;

    signerMappings[index].fieldMappings.push({
      apiName: 's'
    });

    component.set('v.config', config);
  },

  removeSignerField: function(component, event) {
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

      mappingComponents.forEach(function(cmp) {
        if (cmp && cmp.setTokenValue) {
          cmp.setTokenValue();
        }
      });
    }
  }
});
