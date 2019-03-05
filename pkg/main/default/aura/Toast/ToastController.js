({
  close: function (component) {
    component.set('v.showToast', false);
  },

  show: function (component) {
    component.set('v.showToast', true);
  }
});
