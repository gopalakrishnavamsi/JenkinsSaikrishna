({
  toggleView: function (component) {
    var acc = component.find('objMapping');
    for (var cmp in acc) {
      $A.util.toggleClass(acc[cmp], 'slds-show');
      $A.util.toggleClass(acc[cmp], 'slds-hide');
    }
  },

  openSetup: function (component) {
    var _this = this;
    var action = component.get('c.getCurrentUserExperience');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var theme = response.getReturnValue();
        if (
          theme === 'Theme4d' ||
          theme === 'Theme4t' ||
          theme === 'Theme4u'
        ) {
          navUtils.navigateToUrl($A.get('$Label.c.LEXObjectManagerURL'));
        } else {
          navUtils.navigateToUrl($A.get('$Label.c.ClassicObjectManagerURL'));
        }
      } else if (state === 'ERROR') {
        var errors = response.getError();
        if (errors && errors[0] && errors[0].message) {
          _this.fireToast(component, errors[0].message, this.ERROR);
        }
      }
    });
    $A.enqueueAction(action);
  },

  updateState: function (component, step) {
    var action = component.get('c.setProgressStatus');
    action.setParams({
      step: step
    });
    $A.enqueueAction(action);
  }
});