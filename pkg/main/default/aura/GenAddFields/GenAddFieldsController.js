({
  init: function (component, event, helper) {
    helper.loadUserLocaleDateFormat(component);
    helper.loadConditionalOptions(component);
  },
  validate: function (component) {
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        var template = component.get('v.template');
        if (!$A.util.isUndefinedOrNull(template.objectMappings)) {
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

    if (fieldMapping.type === 'DATETIME') {
      helper.setDateFormatOnOptionsModal(component, fieldMapping);
      helper.setTimeFormatOnOptionsModal(component, fieldMapping);
    } else if (fieldMapping.type === 'DATE') {
      helper.setDateFormatOnOptionsModal(component, fieldMapping);
    } else if (fieldMapping.type === 'TIME') {
      helper.setTimeFormatOnOptionsModal(component, fieldMapping);
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
    var fieldMapping = Object.assign({}, helper.getMergeFieldMapping(component, optionModalParams));
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    var timeFormat = '';
    var dateFormat = '';

    if (component.get('v.clonedFieldMapping').type === 'DATE' || component.get('v.clonedFieldMapping').type === 'DATETIME') {
      if (helper.validateFormats(component)) {
        return;
      }
      component.set('v.clonedFieldMapping.format', component.get('v.dateDropDown') === $A.get('$Label.c.Custom') ?
        component.get('v.customDateInput') : component.get('v.dateDropDown'));
      //storing updated format value into dateFormat
      dateFormat = component.get('v.clonedFieldMapping.format');
    }
    if (component.get('v.clonedFieldMapping').type === 'TIME' || component.get('v.clonedFieldMapping').type === 'DATETIME') {
      if (helper.validateFormats(component)) {
        return;
      }
      component.set('v.clonedFieldMapping.format', component.get('v.timeDropDown') === $A.get('$Label.c.Custom') ?
        component.get('v.customTimeInput') : component.get('v.timeDropDown'));
      //storing updated format value into timeformat
      timeFormat = component.get('v.clonedFieldMapping.format');
    }


    if (!$A.util.isEmpty(timeFormat) && !$A.util.isEmpty(dateFormat)) {
      component.set('v.clonedFieldMapping.format', stringUtils.format('{0}{1}{2}', dateFormat, '|', timeFormat));
    }

    if (clonedFieldMapping.isConditional && $A.util.isEmpty(clonedFieldMapping.conditionalValue)) {
      component.find('conditionalValue').showHelpMessageIfInvalid();
      return;
    }

    clonedFieldMapping.filterBy = typeof clonedFieldMapping.filterBy === 'string' ? clonedFieldMapping.filterBy.trim() : null;
    clonedFieldMapping.orderBy = typeof clonedFieldMapping.orderBy === 'string' ? clonedFieldMapping.orderBy.trim() : null;
    clonedFieldMapping.maximumRecords = $A.util.isEmpty(clonedFieldMapping.maximumRecords) ? clonedFieldMapping.maximumRecords : parseInt(clonedFieldMapping.maximumRecords);
    if (typeof clonedFieldMapping.maximumRecords === 'number' &&
      !isNaN(clonedFieldMapping.maximumRecords) &&
      !helper.validateLimitByValue(clonedFieldMapping.maximumRecords)) {
      return;
    }

    fieldMapping = Object.assign(fieldMapping, clonedFieldMapping);
    helper.updateFieldMappingInConfig(component, fieldMapping);
  },

  closeMergeOptionsModal: function (component, event, helper) {
    helper.closeMergeOptionsModal(component);
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

  setConditionalProperties: function (component, event) {
    //html always returns the value as a string so we're going to convert it back to boolean
    var conditionalValue = event.getSource().get('v.value');
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    var defaultConditionalType = component.get('v.conditionalTypes')[0];
    clonedFieldMapping.isConditional = conditionalValue === 'true';
    clonedFieldMapping.matchType = clonedFieldMapping.isConditional && $A.util.isUndefinedOrNull(clonedFieldMapping.matchType) ? defaultConditionalType.value : clonedFieldMapping.matchType;
    component.set('v.clonedFieldMapping', clonedFieldMapping);
  },

  addSigner: function (component) {
    var template = component.get('v.template');
    var signerMappings = template.signerMappings;

    signerMappings.push({
      fieldMappings: [
        {
          apiName: 's'
        }
      ]
    });

    component.set('v.template', template);
  },

  removeSigner: function (component, event) {
    var index = event.getSource().get('v.value');
    var template = component.get('v.template');
    var signerMappings = template.signerMappings;

    signerMappings.splice(index, 1);

    component.set('v.template', template);
  },

  addSignerField: function (component, event) {
    var index = event.getSource().get('v.value');
    var template = component.get('v.template');
    var signerMappings = template.signerMappings;

    signerMappings[index].fieldMappings.push({
      apiName: 's'
    });

    component.set('v.template', template);
  },

  removeSignerField: function (component, event) {
    var params = event.getParam('data');
    var template = component.get('v.template');
    var signerMappings = template.signerMappings;
    var fieldMappings = signerMappings[params.parentIndex].fieldMappings;
    fieldMappings.splice(params.index, 1);

    if (fieldMappings.length === 0) {
      signerMappings.splice(params.parentIndex, 1);
    }

    component.set('v.template', template);

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
  },

  onFieldLimitChange: function (component, event, helper) {
    helper.onFieldLimitChange(component, event, helper);
  }
});
