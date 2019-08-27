({
  initializeComponent: function (component, event, helper) {
    helper.initializeComponent(component, event, helper);
  },

  handleSelect: function (component, event) {
    var selected = event.getParam('name');
    component.set('v.selectedItem', selected);
  },

  navigateToEsignatureTab: function (component) {
    component.set('v.selectedItem', 'tab_eSignature');
  },

  navigateToDocumentGenerationTab: function (component) {
    component.set('v.selectedItem', 'tab_documentGeneration');
  },

  navigateToNegotiationTab: function (component) {
    component.set('v.selectedItem', 'tab_negotiation');
  },

  navigateToUserManagementTab: function (component) {
    component.set('v.selectedItem', 'tab_userManagement');
  },

  navigateToComponentsTab: function (component) {
    component.set('v.selectedItem', 'tab_components');
  },

  navigateToHelpTab: function (component) {
    component.set('v.selectedItem', 'tab_help');
  },

  triggerLogout: function (component) {
    component.destroy();
  }

});