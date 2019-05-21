({
  rename: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.rename(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  delete: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.delete(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  internalApproval: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.internalApproval(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  externalReview: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.externalReview(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  upload: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      actions.upload(component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  share: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreement');
      actions.share(agreement, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  }
});
