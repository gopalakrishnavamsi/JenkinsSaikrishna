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

  copyToClipboard: function(component, event, helper) {
    try {
      var tempInput = document.createElement('input');
      tempInput.setAttribute('value', component.get('v.documentUrl'));
      document.body.appendChild(tempInput);
      tempInput.select();
      document.execCommand('copy');
      document.body.removeChild(tempInput);  
      component.set('v.linkCopied', true);   
    } catch(err) {
      helper.showToast(component, err, 'error');
    }
 
  }

});
