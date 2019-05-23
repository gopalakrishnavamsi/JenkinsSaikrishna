({
  init: function(component, event, helper) {
    helper.getLayouts(component, event, helper);
    helper.getGenActionName(component, event, helper);
  },

  publish: function(component, event, helper) {
    helper.publishGenButtons(component, event, helper);
  },

  checkValidState: function(component) {
    var layouts = component.get('v.layouts');
    var selectedLayouts = [];
    layouts.forEach(function(layout) {
      if (layout.checked) {
        selectedLayouts.push(layout);
      }
    });
    var invalid = false;
    if ($A.util.isEmpty(selectedLayouts)) {
      invalid = true;
    }
    component.set('v.invalidState', invalid);
  },

  validate: function() {
    return new Promise(
      $A.getCallback(function(resolve) {
        resolve();
      })
    );
  }
});
