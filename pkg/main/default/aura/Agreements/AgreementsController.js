({
  doInit: function (component, event, helper) {
    component.set('v.loading', true);
    helper.setNameSpace(component, event, helper);
    helper.getAgreements(component, event, helper);
  },

  handleToastEvent: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
      if (params.mode === 'success') {
        setTimeout($A.getCallback(function () {
          helper.hideToast(component);
        }), 3000);
      }
    } else {
      helper.hideToast(component);
    }
  },

  importAgreements: function (component, event, helper) {
    helper.createImportComponent(component, event, helper);
  }
});
