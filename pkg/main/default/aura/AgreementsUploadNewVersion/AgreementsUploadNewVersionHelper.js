({
  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true, message: message, mode: mode
    });
    evt.fire();
  },

  setUploadEvent: function (component) {
    document.addEventListener("springcm:upload:fileChange", function(event) {
        component.set('v.hasDocument', event.detail && event.detail.files && event.detail.files.length > 0);
    });   
  }  
  
});
