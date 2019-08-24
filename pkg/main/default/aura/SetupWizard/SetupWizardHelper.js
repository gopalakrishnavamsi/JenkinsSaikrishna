({
  initializeComponent: function (component, event, helper) {
    helper.setNavigationItems(component);
  },

  setNavigationItems: function (component) {
    var sections = [
      {
        label: '',
        items: [
          {
            label: 'Home',
            name: 'tab_home'
          }
        ]
      },
      {
        label: 'Configuration',
        items: [
          {
            label: 'eSignature',
            name: 'tab_eSignature'
          },
          {
            label: 'Document Generation',
            name: 'tab_documentGeneration'
          },
          {
            label: 'Collaboration and Negotiation',
            name: 'tab_negotiation'
          }
        ]
      },
      {
        label: 'Administration',
        items: [
          {
            label: 'User Management',
            name: 'tab_userManagement'
          },
          {
            label: 'Components',
            name: 'tab_components'
          },
          {
            label: 'Help',
            name: 'tab_help'
          }
        ]
      }
    ];
    component.set('v.navigationData', sections);
  },

});