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
      } else {
        _this.fireToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(action);
  },

  updateState: function (component, step, checked) {
    var action = component.get('c.setProgressStatus');
    action.setParams({
      step: step,
      checked: checked
    });
    $A.enqueueAction(action);
  }
});
