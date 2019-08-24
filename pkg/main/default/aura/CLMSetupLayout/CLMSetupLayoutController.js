({
  onInit: function (component, event, helper) {
    helper.insertComponent(component, 'c:CLMSidebar', false, false, 'v.sideBar');
    helper.updateUi(component, '1');
  },

  updateState: function (component, event, helper) {
    var tabIndex = event.getParam('tabIndex');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    if (toComponent === 'CLMSetupLayout' && fromComponent !== 'CLMSetupLayout') {
      helper.updateUi(component, tabIndex);
    }
  },
  
  handleEvent: function (component, event, helper) {
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');
    var data = event.getParam('data');
    if (toComponent === 'CLMSetupLayout' && fromComponent !== 'CLMSetupLayout') {
      if (type === 'toast') {
        helper.showtoast(component, data.title, data.variant);
      }
    }
  },

  triggerLogout: function (component) {
    component.destroy();
  }
});