({
  redirectToCancelUrl: function (component) {
    var helper = this;
    var action = component.get('c.prepareCancelUrl');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var cancelUrl = response.getReturnValue();
        window.open(cancelUrl, '_self');
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(action);
  },
  deleteTemplate: function (component) {
    component.set('v.isProcessing',true);
    var helper = this;
    var action = component.get('c.deleteTemplate');
    action.setParams({
      templateId: component.get('v.templateId')
    });
    action.setCallback(this, function (response) {
      component.set('v.isProcessing',false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        var isDeleted = response.getReturnValue();
        if (isDeleted) {
          helper.showToast(component, $A.get('$Label.c.TemplateDeleted'), 'success');
          helper.redirectToCancelUrl(component);
        }
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function (component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.set('v.showToast', true);
  },

  hideToast: function (component) {
    component.find('toast').close();
  },
});