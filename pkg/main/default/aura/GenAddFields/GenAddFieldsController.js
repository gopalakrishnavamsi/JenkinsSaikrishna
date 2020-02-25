({
  init: function (component, event, helper) {
    helper.setConditionalRadio(component);
  },
  validate: function (component) {
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        var config = component.get('v.config');
        if (!$A.util.isUndefinedOrNull(config.objectMappings)) {
          resolve();
        } else {
          reject();
        }
      })
    );
  },

  showMergeOptionsModal: function (component, event, helper) {
    var optionModalParams = event.getParam('data');
    var fieldMapping = helper.getMergeFieldMapping(component, optionModalParams);
    var clonedFieldMapping = Object.assign({}, fieldMapping);

    if (fieldMapping.type === 'DATE' || fieldMapping.type === 'DATETIME') {
      component.set('v.userLocaleDateFormat', $A.localizationService.formatDate(new Date($A.get('$Label.c.X2019_01_18'))));
      var dateFormat = fieldMapping.format.includes('|') ? fieldMapping.format.split('|')[0] : fieldMapping.format;
      if (!component.get('v.definedDateFormats').includes(dateFormat)) {
        component.set('v.dateDropDown', $A.get('$Label.c.Custom'));
        component.set('v.customDateInput', dateFormat);
        helper.formatDate(component);
      } else {
        component.set('v.datePreview', '');
        component.set('v.customDateInput', '');
        component.set('v.dateDropDown', dateFormat);
      }
    }

    if (fieldMapping.type === 'TIME' || fieldMapping.type === 'DATETIME') {
      var timeFormat = fieldMapping.format.includes('|') ? fieldMapping.format.split('|')[1] : fieldMapping.format;
      if (!component.get('v.definedTimeFormats').includes(timeFormat)) {
        component.set('v.timeDropDown', $A.get('$Label.c.Custom'));
        component.set('v.customTimeInput', timeFormat);
        helper.formatTime(component);
      } else {
        component.set('v.customTimeInput', '');
        component.set('v.timePreview', '');
        component.set('v.timeDropDown', timeFormat);
      }
    }

    if (fieldMapping.type === 'CURRENCY') {
      helper.formatCurrency(component, fieldMapping.format);
    }

    component.set('v.optionModalParams', optionModalParams);
    component.set('v.clonedFieldMapping', clonedFieldMapping);

    if (fieldMapping.type === 'PERCENT') {
      helper.formatPercent(component, fieldMapping.format);
    }
    component.find('merge-token-options').show();
  },

  saveMergeOptions: function (component, event, helper) {
    var optionModalParams = component.get('v.optionModalParams');
    // eslint-disable-next-line no-unused-vars
    var fieldMapping = helper.getMergeFieldMapping(component, optionModalParams);
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    var timeFormat = '';
    var dateFormat = '';

    if(component.get('v.clonedFieldMapping').type === 'DATE' || component.get('v.clonedFieldMapping').type === 'DATETIME' ){
      if (helper.validateFormats(component)) {
        return;
      }
      component.set('v.clonedFieldMapping.format', component.get('v.dateDropDown') === $A.get('$Label.c.Custom') ?
        component.get('v.customDateInput') : component.get('v.dateDropDown'));
      //storing updated format value into dateFormat
      dateFormat = component.get('v.clonedFieldMapping.format');
    }
    if(component.get('v.clonedFieldMapping').type === 'TIME' || component.get('v.clonedFieldMapping').type === 'DATETIME'  ){
      if(helper.validateFormats(component)) {
        return;
      }
      component.set('v.clonedFieldMapping.format', component.get('v.timeDropDown') === $A.get('$Label.c.Custom') ?
        component.get('v.customTimeInput') : component.get('v.timeDropDown'));
      //storing updated format value into timeformat
      timeFormat = component.get('v.clonedFieldMapping.format');
    }



    if (!$A.util.isEmpty(timeFormat) && !$A.util.isEmpty(dateFormat) ) {
      component.set('v.clonedFieldMapping.format', stringUtils.format('{0}{1}{2}',dateFormat,'|',timeFormat));
    }

    if (clonedFieldMapping.isConditional && $A.util.isEmpty(clonedFieldMapping.conditionalValue)) {
      component.find('conditionalValue').showHelpMessageIfInvalid();
      return;
    }

    fieldMapping = Object.assign(fieldMapping, clonedFieldMapping);
    helper.updateFieldMappingInConfig(component, fieldMapping);
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
