({
  setContinueButtonState: function (component) {
    component.set('v.continueButtonDisabled', component.get('v.isLoggedIn') !== true)
  }
});
