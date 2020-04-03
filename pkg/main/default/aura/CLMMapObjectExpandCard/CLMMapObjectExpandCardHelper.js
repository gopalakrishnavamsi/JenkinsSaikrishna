({
  fireApplicationEvent: function (component, params, eventName) {
    var appEvent = $A.get('e.' + component.get('v.namespace') + ':' + eventName);
    if (appEvent) {
      appEvent.setParams(params);
      appEvent.fire();
    } else {
      var toast = component.find('toast');
      component.set('v.toastTitleText', stringUtils.format($A.get('$Label.c.NoEventFound'), eventName));
      component.set('v.toastVariant', 'error');
      toast.show('error', stringUtils.format($A.get('$Label.c.NoEventFound'), eventName));
    }
  },

  mappedObjectCount: function (component) {
    var action = component.get('c.getRecordCount');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
        component.set('v.mappedObjCount', result);
      }
    });
    $A.enqueueAction(action);
  }
});