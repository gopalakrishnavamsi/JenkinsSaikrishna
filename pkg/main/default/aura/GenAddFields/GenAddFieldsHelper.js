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
          path: optionModalParams.path
        });
    });

    return parentNodeOfField.fields[optionModalParams.fieldIndex];
  },

  isParentOfField: function (mergeFieldTreeNode, parentData) {
    var type = parentData.type;
    var pathToParent = parentData.path.join('.');

    switch (type) {
      case 'ROOT':
        return mergeFieldTreeNode.type === type;
      case 'REFERENCE':
      case 'CHILD_RELATIONSHIP':
        return mergeFieldTreeNode.key === pathToParent;
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
    return ((component.get('v.timePreview') === 'Invalid Time' && component.get('v.timeDropDown') === $A.get('$Label.c.Custom')) ||
      (component.get('v.datePreview') === 'Invalid Date' && component.get('v.dateDropDown') === $A.get('$Label.c.Custom')));
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

  updateFieldMappingInConfig: function (component, fieldMapping) {
    var self = this;
    var parentIndexInTree;
    var mergeFieldTree = component.get('v.config').objectMappings.fieldMappings.slice();
    var optionModalParams = component.get('v.optionModalParams');

    var parentNodeOfField = mergeFieldTree.find(function (node, index) {
      if (self.isParentOfField(node, optionModalParams)) {
        parentIndexInTree = index;
        return true;
      }
      return false;
    });

    if (!$A.util.isUndefinedOrNull(parentIndexInTree)) {
      parentNodeOfField.fields[optionModalParams.fieldIndex] = fieldMapping;
      mergeFieldTree[parentIndexInTree] = parentNodeOfField;
      component.set('v.config.objectMappings.fieldMappings', mergeFieldTree);
    }
  }
});
