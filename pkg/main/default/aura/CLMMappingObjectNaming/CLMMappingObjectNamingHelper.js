({
  passModelText: function (component, text, helper) {
    var buttonDisabled = component.get('v.buttonDisabled');
    if (text && buttonDisabled === true) {
      helper.fireApplicationEvent(component, {
        fromComponent: 'CLMMappingObjectNaming',
        toComponent: 'CLMModelFooterButton',
        type: 'enable'
      }, 'CLMEvent');
      component.set('v.buttonDisabled', false);
    }
    else if (!text && buttonDisabled === false) {
      helper.fireApplicationEvent(component, {
        fromComponent: 'CLMMappingObjectNaming',
        toComponent: 'CLMModelFooterButton',
        type: 'disable'
      }, 'CLMEvent');
      component.set('v.buttonDisabled', true);
    }
    var onchangeValue = component.getEvent('CLMMappingObjectEvent_UpdateName');
    onchangeValue.setParams({
      'type': 'update',
      'fromComponent': 'CLMMappingObjectNaming',
      'toComponent': 'CLMMappedObjectEdit',
      'data': { 'value': text }
    });
    onchangeValue.fire();
  }
});