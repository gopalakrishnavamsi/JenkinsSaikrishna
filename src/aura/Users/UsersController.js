({
  init: function (component, event, helper) {
    component.set('v.tableLoading', true);
    helper.getDocuSignUsers(component, event, helper);
  },

  showAddUserModal: function (component, event, helper) {
    component.set('v.showAddUserModal', true);
    window.setTimeout($A.getCallback(function () {
      component.find('lookup').focus();
    }), 1);
  },

  cancelAddUser: function (component, event, helper) {
    var labels = component.labels;
    component.set('v.showAddUserModal', false);
    component.set('v.lookupValue', null);
    component.find('lookup').set('v.error', false);
    component.find('lookup').set('v.errorMessage', $A.get('$Label.c.FieldError'));
    component.set('v.formData', {});
  },

  showRemoveUser: function (component, event, helper) {
    var index = event.getSource().get('v.value');
    var user = component.find('table').get('v.data').rows[index];
    component.set('v.formData.user', user);
    component.set('v.showRemoveUserModal', true);
  },

  hideRemoveUserModal: function (component, event, helper) {
    component.set('v.showRemoveUserModal', false);
  },

  removeDocuSignUser: function (component, event, helper) {
    component.set('v.showToast', false);
    helper.removeUser(component, event, helper);
  },

  validateAddUserForm: function (component, event, helper) {
    event.stopPropagation();

    var lookup = component.find('lookup');
    var inputs = component.find('input');
    var valid = true;

    inputs = Array.isArray(inputs) ? inputs : [inputs]; // Safety first

    if ($A.util.isEmpty(lookup.get('v.value'))) {
      valid = false;
      lookup.set('v.error', true);
    } else {
      lookup.set('v.error', false);
    }

    inputs.forEach(function (input, index) {
      // Force error states from inputs
      if (input.focus) input.focus();
      if (input.blur) input.blur();

      if ($A.util.isEmpty(input.get('v.value'))) {
        valid = false;
      }
    });

    if (valid) {
      component.set('v.showToast', false);
      component.set('v.modalLoading', true);
      helper.createUser(component, event, helper);
    }
  },

  removeLookupErrorState: function (component, event, helper) {
    var lookup = component.find('lookup');
    lookup.set('v.error', false);
    lookup.set('v.errorMessage', $A.get('$Label.c.FieldError'));
    component.set('v.formData', {});

    if (typeof(lookup) !== 'undefined') {
      lookup.set('v.error', false);
      if (component.get('v.showAddUserModal') && lookup.get('v.value')) {
        var userId = lookup.get('v.value');
        helper.getUser(component, event, helper, userId);
      } else {
        component.find('primaryFooterButton').set('v.disabled', false);
      }
    }
  },

  handleUsersChange: function (component, event, helper) {
    helper.buildUsersTable(component, event, helper);
  },

  handleDocuSignUsersChange: function (component, event, helper) {
    var searched = component.find('searchBy').get('v.value');
    component.set('v.users', component.get('v.docuSignUsers'));

    if ($A.util.isEmpty(component.get('v.dsUserSearchTerm'))) {
      helper.resetUsersTable(component, event, helper);
    } else if (searched) {
      helper.searchTable(component, event, helper);
    }
  }
});
