({
  getFieldMapping: function (component, optionModalParams) {
    var config = component.get('v.config');
    var fieldMapping;
    var objMapping = config.objectMappings[optionModalParams.objIndex];

    if (optionModalParams.isChild) {
      var parentFieldMapping =
        objMapping.fieldMappings[optionModalParams.parentIndex];
      fieldMapping =
        parentFieldMapping.childFieldMappings[optionModalParams.fieldIndex];
    } else {
      fieldMapping = objMapping.fieldMappings[optionModalParams.fieldIndex];
    }

    return fieldMapping;
  },

  setConditionalRadio: function (component) {
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

    component.set('v.mergeFieldDisplayOptions', mergeFieldDisplayOptions);
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
    if (percentFormat === false) {
      component.set('v.formattedPercent', $A.localizationService.formatNumber(defaultValue));
    } else {
      component.set(
        'v.formattedPercent',
        $A.localizationService.formatNumber(defaultValue, $A.get('$Locale').numberFormat) + ' %');
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
  }
});
