({
  init: function (component, event, helper) {
    console.log(JSON.stringify(component.get('v.template')));
    helper.init(component, event, helper);
  },

  onUserEventsReady: function (component, event, helper) {
    helper.startPublish(component, event.getParam('userEvents'));
  },

  makeDirty: function (component, event, helper) {
    component.set('v.isDirty', helper.isDirty(component.get('v.layouts'), component));
  },

  updateGenActionLabel: function (component, event, helper) {
    var validity = event.getSource().get('v.validity');
    if (validity.valid === true) {
      helper.updateGenActionLabel(component.get('v.layouts'), component);
      component.set('v.isDirty', helper.isDirty(component.get('v.layouts'), component));
      component.set('v.invalidButtonName', false);
    } else {
      component.set('v.invalidButtonName', true);
    }
  },

  publish: function (component, event, helper) {
    helper.publishGenButtons(component, event, helper);
  },

  validate: function () {
    return new Promise(
      $A.getCallback(function (resolve) {
        resolve();
      })
    );
  }
});