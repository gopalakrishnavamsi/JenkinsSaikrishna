({
  onChangeIsAuthorized: function (component, event, helper) {
    helper.processAfterAuthorization(component);
  },
  handleDecErrorMessage: function(component, message) {
    if (message !== null && message.getParam('errorMessage') !== null) {
      var toast = component.find('ds-toast');
      if (toast) {
        toast.show('error', message.getParam('errorMessage'), 'error');
      }
    }
  }
});