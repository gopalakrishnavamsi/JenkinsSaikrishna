({
  cancelButtonClicked: function (component, event, helper) {
    helper.close(component, event, helper);
  },

  renameButtonClicked: function (component, event, helper) {
    helper.renameAgreement(component, event, helper);
  },

  cancelButtonMouseEnter: function (component) {
    component.set('v.inputRequired', false);
  },

  cancelButtonMouseLeave: function (component) {
    component.set('v.inputRequired', true);
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
