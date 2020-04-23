({
  init: function (component, event, helper) {
    helper.init(component, helper);
  },

  showRuleModal: function (component, event, helper) {
    helper.showRuleModal(component);
  },

  closeRuleModal: function (component, event, helper) {
    helper.closeRuleModal(component, helper);
  },

  onRuleChange: function (component, event, helper) {
    helper.onRuleChange(component, event);
    helper.updateRuleValidity(component);
  },

  saveRule: function (component, event, helper) {
    helper.saveRule(component, helper);
  },

  clearRule: function (component, event, helper) {
    helper.clearRule(component, helper);
  },

  blurRuleInput: function (component, event, helper) {
    helper.blurRuleInput(component);
  },

  addCondition: function (component, event, helper) {
    helper.addCondition(component, helper);
    helper.updateRuleValidity(component);
  },

  removeCondition: function (component, event, helper) {
    helper.removeCondition(component, event);
    helper.updateRuleValidity(component);
  },

  copyCondition: function (component, event, helper) {
    helper.copyCondition(component, event);
    helper.updateRuleValidity(component);
  },

  onConditionChange: function (component, event, helper) {
    helper.onConditionChange(component, event);
    helper.updateRuleValidity(component);
  },

  updateRuleValidity: function (component, event, helper) {
    helper.updateRuleValidity(component);
  }
});