({
  close: function (component, event, helper) {
    component.set('v.showToast', false);
  },

  show: function (component, event, helper) {
    component.set('v.showToast', true);
  }
});
