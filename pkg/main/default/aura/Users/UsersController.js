({
  initializeComponent: function (component, event, helper) {
    helper.initializeComponent(component, event, helper);
  },

  handleFilteredUsersChange: function (component, event, helper) {
    helper.buildUsersTable(component, event, helper);
  },

  handleUsersChange: function (component, event, helper) {
    var userSearchTerm = component.get('v.userSearchTerm');
    if ($A.util.isEmpty(userSearchTerm)) {
      helper.resetUsersTable(component);
    } else {
      helper.searchTable(component, userSearchTerm);
    }
  },

  handleRowAction: function (component, event, helper) {
    var action = event.getParam('action');
    var row = event.getParam('row');

    switch (action.name) {
      case 'edit_permissions':
        //TODO: Implement edit permissions single row here
        break;
      case 'remove_close':
        helper.removeAndCloseSingleUser(component, row, helper);
        break;
    }
  },

  handleRowSelection: function (component, event) {
    var selectedRows = event.getParam('selectedRows');
    component.set('v.selectedRows', selectedRows);
  },

  editPermissionsMultipleUsers: function (component, event, helper) {
    helper.editPermissionsMultipleUsers(component, event, helper);
  },

  removeAndCloseMultipleUsers: function (component, event, helper) {
    helper.removeAndCloseMultipleUsers(component, event, helper);
  },

  showAddUsersModal: function (component, event, helper) {
    helper.clearAddUserModalData(component, event, helper);
    component.find('add-users').show();
  },

  closeAddUsersModal: function (component) {
    component.find('add-users').hide();
  },

  sortUserTable: function (component, event, helper) {
    var users = component.get('v.filteredUsers');
    var sortParams = component.get('v.userSortParams');
    sortParams.sortedDirection = event.getParam('sortDirection');
    sortParams.sortedBy = event.getParam('fieldName');
    helper.sortData(component, users, sortParams);
    component.set('v.userSortParams', sortParams);
    component.set('v.filteredUsers', users);
  },

  addFilter: function (component, event, helper) {
    var filterOptions = component.get('v.filterOptions');
    var filters = component.get('v.filters');
    for (var i = 0; i < filterOptions.length; i++) {
      var filterOption = filterOptions[i];
      if (!filterOption.disabled) {
        filterOption.disabled = true;
        filters.push({
          type: filterOption.label,
          value: ''
        });
        break;
      }
    }
    component.set('v.filterOptions', filterOptions);
    component.set('v.filters', filters);
    helper.buildFilterLabel(component);
  },

  filterChanged: function (component, event, helper) {
    var index = event.getSource().get('v.name');
    var filters = component.get('v.filters');
    filters[index].value = '';

    helper.updateFilterOptionsState(component);
    component.set('v.filters', filters);

    helper.filterSFUsers(component, event, helper);
    helper.buildFilterLabel(component);
  },

  filterUsers: function (component, event, helper) {
    clearTimeout(component.filterUserTimeout);
    component.filterUserTimeout = setTimeout($A.getCallback(function () {
      helper.filterSFUsers(component, event, helper);
    }), 200);
  },

  removeFilter: function (component, event, helper) {
    var index = event.getSource().get('v.value');
    var filters = component.get('v.filters');
    filters.splice(index, 1);
    component.set('v.filters', filters);
    helper.updateFilterOptionsState(component);
    helper.filterSFUsers(component, event, helper);
    helper.buildFilterLabel(component);
  },

  setTotalCount: function (component, event) {
    component.set('v.selectedUsersCount', event.getParam('selectedRows').length);
  },

  sortAddUsersTable: function (component, event, helper) {
    var sfUsers = component.get('v.sfUsers');
    var sortParams = component.get('v.addUserSortParams');

    sortParams.sortedDirection = event.getParam('sortDirection');
    sortParams.sortedBy = event.getParam('fieldName');
    helper.sortData(component, sfUsers, sortParams);

    var sortField = event.getParam('fieldName');
    switch (sortField) {
      case 'FirstName':
        sortParams.sortedByLabel = $A.get('$Label.c.FirstName');
        break;
      case 'LastName':
        sortParams.sortedByLabel = $A.get('$Label.c.LastName');
        break;
      case 'Email' :
        sortParams.sortedByLabel = $A.get('$Label.c.EmailAddress');
        break;
      case 'ProfileName' :
        sortParams.sortedByLabel = $A.get('$Label.c.ProfileLabel');
        break;
    }

    component.set('v.sfUsers', sfUsers);
    component.set('v.addUserSortParams', sortParams);
  },

  handleAddUsers: function (component, event, helper) {
    helper.invokeAddUsers(component, event, helper);
  }

});