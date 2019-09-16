({
  initializeComponent: function (component, event, helper) {
    helper.setCurrentUser(component);
    helper.setProductRoles(component, event, helper);
    helper.getProfiles(component, event, helper);
    helper.getPermissionSets(component, event, helper);
    helper.setSortParams(component);
    helper.setAddUserColumns(component);
    helper.setFilterOptions(component);
    helper.setFilters(component);
    helper.buildFilterLabel(component);
    helper.getUsers(component, event, helper);
  },

  setCurrentUser: function (component) {
    component.set('v.currentUserId', $A.get('$SObjectType.CurrentUser.Id'));
  },

  capitalizeRoles: function (role) {
    if (!$A.util.isUndefinedOrNull(role)) {
      return role.charAt(0).toUpperCase() + role.slice(1);
    }
  },

  setProductRoles: function (component, event, helper) {
    component.set('v.userTableLoading', true);
    helper.invokeGetProductRoles(component)
      .then($A.getCallback(function (response) {
        if (!$A.util.isUndefinedOrNull(response)) {
          var productRoles = JSON.parse(response);
          var productsWithRoles = [];
          component.get('v.products').forEach(function (product) {
            var roles = [];
            if (product.name === 'e_sign' && product.status === 'active') {
              roles.push({'label': $A.get('$Label.c.None'), 'value': ''});
              productRoles.e_sign.forEach(function (role) {
                roles.push(
                  {'label': helper.capitalizeRoles(role), 'value': helper.capitalizeRoles(role)}
                );
              });
              product.roles = roles;
            } else if (product.name === 'gen' && product.status === 'active') {
              roles.push({'label': $A.get('$Label.c.None'), 'value': ''});
              productRoles.gen.forEach(function (role) {
                roles.push(
                  {'label': helper.capitalizeRoles(role), 'value': helper.capitalizeRoles(role)}
                );
              });
              product.roles = roles;
            } else if (product.name === 'negotiate' && product.status === 'active') {
              roles.push({'label': $A.get('$Label.c.None'), 'value': ''});
              productRoles.negotiate.forEach(function (role) {
                roles.push(
                  {'label': helper.capitalizeRoles(role), 'value': helper.capitalizeRoles(role)}
                );
              });
              product.roles = roles;
            } else if (product.name === 'clm' && product.status === 'active') {
              roles.push({'label': $A.get('$Label.c.None'), 'value': ''});
              productRoles.clm.forEach(function (role) {
                roles.push(
                  {'label': helper.capitalizeRoles(role), 'value': helper.capitalizeRoles(role)}
                );
              });
              product.roles = roles;
            }
            productsWithRoles.push(product);
          });
          if (!$A.util.isEmpty(productsWithRoles)) {
            component.set('v.products', productsWithRoles);
          }
        }
      }))
      .catch(function (error) {
        helper.showToast(component, error, 'error');
      })
      .finally(function () {
        component.set('v.userTableLoading', false);
      });
  },


  setSortParams: function (component) {
    var userSortParams = {
      sortedBy: 'name',
      sortedDirection: 'desc'
    };

    var addUserSortParams = {
      sortedBy: 'name',
      sortedByLabel: $A.get('$Label.c.NameLabel'),
      sortedDirection: 'asc'
    };

    component.set('v.userSortParams', userSortParams);
    component.set('v.addUserSortParams', addUserSortParams);
  },

  setAddUserColumns: function (component) {
    component.set('v.addUserColumns',
      [
        {
          label: $A.get('$Label.c.FirstName'),
          fieldName: 'FirstName',
          type: 'text',
          sortable: true
        },
        {
          label: $A.get('$Label.c.LastName'),
          fieldName: 'LastName',
          type: 'text',
          sortable: true
        },
        {
          label: $A.get('$Label.c.EmailAddress'),
          fieldName: 'Email',
          type: 'text',
          sortable: true
        },
        {
          label: $A.get('$Label.c.ProfileLabel'),
          fieldName: 'ProfileName',
          type: 'text',
          sortable: true
        }
      ]);
  },

  setFilterOptions: function (component) {
    component.set('v.filterOptions', [{
      disabled: true,
      label: $A.get('$Label.c.User')
    },
      {
        disabled: false,
        label: $A.get('$Label.c.ProfileLabel')
      },
      {
        disabled: false,
        label: $A.get('$Label.c.PermissionSetLabel')
      }
    ]);
  },

  setFilters: function (component) {
    component.set('v.filters', [{
      type: 'User',
      value: ''
    }]);
  },

  updateFilterOptionsState: function (component) {
    var filters = component.get('v.filters');
    var filterOptions = component.get('v.filterOptions');

    filterOptions.forEach(function (filterOption) {
      filterOption.disabled = false;

      filters.forEach(function (filter) {
        if (filter.type === filterOption.label) {
          filterOption.disabled = true;
        }
      });
    });

    component.set('v.filterOptions', filterOptions);
  },

  buildFilterLabel: function (component) {
    var filters = component.get('v.filters');
    var filterLabels = filters.map(function (filter) {
      return filter.type;
    });

    var filterLabel = filterLabels.join(', ');
    component.set('v.filterLabel', filterLabel);
  },

  filterSFUsers: function (component, event, helper) {
    var filters = component.get('v.filters');
    var validFilters = filters.filter(function (filter) {
      return !$A.util.isEmpty(filter.value) && !$A.util.isEmpty(filter.type);
    });

    if (validFilters.length === 0) {
      component.set('v.sfUsers', []);
      component.set('v.hasPopulatedFilters', false);
      return;
    } else {
      component.set('v.hasPopulatedFilters', true);
    }

    var action = component.get('c.filterSFUsers');
    var params = {filters: validFilters};

    action.setParams({
      jsonString: JSON.stringify(params)
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var sfUsers = response.getReturnValue();
        sfUsers.forEach(function (sfUser) {
          if (sfUser.Profile) {
            //lightning data tables can't drill down into multi level objects
            sfUser.ProfileName = sfUser.Profile.Name;
          }
        });
        component.set('v.sfUsers', sfUsers);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.searching', false);
    });

    component.set('v.searching', true);
    $A.enqueueAction(action);
  },

  getUsers: function (component, event, helper) {
    component.set('v.userTableLoading', true);
    helper.invokeGetUsers(component)
      .then($A.getCallback(function (response) {
        component.set('v.users', response);
      }))
      .catch(function (error) {
        helper.showToast(component, error, 'error');
      })
      .finally(function () {
        component.set('v.userTableLoading', false);
      });
  },

  getProfiles: function (component, event, helper) {
    component.set('v.userTableLoading', true);
    helper.invokeGetProfiles(component)
      .then($A.getCallback(function (response) {
        component.set('v.profiles', response);
      }))
      .catch(function (error) {
        helper.showToast(component, error, 'error');
      })
      .finally(function () {
        component.set('v.userTableLoading', false);
      });
  },

  getPermissionSets: function (component, event, helper) {
    component.set('v.userTableLoading', true);
    helper.invokeGetPermissionSets(component)
      .then($A.getCallback(function (response) {
        component.set('v.permSets', response);
      }))
      .catch(function (error) {
        helper.showToast(component, error, 'error');
      })
      .finally(function () {
        component.set('v.userTableLoading', false);
      });
  },

  invokeGetProductRoles: function (component) {
    var invokeGetProductRoles = component.get('c.getProductRoles');
    return new Promise($A.getCallback(function (resolve, reject) {
      invokeGetProductRoles.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(invokeGetProductRoles);
    }));
  },

  //returns a promise which resolves to the response of the getUsers AuraEnabled Apex method
  invokeGetUsers: function (component) {
    var invokeGetUsers = component.get('c.getUsers');
    return new Promise($A.getCallback(function (resolve, reject) {
      invokeGetUsers.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(invokeGetUsers);
    }));
  },

  //returns a promise which resolves to the response of the getProfiles AuraEnabled Apex method
  invokeGetProfiles: function (component) {
    var invokeGetProfiles = component.get('c.getProfiles');
    return new Promise($A.getCallback(function (resolve, reject) {
      invokeGetProfiles.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(invokeGetProfiles);
    }));
  },

  //returns a promise which resolves to the response of the getPermissionSets AuraEnabled Apex method
  invokeGetPermissionSets: function (component) {
    var invokeGetPermissionSets = component.get('c.getPermissionSets');
    return new Promise($A.getCallback(function (resolve, reject) {
      invokeGetPermissionSets.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(invokeGetPermissionSets);
    }));
  },

  resetUsersTable: function (component) {
    component.set('v.filteredUsers', component.get('v.users'));
  },

  searchTable: function (component, userSearchTerm) {
    var users = component.get('v.users');

    //Get users filtered on name
    var filteredUsersByName = users.filter(function (user) {
      return user.name.toUpperCase().match(userSearchTerm.toUpperCase());
    });

    //Get users filtered on email
    var filteredUsersByEmail = users.filter(function (user) {
      return user.email.toUpperCase().match(userSearchTerm.toUpperCase());
    });

    if (!$A.util.isEmpty(filteredUsersByName)) {
      component.set('v.filteredUsers', filteredUsersByName);
    } else if (!$A.util.isEmpty(filteredUsersByEmail)) {
      component.set('v.filteredUsers', filteredUsersByEmail);
    } else {
      component.set('v.filteredUsers', []);
    }
  },

  buildUsersTable: function (component, event, helper) {
    component.set('v.tableLoading', true);
    if (component.get('v.context') === 'e_sign') {
      helper.setEsignContextColumns(component);
    } else if (component.get('v.context') === 'clm') {
      helper.setCLMContextColumns(component);
    }

    var filteredUsers = component.get('v.filteredUsers');
    var userRows = [];

    filteredUsers.forEach(function (user) {
      userRows.push({
        id: user.id.value,
        name: user.name,
        email: user.email,
        //TODO setup user status right now is being returned as blank from getUsers. Added a check currently so that if the status is blank
        // but the id and canManageAccount are valid indicates this as the setup user and the status is shown as Active
        status: !$A.util.isUndefinedOrNull(user.status) ? user.status.toString()
          : ($A.util.isUndefinedOrNull(user.status) && !($A.util.isUndefinedOrNull(user.id) && user.canManageAccount)) ? 'Active' : '',
        admin: user.canManageAccount,
        eSignatureRole: (!$A.util.isUndefinedOrNull(user.roles)
          && !$A.util.isUndefinedOrNull(user.roles.e_sign)
          && !$A.util.isEmpty(user.roles.e_sign)) ? helper.formatRole(user.roles.e_sign) : null,
        documentGenerationRole: (!$A.util.isUndefinedOrNull(user.roles)
          && !$A.util.isUndefinedOrNull(user.roles.gen)
          && !$A.util.isEmpty(user.roles.gen)) ? helper.formatRole(user.roles.gen) : null,
        negotiationRole: (!$A.util.isUndefinedOrNull(user.roles)
          && !$A.util.isUndefinedOrNull(user.roles.negotiate)
          && !$A.util.isEmpty(user.roles.negotiate)) ? helper.formatRole(user.roles.negotiate) : null,
        clmRole: (!$A.util.isUndefinedOrNull(user.roles)
          && !$A.util.isUndefinedOrNull(user.roles.clm)
          && !$A.util.isEmpty(user.roles.clm)) ? helper.formatRole(user.roles.clm) : null,

        provisioned: user.provisioned,
        sourceId: user.sourceId,
      });
    });

    component.set('v.dataRows', userRows);
    component.set('v.tableLoading', false);
    component.set('v.formData', {});
  },

  setEsignContextColumns: function (component) {
    var actions = [
      {label: $A.get('$Label.c.EditPermissions'), name: 'edit_permissions'},
      {label: $A.get('$Label.c.RemoveAndClose'), name: 'remove_close'}
    ];

    //Set the columns for the data table
    component.set('v.dataColumns', [
      {
        sortable: true,
        label: $A.get('$Label.c.NameLabel'),
        type: 'text',
        fieldName: 'name'
      },
      {
        sortable: true,
        label: $A.get('$Label.c.EmailAddress'),
        type: 'text',
        fieldName: 'email'
      },
      {
        sortable: true,
        label: $A.get('$Label.c.Status'),
        type: 'text',
        fieldName: 'status'
      },
      {
        sortable: false,
        label: $A.get('$Label.c.Admin'),
        type: 'boolean',
        fieldName: 'admin'
      },
      {
        sortable: false,
        label: $A.get('$Label.c.TabESignature'),
        type: 'text',
        fieldName: 'eSignatureRole'
      },
      {
        sortable: false,
        label: $A.get('$Label.c.TabDocumentGeneration'),
        type: 'text',
        fieldName: 'documentGenerationRole'
      },
      {
        sortable: false,
        label: $A.get('$Label.c.TabNegotiation'),
        type: 'text',
        fieldName: 'negotiationRole'
      },
      {
        sortable: true,
        label: $A.get('$Label.c.AddedDate'),
        type: 'date',
        fieldName: 'provisioned'
      },
      {
        type: 'action',
        typeAttributes: {
          rowActions: actions
        }
      }
    ]);
  },

  setCLMContextColumns: function (component) {
    var actions = [
      {label: $A.get('$Label.c.EditPermissions'), name: 'edit_permissions'},
      {label: $A.get('$Label.c.RemoveAndClose'), name: 'remove_close'}
    ];

    //Set the columns for the data table
    component.set('v.dataColumns', [
      {
        sortable: true,
        label: $A.get('$Label.c.NameLabel'),
        type: 'text',
        fieldName: 'name'
      },
      {
        sortable: true,
        label: $A.get('$Label.c.EmailAddress'),
        type: 'text',
        fieldName: 'email'
      },
      {
        sortable: true,
        label: $A.get('$Label.c.Status'),
        type: 'text',
        fieldName: 'status'
      },
      {
        sortable: false,
        label: $A.get('$Label.c.Admin'),
        type: 'boolean',
        fieldName: 'admin'
      },
      {
        sortable: false,
        label: $A.get('$Label.c.CLMRole'),
        type: 'text',
        fieldName: 'clmRole'
      },
      {
        sortable: true,
        label: $A.get('$Label.c.AddedDate'),
        type: 'date',
        fieldName: 'provisioned'
      },
      {
        type: 'action',
        typeAttributes: {
          rowActions: actions
        }
      }
    ]);
  },

  sortData: function (component, data, sortParams) {
    var reverse = sortParams.sortedDirection !== 'asc';
    var sortFunction = this.sortBy(sortParams.sortedBy, reverse);
    data.sort(sortFunction);
  },

  sortBy: function (field, reverse, primer) {
    var key = primer ?
      function (x) {
        return primer(x[field]);
      } :
      function (x) {
        return x[field];
      };
    reverse = !reverse ? 1 : -1;
    return function (a, b) {
      return a = key(a) ? key(a) : '', b = key(b) ? key(b) : '', reverse * ((a > b) - (b > a));
    };
  },

  removeAndCloseSingleUser: function (component, event, helper, row) {
    //Current user should not be able to close themselves
    if (row.sourceId.toString() === component.get('v.currentUserId')) {
      helper.showToast(component, $A.get('$Label.c.CannotCloseCurrentUser'), 'error');
      return;
    }
    //Invoke the remove User helper method to Remove and Close the user
    var usersToRemove = [];
    usersToRemove.push(row);
    helper.createRemoveUsersModal(component, event, helper, usersToRemove);
  },

  editPermissionsMultipleUsers: function (component, event, helper) {
    component.get('v.selectedRows').forEach(function (row) {
      //Current user should not be part of editing permissions in bulk
      if (row.sourceId.toString() === component.get('v.currentUserId')) {
        helper.showToast(component, $A.get('$Label.c.CannotEditPermissionsCurrentUser'), 'error');
        return;
      }
    });
  },

  removeAndCloseMultipleUsers: function (component, event, helper) {
    var currentUserSelected = false;
    component.get('v.selectedRows').forEach(function (row) {
      //Current user should not be a part of removing and closing users in bulk
      if (row.sourceId.toString() === component.get('v.currentUserId')) {
        currentUserSelected = true;
      }
    });
    if (currentUserSelected === true) {
      helper.showToast(component, $A.get('$Label.c.CannotCloseCurrentUser'), 'error');
    } else {
      helper.createRemoveUsersModal(component, event, helper, component.get('v.selectedRows'));
    }
  },

  formatRole: function (roles) {
    var formattedRole;
    roles.forEach(function (role) {
      if ($A.util.isUndefinedOrNull(formattedRole)) {
        formattedRole = role;
      } else {
        formattedRole += ', ' + role;
      }
    });
    return formattedRole;
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  },

  clearAddUserModalData: function (component, event, helper) {
    component.set('v.sfUsers', []);
    component.set('v.addUserSortParams', {
      sortedBy: 'Name',
      sortedByLabel: $A.get('$Label.c.NameLabel'),
      sortedDirection: 'asc'
    });
    component.set('v.filters', [{
      type: 'User',
      value: ''
    }]);
    component.set('v.canManageAccount', false);
    component.set('v.genRole', '');
    component.set('v.negotiateRole', '');
    component.set('v.clmRole', '');
    helper.setFilterOptions(component);
  },

  invokeAddUsers: function (component, event, helper) {
    component.set('v.addUsersLoading', true);
    var usersToAdd = helper.prepareUsersList(component);
    var rolesMap = helper.prepareRolesMap(component);
    var action = component.get('c.addUsers');
    action.setParams({
      users: JSON.stringify(usersToAdd),
      roles: JSON.stringify(rolesMap)
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(component, $A.get('$Label.c.UserAddedSuccessfully'), 'success');
        component.set('v.addUsersLoading', false);
        component.find('add-users').hide();
        helper.initializeComponent(component, event, helper);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        component.set('v.addUsersLoading', false);
        component.find('add-users').hide();
      }
    });
    $A.enqueueAction(action);
  },

  prepareUsersList: function (component) {
    var usersListToAdd = [];
    component.find('sfUsers').getSelectedRows().forEach(function (row) {
      var userInstance = {};
      //sourceId
      userInstance.sourceId = !$A.util.isUndefinedOrNull(row.Id) ? row.Id : '';
      //email
      userInstance.email = !$A.util.isUndefinedOrNull(row.Email) ? row.Email : '';
      //firstName
      userInstance.firstName = !$A.util.isUndefinedOrNull(row.FirstName) ? row.FirstName : '';
      //lastName
      userInstance.lastName = !$A.util.isUndefinedOrNull(row.LastName) ? row.LastName : '';
      //canManageAccount
      if (component.get('v.context') === 'e_sign') {
        userInstance.canManageAccount = component.get('v.canManageAccount');
      } else if (component.get('v.context') === 'clm') {
        userInstance.canManageAccount = component.get('v.clmRole') === 'Administrator';
      }
      usersListToAdd.push(userInstance);
    });
    return usersListToAdd;
  },

  prepareRolesMap: function (component) {
    var rolesMap = {};
    if (component.get('v.context') === 'e_sign') {
      var esignRoles = [];
      //If context is e sign then add the default e sign user role
      esignRoles.push(component.get('v.eSignRole'));
      if (component.get('v.canManageAccount') === true) {
        esignRoles.push('Administrator');
      }
      rolesMap.e_sign = esignRoles;

      if (!$A.util.isEmpty(component.get('v.genRole'))) {
        var genRoles = [];
        genRoles.push(component.get('v.genRole'));
        rolesMap.gen = genRoles;
      }
      if (!$A.util.isEmpty(component.get('v.negotiateRole'))) {
        var negotiateRoles = [];
        negotiateRoles.push(component.get('v.negotiateRole'));
        rolesMap.negotiate = negotiateRoles;
      }
    } else if (component.get('v.context') === 'clm') {
      var clmEsignRoles = [];
      //If context is e sign then add the default e sign user role
      clmEsignRoles.push(component.get('v.eSignRole'));
      if (component.get('v.canManageAccount') === true) {
        clmEsignRoles.push('Administrator');
      }
      rolesMap.e_sign = clmEsignRoles;

      if (!$A.util.isEmpty(component.get('v.clmRole'))) {
        var clmRoles = [];
        clmRoles.push(component.get('v.clmRole'));
        rolesMap.clm = clmRoles;
      }
    }
    return rolesMap;
  },

  createRemoveUsersModal: function (component, event, helper, usersToRemove) {
    var modalTitle, modalMessage;
    if (!$A.util.isUndefinedOrNull(usersToRemove) && (!$A.util.isEmpty(usersToRemove))) {
      if (usersToRemove.length === 1) {
        modalTitle = stringUtils.format($A.get('$Label.c.RemoveSingleUserTitle'), usersToRemove[0].name);
        modalMessage = stringUtils.format($A.get('$Label.c.RemoveSingleUserMessage'), usersToRemove[0].name);
      } else {
        modalTitle = stringUtils.format($A.get('$Label.c.RemoveBulkUsersTitle'), usersToRemove.length);
        modalMessage = stringUtils.format($A.get('$Label.c.RemoveBulkUsersMessage'), usersToRemove.length);
      }
      $A.createComponent('c:RemoveUsersModal',
        {
          modalTitle: modalTitle,
          modalMessage: modalMessage,
          userRemovalJson: JSON.stringify(usersToRemove),
          showModal: true
        },
        $A.getCallback(function (componentBody) {
            if (component.isValid()) {
              var targetCmp = component.find('removeModalContent');
              var body = targetCmp.get('v.body');
              targetCmp.set('v.body', []);
              body.push(componentBody);
              targetCmp.set('v.body', body);
            }
          }
        ));
    }
  }

});