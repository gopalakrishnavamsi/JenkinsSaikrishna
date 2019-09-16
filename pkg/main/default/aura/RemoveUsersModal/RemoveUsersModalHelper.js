({
  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  reloadUsers: function (component) {
    component.getEvent('reloadUsersEvent').fire();
  },

  invokeRemoveUsers: function (component, event, helper) {
    component.set('v.loading', true);
    var removeUsersAction = component.get('c.removeUsers');
    removeUsersAction.setParams({
      usersToRemove: component.get('v.userRemovalJson')
    });

    removeUsersAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(component, $A.get('$Label.c.UsersClosedSuccessfully'), 'success');
        component.set('v.loading', false);
        helper.reloadUsers(component);
        helper.close(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        component.set('v.loading', false);
        helper.close(component);
      }
    });
    $A.enqueueAction(removeUsersAction);
  }

});
