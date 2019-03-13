({
  onInitialize: function (component, event, helper) {
    var dt = component.get('v.datetime');
    if (dt) {
      component.set('v.dt', {value: new Date(dt), daysBetween: helper.getDaysBetween(dt)});
    }
    var rt = component.get('v.relativeThreshold');
    if (!rt || typeof rt !== 'number' || rt <= 0) {
      component.set('v.relativeThreshold', 7);
    }
  }
});
