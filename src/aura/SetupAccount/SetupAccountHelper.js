({
  setContinueButtonState: function (component) {
    component.set('v.continueButtonDisabled', component.get('v.login.isLoggedIn') !== true)
  }
});
