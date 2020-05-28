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
          typeAttributes: {label: {fieldName: 'name'}, target: '_blank'}
        },
        {
          label: $A.get('$Label.c.MainDataSource'),
          fieldName: 'sourceObject',
          type: 'text'
        },
        {
          label: $A.get('$Label.c.LastModfiedDateLabel'),
          fieldName: 'lastModifiedDate',
          type: 'date',
          typeAttributes: {year: 'numeric', month: 'long', day: '2-digit', hour: '2-digit', minute: '2-digit'}
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
  }

});