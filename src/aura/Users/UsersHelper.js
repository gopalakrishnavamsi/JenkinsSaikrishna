({
  getError: function (component, response) {
    var message = '';
    if (component && response) {
      var errors = response.getError();
      message = errors;
      if (!$A.util.isEmpty(errors)) {
        message = errors[0].message;
      }
    }
    return message;
  },

  setError: function (component, message) {
    if (component && message) {
      console.error(message);
      component.set('v.message', message);
      component.set('v.mode', 'error');
      component.set('v.showToast', true);
      component.set('v.tableLoading', false);
      component.set('v.modalLoading', false);
    }
  },

  getDocuSignUsers: function (component, event, helper) {
    var getDocuSignUsers = component.get('c.getUsers');
    getDocuSignUsers.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        component.set('v.docuSignUsers', response.getReturnValue());
      } else {
        helper.setError(component, helper.getError(component, response));
      }
    });
    $A.enqueueAction(getDocuSignUsers);
  },

  buildUsersTable: function (component, event, helper) {
    var docuSignUsers = component.get('v.users');
    var userRows = [];

    var checkIcon = {
      'type': 'lightning:icon', 'attributes': {
        'iconName': 'utility:check', 'size': 'x-small', 'class': 'slds-m-left_small'
      }
    };

    var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
    docuSignUsers.forEach(function (user, index) {
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
    component.set('v.modalLoading', true);
    var docuSignUsers = component.get('v.docuSignUsers');
    var getUser = component.get('c.getUser');

    getUser.setParams({
      userId: userId
    });

    getUser.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        var user = response.getReturnValue();
        if ($A.util.isEmpty(user)) {
          helper.setError(component, $A.get('$Label.c.UserNotFound'));
        } else {
          var userMatches = docuSignUsers.filter(function (u) {
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
            component.set('v.modalLoading', false);
          } else {
            component.set('v.lookupError', true);
            component.find('primaryFooterButton').set('v.disabled', true);
            component.find('lookup').set('v.error', true);
            component.find('lookup').set('v.errorMessage', _format($A.get('$Label.c.AlreadyMember_1'), user.Email));
            component.set('v.formData', {});
            component.set('v.modalLoading', false);
          }
        }
      } else {
        helper.setError(component, helper.getError(component, response));
      }
    });
    $A.enqueueAction(getUser);
  },

  searchTable: function (component, event, helper) {
    var searchBy = component.find('searchBy').get('v.value');
    var users = component.get('v.docuSignUsers');

    var updateUsersTable = users.filter(function (user) {
      return user.name.toUpperCase().match(searchBy.toUpperCase());
    });

    if (!$A.util.isEmpty(updateUsersTable)) {
      component.set('v.users', updateUsersTable);
    } else {
      component.set('v.users', []);
    }
  },

  createUser: function (component, event, helper) {
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
        var users = response.getReturnValue();
        helper.getDocuSignUsers(component, event, helper);
        component.set('v.message', _format($A.get('$Label.c.MemberAdded_1'), user.email));
        component.set('v.mode', 'success');
        component.set('v.showToast', true);
        component.set('v.showAddUserModal', false);
        component.set('v.modalLoading', false);

        setTimeout($A.getCallback(function () {
          component.set('v.showToast', false);
          component.set('v.lookupValue', null);
          component.set('v.formData', {});
        }), 3000);
      } else {
        helper.setError(component, helper.getError(component, response));
      }
    });
    $A.enqueueAction(addUser);
  },

  removeUser: function (component, event, helper) {
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
            helper.getDocuSignUsers(component, event, helper);
            component.set('v.message', _format($A.get('$Label.c.MemberRemoved_1'), user.email));
            component.set('v.mode', 'success');
            component.set('v.showToast', true);

            setTimeout($A.getCallback(function () {
              component.set('v.showToast', false);
              component.set('v.tableLoading', false);
              component.set('v.showRemoveUserModal', false);
              component.set('v.lookupValue', null);
              component.set('v.formData', {});
            }), 3000);
          } else {
            helper.setError(component, helper.getError(component, response));
          }
        });
        $A.enqueueAction(removeFromDocuSign);
      }), 300);
    }
  },

  resetUsersTable: function (component, event, helper) {
    component.set('v.users', component.get('v.docuSignUsers'));
  }
});
