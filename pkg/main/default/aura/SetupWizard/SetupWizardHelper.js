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
            label: $A.get('$Label.c.TabHome'),
            name: 'tab_home'
          }
        ]
      },
      {
        label: $A.get('$Label.c.ConfigurationSection'),
        items: [
          {
            label: $A.get('$Label.c.TabESignature'),
            name: 'tab_eSignature'
          },
          {
            label: $A.get('$Label.c.TabDocumentGeneration'),
            name: 'tab_documentGeneration'
          },
          {
            label: $A.get('$Label.c.TabNegotiation'),
            name: 'tab_negotiation'
          }
        ]
      },
      {
        label: $A.get('$Label.c.AdministrationSection'),
        items: [
          {
            label: $A.get('$Label.c.TabUserManagement'),
            name: 'tab_userManagement'
          },
          {
            label: $A.get('$Label.c.TabComponents'),
            name: 'tab_components'
          },
          {
            label: $A.get('$Label.c.TabHelp'),
            name: 'tab_help'
          }
        ]
      }
    ];
    component.set('v.navigationData', sections);
  }

});