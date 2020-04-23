({
  init: function (component) {
    var conditionTypeOptions = [{
      label: $A.get('$Label.c.Equals'),
      value: 'equals'
    }, {
      label: $A.get('$Label.c.DoesNotEqual'),
      value: 'notEquals'
    }];

    component.set('v.conditionTypeOptions', conditionTypeOptions);
  },

  fireEvent: function (component, eventName, parameters) {
    var event = component.getEvent(eventName);
    if (!$A.util.isUndefinedOrNull(parameters)) {
      event.setParams(parameters);
    }
    event.fire();
  }
});