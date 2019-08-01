({
  fireApplicationEvent: function (component, params, eventName) {
    var appEvent = $A.get('e.'+component.get('v.namespace')+':' + eventName);
    if (appEvent) {
      appEvent.setParams(params);
      appEvent.fire();
    } else {
      var toast = component.find('toast');
      component.set('v.toastTitleText', stringUtils.format($A.get('$Label.c.NoEventFound'), eventName));
      component.set('v.toastVariant', 'error');
      toast.show();
      setTimeout($A.getCallback(function () {
        toast.close();
      }), 2000);
    }
  },
});