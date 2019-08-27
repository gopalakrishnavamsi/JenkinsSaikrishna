({
  onInitialize: function (component) {
    var login = component.get('v.login');
    component.set('v.accountName', stringUtils.format($A.get('$Label.c.AccountDisplay_2'), login.accounts[0].name, login.accounts[0].accountNumber));
  },

  triggerLogout: function (component) {
    component.getEvent('logoutEvent').fire();
  }
});