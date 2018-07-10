({
  format: function(s) {
    if (s) {
      var outerArguments = arguments;
      return s.replace(/\{(\d+)\}/g, function () {
        return outerArguments[parseInt(arguments[1]) + 1];
      });
    }
    return '';
  },

  setError: function (component, response) {
    if (component && response) {
      var errors = response.getError();
      var errMsg = errors;
      if (!$A.util.isEmpty(errors)) {
        errMsg = errors[0].message;
      }
      console.error(errMsg);
      component.set('v.message', errMsg);
      component.set('v.mode', 'error');
      component.set('v.showToast', true);
      component.set('v.modalLoading', false);
    }
  },

  getDocuSignUsers: function (component, event, helper) {
    var getDocuSignUsers = component.get('c.getDocuSignUsers');
    getDocuSignUsers.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        component.set('v.docuSignUsers', response.getReturnValue());
      } else {
        helper.setError(component, response);
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

    docuSignUsers.forEach(function (user, index) {
      var removeButton = {
        'type': 'lightning:buttonIcon', 'attributes': {
          'value': index,
          'iconName': 'utility:close',
          'onclick': component.getReference('c.showRemoveUser'),
          'size': 'medium',
          'variant': 'bare',
          'class': 'ds-remove'
        }
      };
      var row = {
        SalesforceUser: user.Name,
        EmailAddress: user.Email,
        Admin: user.CanManageUsers__c === 'true' ? checkIcon : null,
        Remove: removeButton,
        Id: user.Id
      };
      userRows.push(row);
    });

    var data = {
      'columns': [{
        'sortable': true, 'label': $A.get('$Label.c.SalesforceUser'), 'dataType': 'STRING', 'name': 'SalesforceUser'
      }, {
        'sortable': true, 'label': $A.get('$Label.c.EmailAddress'), 'dataType': 'STRING', 'name': 'EmailAddress'
      }, {
        'sortable': true, 'label': $A.get('$Label.c.Admin'), 'dataType': 'COMPONENT', 'name': 'Admin'
      }, {
        'sortable': false, 'label': $A.get('$Label.c.Remove'), 'dataType': 'COMPONENT', 'name': 'Remove'
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
        var userMatches = docuSignUsers.filter(function (u) {
          return u.Id.match(user.Id);
        });
        if ($A.util.isEmpty(userMatches)) {
          component.set('v.lookupError', false);
          component.find('primaryFooterButton').set('v.disabled', false);
          component.set('v.formData', results);
          component.set('v.modalLoading', false);
        } else {
          component.set('v.lookupError', true);
          component.find('primaryFooterButton').set('v.disabled', true);
          component.find('lookup').set('v.error', true);
          component.find('lookup').set('v.errorMessage', helper.format($A.get('$Label.c.AlreadyMember_1'), user.Email));
          component.set('v.formData', {});
          component.set('v.modalLoading', false);
        }
      } else {
        helper.setError(component, response);
      }
    });
    $A.enqueueAction(getUser);
  },

  searchTable: function (component, event, helper) {
    var searchBy = component.find('searchBy').get('v.value');
    var users = component.get('v.docuSignUsers');

    var updateUsersTable = users.filter(function (user) {
      return user.Name.toUpperCase().match(searchBy.toUpperCase());
    });

    if (!$A.util.isEmpty(updateUsersTable)) {
      component.set('v.users', updateUsersTable);
    } else {
      component.set('v.users', []);
    }
  },

  createUser: function (component, event, helper) {
    var addToDocuSign = component.get('c.addUsers');
    var user = component.get('v.formData.user');
    var canManage = component.find('canManage').get('v.checked');

    addToDocuSign.setParams([{
      source: user.Id,
      userName: user.Email,
      email: user.Email,
      firstName: user.FirstName,
      lastName: user.LastName,
      canManageAccount: !!canManage
    }]);

    addToDocuSign.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        var users = response.getReturnValue();
        helper.getDocuSignUsers(component, event, helper);
        component.set('v.message', helper.format($A.get('$Label.c.MemberAdded_1'), user.Email));
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
        helper.setError(component, response);
      }
    });
    $A.enqueueAction(addToDocuSign);
  },

  removeUser: function (component, event, helper) {
    component.set('v.showRemoveUserModal', false);

    setTimeout($A.getCallback(function () {
      component.set('v.tableLoading', true);
      var removeFromDocuSign = component.get('c.removeUsers');
      var user = component.get('v.formData.user');
      var params = [{
        source: user.Id
      }];

      removeFromDocuSign.setParams({
        userJson: JSON.stringify(params), closeMembership: true
      });

      removeFromDocuSign.setCallback(this, function (response) {
        var status = response.getState();
        if (status === "SUCCESS") {
          var users = response.getReturnValue();
          helper.getDocuSignUsers(component, event, helper);
          component.set('v.message', helper.format($A.get('$Label.c.MemberRemoved_1'), user.EmailAddress));
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
          helper.setError(component, response);
        }
      });
      $A.enqueueAction(removeFromDocuSign);
    }), 300);
  }
});
