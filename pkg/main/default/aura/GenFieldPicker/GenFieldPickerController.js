({
  onInit: function (component, event, helper) {
    helper.onInit(component, event, helper);
  },

  fieldSelectionChange: function (component, event, helper) {
    helper.fieldSelectionChange(component, event, helper);
  },

  addLookupField: function (component, event, helper) {
    helper.addLookupField(component);
  },

  addChildField: function (component, event, helper) {
    helper.addChildField(component);
  },

  mergeFieldTreeChangeHandler: function (component, event, helper) {
    helper.mergeFieldTreeChangeHandler(component, event, helper);
  },

  copyToken: function (component, event, helper) {
    helper.copyToken(component, event, helper);
  },

  removeField: function (component, event, helper) {
    helper.removeField(component, helper);
  },

  selectedButtonMenuItem: function (component, event, helper) {
    var action = event.getParam('value');

    switch (action) {
      case 'options':
        helper.showMergeOptionsModal(component, helper);
        break;
      case 'remove':
        helper.removeField(component, helper);
        break;
      default:
        break;
    }
  }
});