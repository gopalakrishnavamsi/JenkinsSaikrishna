({
  showToast: function (component, msg, variant) {
    var evt = component.getEvent('showToast');

    evt.setParams({
      data: {
        msg: msg,
        variant: variant
      }
    });

    evt.fire();
  }
});