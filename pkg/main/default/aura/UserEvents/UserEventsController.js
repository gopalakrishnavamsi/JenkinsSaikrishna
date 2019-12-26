({
  onScriptsLoaded: function (component, event, helper) {
    helper.setUIHelper(component);
    helper.setUserEvents(component);
  },

  addProperties: function (component, event) {
    var userEvents = component.get('v.userEvents');
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    userEvents.addProperties(event.getParam('arguments')['properties']);
  },

  time: function (component, event) {
    var userEvents = component.get('v.userEvents');
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    var eventName = event.getParam('arguments')['name'];
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    userEvents.time(eventName);
  },

  success: function (component, event) {
    var userEvents = component.get('v.userEvents');
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    var args = event.getParam('arguments');
    var eventName = args['name'];
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    userEvents.success(eventName, args['properties'] || {});
  },

  error: function (component, event) {
    var userEvents = component.get('v.userEvents');
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    var args = event.getParam('arguments');
    var eventName = args['name'];
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    userEvents.error(eventName, args['properties'] || {}, args['error'] || '');
  },

  cancel: function (component, event) {
    var userEvents = component.get('v.userEvents');
    if ($A.util.isUndefinedOrNull(userEvents)) {
      $A.log('Invalid user events');
      return;
    }

    var args = event.getParam('arguments');
    var eventName = args['name'];
    if ($A.util.isUndefinedOrNull(eventName)) {
      $A.log('Invalid event name');
      return;
    }

    userEvents.cancel(eventName, args['properties'] || {});
  }
});
