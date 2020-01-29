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
  }
});