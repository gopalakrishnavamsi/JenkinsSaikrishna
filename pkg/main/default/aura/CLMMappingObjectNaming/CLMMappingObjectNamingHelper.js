({
  passModelText: function (component, text, helper) {
    var buttondisabled = component.get('v.buttondisabled');
    if (text && buttondisabled === true) {
      helper.fireApplicationEvent(component, {
        fromComponent: 'CLMMappingObjectNaming',
        toComponent: 'CLMModelFooterButton',
        type: 'enable'
      }, 'CLMEvent');
      component.set('v.buttondisabled', false);
    }
    else if (!text && buttondisabled === false) {
      helper.fireApplicationEvent(component, {
        fromComponent: 'CLMMappingObjectNaming',
        toComponent: 'CLMModelFooterButton',
        type: 'disable'
      }, 'CLMEvent');
      component.set('v.buttondisabled', true);
    }
    var onchangeValue = component.getEvent('CLMMappingObjectEvent_UpdateName');
    onchangeValue.setParams({
      'type': helper.ACTIONUPDATE,
      'fromComponent': 'CLMMappingObjectNaming',
      'toComponent': 'CLMMappedObjectEdit',
      'data': { 'value': text }
    });
    onchangeValue.fire();
  }
});