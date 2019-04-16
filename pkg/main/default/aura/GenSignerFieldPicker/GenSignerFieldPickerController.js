({
  init: function (component, event, helper) {
    helper.setTokenValue(component);
  },

  setTokenValue: function (component, event, helper) {
    helper.setTokenValue(component);
  },

  copyToken: function (component) {
    var tokenInput = component.find('token-input');
    tokenInput.getElement().select();
    document.execCommand('copy');

    var evt = component.getEvent('showToast');

    evt.setParams({
      data: {
        msg: $A.get('$Label.c.SuccessCopyClipboard'),
        variant: 'success'
      }
    });

    evt.fire();
  },

  removeSignerField: function (component) {
    var evt = component.getEvent('removeSignerField');
    var params = {
      index: component.get('v.index'),
      parentIndex: component.get('v.parentIndex')
    };

    evt.setParams({
      data: params
    });

    evt.fire();
  }
});