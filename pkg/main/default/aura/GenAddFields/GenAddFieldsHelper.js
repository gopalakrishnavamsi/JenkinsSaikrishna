({
  getFieldMapping: function(component, optionModalParams) {
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

  setConditionalRadio: function(component) {
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
  formatDate: function(component, dateFormat) {
    var date = new Date();

    if (dateFormat === 'default') {
      component.set('v.formattedDate', $A.localizationService.formatDate(date));
    } else {
      component.set(
        'v.formattedDate',
        $A.localizationService.formatDate(date, dateFormat)
      );
    }
  },

  formatCurrency: function(component, currencyFormat) {
    var number = 123456.78;
    var locale = $A.get('$Locale');

    var formattedCurrency = number.toLocaleString(locale.userLocaleCountry, {
      style: 'currency',
      currencyDisplay:
        currencyFormat.indexOf('symbol') !== -1 ? 'symbol' : 'code',
      currency: locale.currencyCode,
      minimumFractionDigits: 0,
      maximumFractionDigits: currencyFormat.indexOf('NoDecimals') !== -1 ? 0 : 2
    });

    component.set('v.formattedCurrency', formattedCurrency);
  }
});
