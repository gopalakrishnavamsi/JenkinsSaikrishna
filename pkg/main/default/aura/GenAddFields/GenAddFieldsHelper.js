({
  getMergeFieldMapping: function (component, optionModalParams) {
    var self = this;
    var mergeFieldTree = component.get('v.config').objectMappings.fieldMappings;

    var parentNodeOfField = mergeFieldTree.find(function (node) {
      return self.isParentOfField(
        node,
        {
          type: optionModalParams.type,
          depth: optionModalParams.depth,
          key: optionModalParams.key
        });
    });

    return parentNodeOfField.fields[optionModalParams.fieldIndex];
  },

  isParentOfField: function (mergeFieldTreeNode, parentData) {
    var type = parentData.type;
    var key = parentData.key;

    switch (type) {
      case 'ROOT':
        return mergeFieldTreeNode.type === type;
      case 'REFERENCE':
      case 'CHILD_RELATIONSHIP':
        return mergeFieldTreeNode.type === type && mergeFieldTreeNode.key === key;
      default:
        return false;
    }
  },

  checkPath: function (pathToCheck, mergeTreePath) {
    if (pathToCheck.length !== mergeTreePath.length) {
      return false;
    }
    for (var i = 0; i < pathToCheck.length; i++) {
      if (pathToCheck[i] !== mergeTreePath[i]) {
        return false;
      }
    }
    return true;
  },

  //validate custom date and time formats
  validateFormats: function (component) {
    var self = this;
    return self.isCustomDateFormatInvalid(component) || self.isCustomTimeFormatInvalid(component);
  },

  isCustomDateFormatInvalid: function (component) {
    return component.get('v.datePreview') === 'Invalid Date' && component.get('v.dateDropDown') === $A.get('$Label.c.Custom');
  },

  isCustomTimeFormatInvalid: function (component) {
    return component.get('v.timePreview') === 'Invalid Time' && component.get('v.timeDropDown') === $A.get('$Label.c.Custom');
  },

  loadUserLocaleDateFormat: function (component) {
    var defaultDate = $A.localizationService.formatDate($A.get('$Label.c.X2019_01_18'));
    // If the locale Default has a timezone offset, update the default date to 18
    if (defaultDate.includes(17)) {
          defaultDate.replace(17,18);
      } else if (defaultDate.includes(19)) {
          defaultDate.replace(19,18); 
      }      
          component.set('v.userLocaleDateFormat', defaultDate );
  },

  setDateFormatOnOptionsModal: function (component, fieldMapping) {
    var self = this;
    var dateFormat;
    dateFormat = fieldMapping.format.includes('|') ? fieldMapping.format.split('|')[0] : fieldMapping.format;

    // If Date format is not in list of defined time formats, designate it as Custom
    if (!component.get('v.definedDateFormats').includes(dateFormat)) {
      component.set('v.dateDropDown', $A.get('$Label.c.Custom'));
      component.set('v.customDateInput', dateFormat);
      self.formatDate(component);
      
    } else {
      component.set('v.dateDropDown', dateFormat);
      component.set('v.datePreview', '');
      component.set('v.customDateInput', '');
    }
  },

  setTimeFormatOnOptionsModal: function (component, fieldMapping) {
    var self = this;
    var timeFormat;

    timeFormat = fieldMapping.format.includes('|') ? fieldMapping.format.split('|')[1] : fieldMapping.format;

    // If Time format is not in list of defined time formats, designate it as Custom
    if (!component.get('v.definedTimeFormats').includes(timeFormat)) {
      component.set('v.timeDropDown', $A.get('$Label.c.Custom'));
      component.set('v.customTimeInput', timeFormat);
      self.formatTime(component);
      // If Custom designation fails, convert the format to default

    } else {
      component.set('v.timeDropDown', timeFormat);
      component.set('v.timePreview', '');
      component.set('v.customTimeInput', '');
    }
  },

  loadConditionalOptions: function (component) {
    var mergeFieldDisplayOptions = [
      {
        label: $A.get('$Label.c.AlwaysDisplayThisField'),
        value: false
      },
      {
        label: $A.get('$Label.c.IncludeOtherContent'),
        value: true
      }
    ];

    var conditionalTypes = [
      {
        label: $A.get('$Label.c.MatchesLabel'),
        value: 'Match'
      },
      {
        label: $A.get('$Label.c.DoesNotMatch'),
        value: 'NotMatch'
      }
    ];

    component.set('v.mergeFieldDisplayOptions', mergeFieldDisplayOptions);
    component.set('v.conditionalTypes', conditionalTypes);
  },

  // TOOD: Generalize formatDate and formatCurrency and move to stringUtils
  formatDate: function (component) {
    var customDateInputValue = component.get('v.customDateInput');
    if (component.get('v.dateDropDown') === $A.get('$Label.c.Custom')) {
      if (!$A.util.isEmpty(customDateInputValue)) {
        var enteredDateFormat = $A.localizationService.formatDate(new Date($A.get('$Label.c.X2019_01_18')), customDateInputValue);
        if (!component.get('v.definedDateFormats').includes(customDateInputValue)) {
          component.set('v.datePreview', $A.localizationService.formatDate(enteredDateFormat, customDateInputValue));
        } else {
          component.set('v.datePreview', enteredDateFormat);
        }
      } else {
        component.set('v.datePreview', '');
      }
    }
  },

  formatTime: function (component) {
    var customTimeInputValue = component.get('v.customTimeInput');
    if (component.get('v.timeDropDown') === $A.get('$Label.c.Custom')) {
      if (!$A.util.isEmpty(customTimeInputValue)) {
        var enteredTimeFormat = $A.localizationService.formatDate(new Date(), 'YYYY-MM-DD,' + customTimeInputValue);
        var formattedValue = $A.localizationService.formatDate(enteredTimeFormat, 'YYYY-MM-DD,' + customTimeInputValue);
        if (!component.get('v.definedTimeFormats').includes(customTimeInputValue)) {
          component.set('v.timePreview', formattedValue === 'Invalid Date' ? 'Invalid Time' : formattedValue.split(',')[1]);
        } else {
          component.set('v.timePreview', formattedValue.split(',')[1]);
        }
      } else {
        component.set('v.timePreview', '');
      }
    }
  },

  formatPercent: function (component, percentFormat) {
    var defaultValue = 123456789000;
    if (typeof percentFormat !== 'boolean') {
      component.set('v.clonedFieldMapping.format', $A.util.getBooleanValue(percentFormat) ? true : false);
    }
    if (!$A.util.getBooleanValue(percentFormat)) {
      component.set('v.formattedPercent', $A.localizationService.formatNumber(defaultValue));
    } else {
      component.set(
        'v.formattedPercent',
        stringUtils.format('{0}{1}', $A.localizationService.formatNumber(defaultValue, $A.get('$Locale').numberFormat), ' %'));
    }
  },

  formatCurrency: function (component, currencyFormat) {
    var number = 123456.78;
    var locale = $A.get('$Locale');
    var sampleCurrency = 0;
    if (currencyFormat.indexOf('NoDecimals') !== -1) {
      number = Math.round(number);
    }
    number = $A.localizationService.formatNumber(number);
    if (currencyFormat.indexOf('noSymbolNoCode') !== -1) {
      component.set('v.formattedCurrency', number);
    } else {
      var getCurrencySymbol = sampleCurrency.toLocaleString(locale.userLocaleCountry, {
        style: 'currency', currency: locale.currencyCode,
        currencyDisplay: currencyFormat.indexOf('symbol') !== -1 ? 'symbol' : 'code',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      });

      component.set('v.formattedCurrency', getCurrencySymbol.replace('0', number));
    }
  },

  resetValidationErrors: function (component) {
    component.set('v.soqlValidationErrorMessage', null);
    component.set('v.hasSoqlValidationError', false);
  },

  validateChildQuery: function (component, depth, fieldMapping) {
    return new Promise(function (resolve, reject) {
      var action = component.get('c.validateChildRelationshipField');
      action.setParams({
        fieldJSON: JSON.stringify(fieldMapping),
        depth: depth
      });

      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(true);
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });

      $A.enqueueAction(action);
    });
  },

  updateFieldMappingInConfig: function (component, fieldMapping) {
    var self = this;
    var parentIndexInTree;
    var mergeFieldTree = component.get('v.config').objectMappings.fieldMappings.slice();
    var optionModalParams = component.get('v.optionModalParams');
    self.resetValidationErrors(component);

    var parentNodeOfField = mergeFieldTree.find(function (node, index) {
      if (self.isParentOfField(node, optionModalParams)) {
        parentIndexInTree = index;
        return true;
      }
      return false;
    });

    if (fieldMapping.isChildRelation && self.requiresQueryValidation(fieldMapping) && !$A.util.isUndefinedOrNull(parentIndexInTree)) {
      self.validateChildQuery(component, parentNodeOfField.depth + 1, fieldMapping)
        .then(function () {
          parentNodeOfField.fields[optionModalParams.fieldIndex] = fieldMapping;
          mergeFieldTree[parentIndexInTree] = parentNodeOfField;
          component.set('v.config.objectMappings.fieldMappings', mergeFieldTree);
          component.find('merge-token-options').hide();
        })
        .catch($A.getCallback(function (err) {
          component.set('v.soqlValidationErrorMessage', err);
          component.set('v.hasSoqlValidationError', true);
        }));
    } else if (!$A.util.isUndefinedOrNull(parentIndexInTree)) {
      parentNodeOfField.fields[optionModalParams.fieldIndex] = fieldMapping;
      mergeFieldTree[parentIndexInTree] = parentNodeOfField;
      component.set('v.config.objectMappings.fieldMappings', mergeFieldTree);
      component.find('merge-token-options').hide();
    }
  },

  requiresQueryValidation: function (fieldMapping) {
    return !$A.util.isEmpty(fieldMapping.filterBy) || !$A.util.isEmpty(fieldMapping.orderBy);
  },

  onFieldLimitChange: function (component, event, helper) {
    var limitByInputCmp = component.find('limitByInput');
    var value = component.get('v.clonedFieldMapping.maximumRecords');
    var filteredValue = value.replace(/[^0-9]/g, '');
    var numericalValue = parseInt(filteredValue);
    var errorMessage = '';
    if (typeof numericalValue === 'number' &&
      !isNaN(numericalValue) &&
      !helper.validateLimitByValue(numericalValue)) {
      errorMessage = $A.get('$Label.c.LimitByErrorMessage');
    }
    limitByInputCmp.setCustomValidity(errorMessage);
    limitByInputCmp.reportValidity();
    component.set('v.clonedFieldMapping.maximumRecords', $A.util.isEmpty(filteredValue) ? null : filteredValue);
  },

  closeMergeOptionsModal: function (component) {
    var clonedFieldMapping = component.get('v.clonedFieldMapping');
    if (clonedFieldMapping.type === 'CHILD_RELATIONSHIP') {
      var limitByInputCmp = component.find('limitByInput');
      limitByInputCmp.setCustomValidity('');
      limitByInputCmp.reportValidity();
    }
    this.resetValidationErrors(component);
  },

  validateLimitByValue: function (limit) {
    return limit >= 1 && limit <= 2000;
  }
});
