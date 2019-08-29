({
  initializeComponent: function (component, event, helper) {
    helper.setAccountProducts(component);
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
            name: 'tab_documentGeneration',
            icon: $A.util.isUndefinedOrNull(component.get('v.genProduct')) ? 'utility:lock' : null
          },
          {
            label: $A.get('$Label.c.TabNegotiation'),
            name: 'tab_negotiation',
            icon: $A.util.isUndefinedOrNull(component.get('v.negotiateProduct')) ? 'utility:lock' : null
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
  },

  setAccountProducts: function (component) {
    component.get('v.products').forEach(function (product) {
      if (product.name === 'e_sign') {
        component.set('v.eSignProduct', product);
      } else if (product.name === 'gen') {
        component.set('v.genProduct', product);
      } else if (product.name === 'negotiate') {
        component.set('v.negotiateProduct', product);
      }
    });
  }

});