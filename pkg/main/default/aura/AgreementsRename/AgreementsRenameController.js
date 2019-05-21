({
  cancelButtonClicked: function (component, event, helper) {
    helper.close(component, event, helper);
  },

  renameButtonClicked: function (component, event, helper) {
    helper.renameAgreement(component, event, helper);
  },

  onNameChange: function (component, event) {
    var validity = event.getSource().get('v.validity');
    if (validity.valid === true) {
      component.set('v.invalidFileName', false);
    } else {
      component.set('v.invalidFileName', true);
    }
  }
});
