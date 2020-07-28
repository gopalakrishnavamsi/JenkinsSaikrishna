({
  handleSuccess: function (component, event, helper) {
    var renderTemplateDetails = component.get('v.renderTemplateDetails');
    renderTemplateDetails();
    helper.hideModal(component);
  },

  hideModal: function (component, event, helper) {
    helper.hideModal(component);
  },

  saveRecord: function (component) {
    component.find('templateEditForm').submit();
  },

  onNameChange: function (component) {
    var templateName = component.find('nameField').get('v.value');
    //validate if templateName contains invalid characters
    // list of invalid characters ? ! < > : | " * \\  \ .
    var containsInvalidCharacters = (templateName.includes('?')||
                                    templateName.includes('!') ||
                                    templateName.includes('<') ||
                                    templateName.includes('>') ||
                                    templateName.includes(':') ||
                                    templateName.includes('|') ||
                                    templateName.includes('"') ||
                                    templateName.includes('*') ||
                                    templateName.includes('\\')||
                                    templateName.includes('.') ||
                                    templateName.includes('\\\\')) ? true : false;
    if (containsInvalidCharacters === true) {
      component.set('v.invalidTemplateName', true);
    }
    else {
      component.set('v.invalidTemplateName', false);
    }
  }
});