({
  closeScopedNotification: function (component) {
    component.destroy();
  },

  handleScopedNotification1: function (component,event) {
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');
    if (toComponent === 'CLMScopedNotifications' && fromComponent !== 'CLMScopedNotifications') {
      if (type === 'hide') {
        component.set('v.isVisible', false);
      }
      else if (type === 'show') {
        component.set('v.isVisible', true);

      }

    }

  },

});