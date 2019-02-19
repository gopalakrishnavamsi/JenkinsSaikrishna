({
  onToast: function (component, event, helper) {
    event.stopPropagation();
    var toast = component.find('ds-toast');
    var params = event.getParams();
    if (params && params.show === true) {
      component.set('v.message', params.message);
      component.set('v.mode', params.mode);
      toast.show();
      if (params.mode === 'success') {
        setTimeout($A.getCallback(function () {
          toast.close();
        }), 3000);
      }
    } else {
      toast.close();
    }
  },

  onLoading: function (component, event, helper) {
    event.stopPropagation();
    var params = event.getParams();
    component.set('v.loading', params && params.isLoading === true);
  }
});
