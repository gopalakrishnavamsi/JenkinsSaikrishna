({
  init: function (component, event, helper) {
    helper.getGenTemplates(component, event, helper);
  },

  createTemplateConfiguration: function (component, event, helper) {
    helper.createNewGenTemplate(component, event, helper);
  }
});