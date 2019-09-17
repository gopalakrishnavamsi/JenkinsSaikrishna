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
    var deseriazedUsersToRemove = JSON.parse(component.get('v.userRemovalJson'));
    var successModalMessage;
    if (!$A.util.isUndefinedOrNull(deseriazedUsersToRemove) && (!$A.util.isEmpty(deseriazedUsersToRemove))) {
      if (deseriazedUsersToRemove.length === 1) {
        successModalMessage = stringUtils.format($A.get('$Label.c.SingleUserClosedSuccessfully'), deseriazedUsersToRemove[0].name);
      } else {
        successModalMessage = stringUtils.format($A.get('$Label.c.MultipleUsersClosedSuccessfully'), deseriazedUsersToRemove.length);
      }
    }
    removeUsersAction.setParams({
      usersToRemove: component.get('v.userRemovalJson')
    });

    removeUsersAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(component, successModalMessage, 'success');
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
