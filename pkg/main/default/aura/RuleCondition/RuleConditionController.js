({
  init: function (component, event, helper) {
    helper.init(component);
  },

  addCondition: function (component, event, helper) {
    helper.fireEvent(component, 'addCondition', null);
  },

  removeCondition: function (component, event, helper) {
    helper.fireEvent(component, 'removeCondition', {
      data: {
        conditionIndex: component.get('v.conditionIndex')
      }
    });
  },

  copyCondition: function (component, event, helper) {
    helper.fireEvent(component, 'copyCondition', {
      data: {
        condition: component.get('v.condition'),
        conditionIndex: component.get('v.conditionIndex')
      }
    });
  },

  onConditionChange: function (component, event, helper) {
    var fieldType = event.getSource().get('v.name');
    var newValue = event.getSource().get('v.value');
    var sanitizedValue = fieldType === 'matchValue' ? newValue.trimLeft() : newValue;
    var data = {
      conditionIndex: component.get('v.conditionIndex'),
      fieldType: fieldType,
      value: sanitizedValue
    };

    if (fieldType === 'fieldName') {
      var fieldData = component.get('v.currentLevelFieldOptions').find(function (field) {
        return field.name === newValue;
      });
      data.fieldOptionType = fieldData.type;
    } else if (fieldType === 'matchValue') {
      var updatedCondition = component.get('v.condition');
      updatedCondition.matchValue = sanitizedValue;
      component.set('v.condition', updatedCondition);
    }

    helper.fireEvent(component, 'onConditionChange', {
      data: data
    });
  }
});