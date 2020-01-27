({
  initSetup: function (component) {
    component.set('v.loading', true);
    var isAuthorized = component.get('v.isAuthorized');
    var isGenEnabled = component.get('v.isGenEnabled');
    if (isAuthorized && isGenEnabled) {
      var action = component.get('c.getTemplateTypes');
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.loading', false);
          var templateTypes = [];
          var responseMap = response.getReturnValue();
          for (var key in responseMap) {
            templateTypes.push({label: responseMap[key], name: key});
          }
          component.set('v.templateTypes', templateTypes);
        } else {
          component.set('v.errMsg', stringUtils.getErrorMessage(response));
        }
        component.set('v.loading', false);
      });
      $A.enqueueAction(action);
    }
  },
  saveTemplate: function (component, event, helper) {
    component.set('v.loading', true);
    var template = component.get('v.template');
    template.templateType = component.get('v.selectedType');
    template.stepsCompleted = 1;
    template.useAllTemplates = true;
    template.useCurrentRecord = true;
    var action = component.get('c.saveAndCreateGenTemplateUrl');
    var saveTemplateParameters = JSON.stringify(template);
    action.setParams({
      templateJson: saveTemplateParameters
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var templateUrl = response.getReturnValue();
        component.find('genTemplateNavigator').destroy();
        navUtils.navigateToUrl(templateUrl);
        if (!component.get('v.isFromSetupWizard')) {
          helper.redirectToCancelUrl(component);
        }
      } else {
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  },
  redirectToCancelUrl: function (component) {
    var action = component.get('c.prepareCancelUrl');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var cancelUrl = response.getReturnValue();
        window.open(cancelUrl, '_self');
      } else {
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
      }
    });
    $A.enqueueAction(action);
  }
});