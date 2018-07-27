({
  afterRender: function (component, helper) {
    this.superAfterRender();

    if (!component.get('v.login.isLoggedIn')) {
      component.find('login-input').focus();
    }
  }
});
