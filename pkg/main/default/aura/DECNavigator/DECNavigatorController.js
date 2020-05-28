({
  onChangeIsAuthorized: function (component, event, helper) {
    helper.processAfterAuthorization(component);
  },

  createEnvelopeConfig: function (component, event, helper) {
    helper.createEnvelopeConfig(component);
  },

  cancel: function (component) {
    var isRedirectOnCancel = component.get('v.isRedirectOnCancel');
    if (isRedirectOnCancel) {
      var ns = component.get('v.namespace');
      if ($A.util.isEmpty(ns)) {
        ns = '';
      } else {
        ns += '__';
      }
      var event = $A.get('e.force:navigateToObjectHome');
      event.setParam('scope', ns + 'EnvelopeConfiguration__c');
      event.fire();
    } else {
      component.find('decNavigatorModal').destroy();
    }
  }
});