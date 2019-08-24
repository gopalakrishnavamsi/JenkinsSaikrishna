({
  triggerLogout: function (component) {
    component.getEvent('logoutEvent').fire();
  }
});