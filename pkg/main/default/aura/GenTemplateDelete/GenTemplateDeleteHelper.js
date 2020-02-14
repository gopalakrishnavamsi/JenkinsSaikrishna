({
  navigateToObjectHome: function (component) {
    var ns = component.get('v.namespace');
    ns = $A.util.isEmpty(ns) ? '' : ns + '__';
    var event = $A.get('e.force:navigateToObjectHome');
    event.setParam('scope', ns + 'GenTemplate__c');
    event.fire();
  },

  deleteTemplate: function (component) {
    component.set('v.isProcessing', true);
    var helper = this;
    var action = component.get('c.deleteTemplate');
    action.setParams({
      templateId: component.get('v.templateId')
    });
    action.setCallback(this, function (response) {
      component.set('v.isProcessing', false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        var isDeleted = response.getReturnValue();
        if (isDeleted) {
          helper.showToast(component, $A.get('$Label.c.TemplateDeleted'), 'success');
          helper.navigateToObjectHome(component);
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
  }
});
