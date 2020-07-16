({
  openEnvelopeConfigModal: function (component) {
    this.createComponent('decNavigator', component, 'c:DECNavigator',
      {
        isRedirectOnCancel: false,
        isFromSetupWizard: true,
        navigateToNewEnvelopeConfigUrl: component.get('v.navigateToNewEnvelopeConfigUrl')
      }
    );
  },

  getEnvelopeConfigurations: function (component, uiHelper) {
    component.set('v.loading', true);
    component.set('v.envelopeConfigurations', []);
    uiHelper.invokeAction(component.get('c.getEnvelopeConfigurations'), {}, $A.getCallback(function (envelopeConfigurations) {
      if ($A.util.isEmpty(envelopeConfigurations)) {
        component.set('v.loading', false);
        return;
      }
      //Table Data
      component.set('v.envelopeConfigurations', envelopeConfigurations.map(function (config) {
        return {
          name: config.name,
          sourceObject: $A.util.isUndefinedOrNull(config.sourceObject) ? null : config.sourceObject,
          lastModifiedDate: config.lastModifiedDate,
          link: '/' + config.id
        };
      }));
      //Table Columns
      //set Row Actions for Editing and Deleting an envelope configuration record
      var rowActionsObject = [
        {
          label: $A.get('$Label.c.Edit'),
          name: 'edit_Action'
        },
        {
          label: $A.get('$Label.c.DeleteButtonLabel'),
          name: 'delete_Action'
        }
      ];
      component.set('v.columns', [
        {
          label: $A.get('$Label.c.NameLabel'),
          fieldName: 'link',
          type: 'url',
          sortable: true,
          typeAttributes: {label: {fieldName: 'name'}, target: '_blank'}
        },
        {
          label: $A.get('$Label.c.MainDataSource'),
          fieldName: 'sourceObject',
          type: 'text',
          sortable: true
        },
        {
          label: $A.get('$Label.c.LastModfiedDateLabel'),
          fieldName: 'lastModifiedDate',
          type: 'date',
          sortable: true,
          typeAttributes: {
            month: '2-digit',
            day: '2-digit',
            year: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
          }
        },
        {
          type: 'action',
          typeAttributes: {rowActions: rowActionsObject}
        }
      ]);
      component.set('v.loading', false);
    }));
  },

  navigateToEditEnvelopeConfiguration: function (component, envelopeConfigurationIdParameter) {
    var navigateToEditEnvelopeConfigUrl = component.get('v.navigateToNewEnvelopeConfigUrl');
    navigateToEditEnvelopeConfigUrl(envelopeConfigurationIdParameter);
  },

  createDeleteComponent: function (component, envelopeConfigurationId) {
    var deleteAttributes = {
      envelopeConfigurationId: envelopeConfigurationId,
      invokedFromSetupPage: true
    };
    //use createComponent from rootContainer
    this.createComponent('deleteDecSetup', component, 'c:EnvelopeConfigurationDelete', deleteAttributes);
  },

  sortData: function (component, fieldName, sortDirection) {
    var data = component.get('v.envelopeConfigurations');
    var reverse = sortDirection !== 'asc';
    data.sort(this.sortBy(fieldName, reverse));
    component.set('v.envelopeConfigurations', data);
  },

  sortBy: function (field, reverse, primer) {
    var key = primer
      ? function (x) {
        return primer(x[field]);
      }
      : function (x) {
        return x[field];
      };
    reverse = !reverse ? 1 : -1;
    return function (a, b) {
      return (a = key(a)), (b = key(b)), reverse * ((a > b) - (b > a));
    };
  }

});