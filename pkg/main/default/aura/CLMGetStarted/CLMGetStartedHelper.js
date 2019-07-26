({
  fireApplicationEvent: function (component, params, eventName) {
    var appEvent = $A.get('e.c:' + eventName);
    if (appEvent) {
      appEvent.setParams(params);
      appEvent.fire();
    } else {
      var toast = component.find('toast');
      component.set('v.toastTitleText', 'No Application event found with name -' + eventName);
      component.set('v.toastVariant', 'error');
      toast.show();
      setTimeout($A.getCallback(function () {
        toast.close();
      }), 2000);
    }
  }
})