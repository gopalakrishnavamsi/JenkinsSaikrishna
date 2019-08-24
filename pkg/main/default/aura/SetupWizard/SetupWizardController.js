({
  initializeComponent: function (component, event, helper) {
    helper.initializeComponent(component, event, helper);
  },

  handleSelect: function (component, event) {
    var selected = event.getParam('name');
    component.set('v.selectedItem', selected);
  },

  triggerLogout: function (component) {
    component.destroy();
  }

});