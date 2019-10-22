({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized')) {
      var products = component.get('v.products');
      products.forEach(function (product) {
        if (product.name === 'clm' && product.status === 'active') {
          component.set('v.isClmEnabled', true);
          helper.verifyUserPermissions(component);
        }
      });
    }    
  },

  onChangeIsClmAdmin: function (component, event, helper) {
    if (component.get('v.isClmAdmin')) {
      helper.insertComponent(component, 'c:CLMSidebar', false, false, 'v.sideBar');
      helper.updateUi(component, '2');
    }
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
      } else if (type === 'closeNotification') {
        component.set('v.isCloseNotification', true);
      }
    }
  },

  triggerLogout: function (component) {
    component.destroy();
  }
});