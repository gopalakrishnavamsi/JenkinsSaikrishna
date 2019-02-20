({
  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    if (!$A.util.isUndefinedOrNull(evt)) {
      evt.setParams({
        show: true, message: message, mode: mode
      });
      evt.fire();
    }
  },

  hideToast: function (component) {
    var evt = component.getEvent('toastEvent');
    if (!$A.util.isUndefinedOrNull(evt)) {
      evt.setParams({
        show: false
      });
      evt.fire();
    }
  },

  setLoading: function (component, isLoading) {
    component.set('v.modalLoading', isLoading === true);
    var evt = component.getEvent('loadingEvent');
    if (!$A.util.isUndefinedOrNull(evt)) {
      evt.setParams({
        isLoading: isLoading === true
      });
      evt.fire();
    }
  },

  getUsers: function (component, helper) {
    helper.hideToast(component);
    component.set('v.tableLoading', true);

    var getUsers = component.get('c.getUsers');

    getUsers.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.users', response.getReturnValue());
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
      component.set('v.tableLoading', false);
    });

    $A.enqueueAction(getUsers);
  },

  buildUsersTable: function (component, event, helper) {
    component.set('v.tableLoading', true);
    var filteredUsers = component.get('v.filteredUsers');
    var userRows = [];

    var checkIcon = {
      'type': 'lightning:icon', 'attributes': {
        'iconName': 'utility:check', 'size': 'x-small', 'class': 'slds-m-left_small'
      }
    };

    var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
    filteredUsers.forEach(function (user, index) {
      // CurrentUser.Id uses 15-character Id and API returns 18-character version. T.I.S.
      var allowRemove = user.sourceId.indexOf(currentUserId) !== 0;
      userRows.push({
        id: user.id,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        name: user.name,
        email: user.email,
        admin: !!user.canManageAccount ? checkIcon : null,
        remove: {
          'type': 'lightning:buttonIcon', 'attributes': {
            'value': index,
            'iconName': 'utility:close',
            'onclick': allowRemove ? component.getReference('c.showRemoveUser') : null,
            'size': 'medium',
            'variant': 'bare',
            'class': allowRemove ? 'ds-remove' : 'ds-remove-disabled'
          }
        },
        sourceId: user.sourceId
      });
    });

    var data = {
      'columns': [{
        'sortable': true, 'label': $A.get('$Label.c.SalesforceUser'), 'dataType': 'STRING', 'name': 'name'
      }, {
        'sortable': true, 'label': $A.get('$Label.c.EmailAddress'), 'dataType': 'STRING', 'name': 'email'
      }, {
        'sortable': true, 'label': $A.get('$Label.c.Admin'), 'dataType': 'COMPONENT', 'name': 'admin'
      }, {
        'sortable': false, 'label': $A.get('$Label.c.Remove'), 'dataType': 'COMPONENT', 'name': 'remove'
      }], 'rows': userRows
    };

    component.set('v.data', data);
    component.set('v.tableLoading', false);
    component.set('v.formData', {});
  },

  getUser: function (component, event, helper, userId) {
    helper.hideToast(component);
    helper.setLoading(component, true);

    var users = component.get('v.users');
    var getUser = component.get('c.getUser');

    getUser.setParams({
      userId: userId
    });

    getUser.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        var user = response.getReturnValue();
        if ($A.util.isEmpty(user)) {
          helper.showToast(component, $A.get('$Label.c.UserNotFound'), 'error');
        } else {
          var userMatches = users.filter(function (u) {
            return u.sourceId.indexOf(user.Id) === 0;
          });
          if ($A.util.isEmpty(userMatches)) {
            component.set('v.lookupError', false);
            component.find('primaryFooterButton').set('v.disabled', false);
            component.set('v.formData', {
              user: {
                email: user.Email, firstName: user.FirstName, lastName: user.LastName, sourceId: user.Id
              }
            });
          } else {
            component.set('v.lookupError', true);
            component.find('primaryFooterButton').set('v.disabled', true);
            component.find('lookup').set('v.error', true);
            component.find('lookup').set('v.errorMessage', _format($A.get('$Label.c.AlreadyMember_1'), user.Email));
            component.set('v.formData', {});
          }
        }
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
      helper.setLoading(component, false);
    });
    $A.enqueueAction(getUser);
  },

  searchTable: function (component, name) {
    var users = component.get('v.users');

    var filteredUsers = users.filter(function (user) {
      return user.name.toUpperCase().match(name.toUpperCase());
    });

    if (!$A.util.isEmpty(filteredUsers)) {
      component.set('v.filteredUsers', filteredUsers);
    } else {
      component.set('v.filteredUsers', []);
    }
  },

  createUser: function (component, event, helper) {
    helper.hideToast(component);
    component.set('v.showAddUserModal', false);
    component.set('v.tableLoading', true);

    var addUser = component.get('c.addUser');
    var user = component.get('v.formData.user');

    addUser.setParams({
      sourceId: user.sourceId,
      username: user.email,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      canManageAccount: !!component.find('canManageAccount').get('v.checked')
    });

    addUser.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        component.set('v.users', response.getReturnValue());
        component.set('v.lookupValue', null);
        component.set('v.formData', {});
        helper.showToast(component, _format($A.get('$Label.c.MemberAdded_1'), user.email), 'success');
      } else {
        helper.showToast(component, _getErrorMessage(response), 'error');
      }
      component.set('v.tableLoading', false);
    });
    $A.enqueueAction(addUser);
  },

  removeUser: function (component, event, helper) {
    helper.hideToast(component);
    component.set('v.showRemoveUserModal', false);

    var user = component.get('v.formData.user');
    if ($A.util.isEmpty(user)) {
      helper.setError(component, $A.get('$Label.c.NothingToRemove'));
    } else {
      setTimeout($A.getCallback(function () {
        component.set('v.tableLoading', true);
        var removeFromDocuSign = component.get('c.removeUser');

        removeFromDocuSign.setParams({
          sourceId: user.sourceId, username: user.username
        });

        removeFromDocuSign.setCallback(this, function (response) {
          var status = response.getState();
          if (status === "SUCCESS") {
            component.set('v.users', response.getReturnValue());
            component.set('v.lookupValue', null);
            component.set('v.formData', {});
            helper.showToast(component, _format($A.get('$Label.c.MemberRemoved_1'), user.email), 'success');
          } else {
            helper.showToast(component, _getErrorMessage(response), 'error');
          }
          component.set('v.tableLoading', false);
        });
        $A.enqueueAction(removeFromDocuSign);
      }), 300);
    }
  },

  resetUsersTable: function (component) {
    component.set('v.filteredUsers', component.get('v.users'));
  }
});