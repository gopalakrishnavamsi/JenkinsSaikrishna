({
  cancel: function (component, event, helper) {
    if (component.get('v.invokedFromSetupPage')) {
      component.destroy();
    } else {
      helper.navigateToObjectHome(component);
      component.destroy();
    }
  },

  delete: function (component, event, helper) {
    component.set('v.loading', true);
    var uiHelper = component.get('v.uiHelper');
    var deleteParameters = {
      envelopeConfigurationId: component.get('v.envelopeConfigurationId')
    };

    uiHelper.invokeAction(component.get('c.deleteEnvelopeConfiguration'), deleteParameters, $A.getCallback(function (deleteResponse) {
      component.set('v.loading', false);
      //Delete operation processed successfully
      if (deleteResponse === true) {
        uiHelper.showToast($A.get('$Label.c.EnvelopeTemplateDeleted'), uiHelper.ToastMode.SUCCESS);
      }

      //If the component is created from Setup page context we will fire the event to reload Envelope configuration tab
      if (component.get('v.invokedFromSetupPage')) {
        helper.fireReloadEnvelopeConfigurationTab(component);
        component.find('envelopeConfigurationDelete').destroy();
      }
      //If the component is created from standard delete button click we will navigate back to the Envelope configuration tab after deletion
      else {
        helper.navigateToObjectHome(component);
        component.find('envelopeConfigurationDelete').destroy();
      }
    }));
  },

  navigateToObjectHome: function (component) {
    var ns = component.get('v.namespace');
    ns = $A.util.isEmpty(ns) ? '' : ns + '__';
    var event = $A.get('e.force:navigateToObjectHome');
    event.setParam('scope', ns + 'EnvelopeConfiguration__c');
    event.fire();
  },

  fireReloadEnvelopeConfigurationTab: function (component) {
    component.getEvent('reloadEnvelopeConfigurations').fire();
  }

});