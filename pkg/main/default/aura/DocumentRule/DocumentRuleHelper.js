({
  init: function (component, helper) {
    helper.updateClonedRule(component, helper);
    helper.loadRuleTypeOptions(component);
    helper.updateRuleValidity(component);
  },

  updateClonedRule: function (component, helper) {
    var rule = !$A.util.isUndefinedOrNull(component.get('v.rule')) ? Object.assign({}, component.get('v.rule')) : null;
    component.set('v.clonedRule', helper.newRule(rule));
  },

  loadRuleTypeOptions: function (component) {
    var ruleTypeOptions = [{
      label: $A.get('$Label.c.Any'),
      value: 'any'
    }, {
      label: $A.get('$Label.c.All'),
      value: 'all'
    }];

    component.set('v.ruleTypeOptions', ruleTypeOptions);
  },

  // Create a copy of an existing rule or create a new rule
  // When copying conditions, create a copy of each object element
  newRule: function (rule) {
    var self = this;
    return {
      name: rule ? rule.name : '',
      ruleType: rule ? rule.ruleType : 'any',
      conditions: rule ? rule.conditions.map(function (c) {
        return Object.assign({}, c);
      }) : [self.newCondition()]
    };
  },

  newCondition: function () {
    return {
      fieldName: '',
      fieldType: '',
      matchType: 'equals',
      matchValue: ''
    };
  },

  showRuleModal: function (component) {
    component.set('v.showModal', true);
  },

  closeRuleModal: function (component, helper) {
    helper.updateClonedRule(component, helper);
    component.set('v.showModal', false);
  },

  onRuleChange: function (component, event) {
    var fieldType = event.getSource().get('v.name');
    var newValue = event.getSource().get('v.value');
    var clonedRule = Object.assign({}, component.get('v.clonedRule'));

    clonedRule[fieldType] = newValue.trimLeft();

    component.set('v.clonedRule', clonedRule);
  },

  saveRule: function (component, helper) {
    var clonedRule = Object.assign({}, component.get('v.clonedRule'));
    helper.fireEvent(component, 'saveDocumentRule', {
      data: {
        fileIndex: component.get('v.fileIndex'),
        rule: clonedRule
      }
    });
    component.set('v.showModal', false);
  },

  clearRule: function (component, helper) {
    helper.fireEvent(component, 'clearDocumentRule', {
      data: {
        fileIndex: component.get('v.fileIndex')
      }
    });
    component.set('v.clonedRule', helper.newRule());
    helper.updateRuleValidity(component);
  },

  fireEvent: function (component, eventName, parameters) {
    var event = component.getEvent(eventName);
    event.setParams(parameters);
    event.fire();
  },

  addCondition: function (component, helper) {
    var updatedConditions = component.get('v.clonedRule').conditions.slice();
    updatedConditions.push(helper.newCondition());
    component.set('v.clonedRule.conditions', updatedConditions);
  },

  removeCondition: function (component, event) {
    var data = event.getParam('data');
    var conditionIndex = data.conditionIndex;
    var updatedConditions = component.get('v.clonedRule').conditions.slice();

    updatedConditions.splice(conditionIndex, 1);
    component.set('v.clonedRule.conditions', updatedConditions);
  },

  copyCondition: function (component, event) {
    var data = event.getParam('data');
    var indexToInsert = data.conditionIndex;
    var conditionToCopy = data.condition;
    var updatedConditions = component.get('v.clonedRule').conditions.slice();

    updatedConditions.splice(indexToInsert, 0, conditionToCopy);
    component.set('v.clonedRule.conditions', updatedConditions);
  },

  onConditionChange: function (component, event) {
    var data = event.getParam('data');
    var fieldType = data.fieldType;
    var newValue = data.value;
    var conditionIndex = data.conditionIndex;
    var updatedConditions = component.get('v.clonedRule').conditions.slice();

    // Update by reference to resolve focus issues with condition fields
    updatedConditions[conditionIndex][fieldType] = newValue;
    if (!$A.util.isEmpty(data.fieldOptionType)) {
      updatedConditions[conditionIndex].fieldType = data.fieldOptionType;
    }
  },

  updateRuleValidity: function (component) {
    var ruleName = component.get('v.clonedRule').name;
    var conditions = component.get('v.clonedRule').conditions;

    // Rule is valid if rule name is non-empty and all conditions are populated
    var isRuleValid = !$A.util.isEmpty(ruleName) &&
      $A.util.isEmpty(conditions.filter(function (c) {
        return $A.util.isEmpty(c.fieldName);
      }));

    component.set('v.isRuleValid', isRuleValid);
  }
});