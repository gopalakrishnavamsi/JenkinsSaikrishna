({
  showToast: function (component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.find('toast').show();
  },

  hideToast: function (component) {
    component.find('toast').close();
  },

  setLoading: function (component, loading) {
    component.set('v.loading', loading === true);
  }
});
