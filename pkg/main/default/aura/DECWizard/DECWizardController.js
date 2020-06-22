({
  onChangeIsAuthorized: function (component, event, helper) {
    helper.processAfterAuthorization(component);
  },
  handleErrorMessage: function(component, message) {
    if (message !== null && message.getParam('errorMessage') !== null) {
      var toast = component.find('ds-toast');
      if (toast) {
        toast.show('error', message.getParam('errorMessage'));
      }
    }
  },
  handleSuccessMessage: function(component, message) {
    if (message !== null && message.getParam('successMessage') !== null) {
      var toast = component.find('ds-toast');
      if (toast) {
        toast.show('success', message.getParam('successMessage'));
      }
    }
  }
});