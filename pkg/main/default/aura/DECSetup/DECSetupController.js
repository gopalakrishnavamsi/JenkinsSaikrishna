({
  onLoad: function (component, event, helper) {
    var uiHelper = new UIHelper(
      function () {
        return component.getEvent('loadingEvent');
      },
      function () {
        return component.getEvent('toastEvent');
      }
    );
    component.set('v.uiHelper', uiHelper);
    helper.getEnvelopeConfigurations(component, uiHelper);
  },

  createEnvelopeConfig: function (component, event, helper) {
    helper.openEnvelopeConfigModal(component);
  },

  handleRowAction: function (component, event, helper) {
    var action = event.getParam('action');
    var row = event.getParam('row');
    var envelopeConfigurationId = row.link.split('/').pop();

    switch (action.name) {
      case 'edit_Action':
        helper.navigateToEditEnvelopeConfiguration(component, envelopeConfigurationId);
        break;

      case 'delete_Action':
        helper.createDeleteComponent(component, envelopeConfigurationId);
        break;
    }
  },

  updateColumnSorting: function (component, event, helper) {
    var fieldName = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    component.set('v.sortedBy', fieldName);
    var sortedByColumn = '';
    if (fieldName === 'Name') {
      sortedByColumn = 'Name';
    } else if (fieldName === 'SourceObject'){
      sortedByColumn = 'Salesforce Object';
    } else if (fieldName === 'LastModifiedDate') {
      sortedByColumn = 'Date Modified';
    }

    component.set('v.sortedByColumn', sortedByColumn);
    component.set('v.sortedBy', fieldName);
    component.set('v.sortedDirection', sortDirection);
    helper.sortData(component, fieldName, sortDirection);
  },

});