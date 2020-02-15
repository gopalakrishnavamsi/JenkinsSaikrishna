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

  saveTemplate: function (component) {
    component.set('v.loading', true);
    var template = component.get('v.template');
    template.templateType = component.get('v.selectedType');
    template.stepsCompleted = 1;
    template.useAllTemplates = true;
    template.useCurrentRecord = true;
    var action = component.get('c.saveTemplate');
    var saveTemplateParameters = JSON.stringify(template);
    action.setParams({
      templateJson: saveTemplateParameters
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var responseTemplate = response.getReturnValue();
        component.find('genTemplateNavigator').destroy();
        var navigateToNewTemplateUrl = component.get('v.navigateToNewTemplateUrl');
        navigateToNewTemplateUrl(responseTemplate.id);
      } else {
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  }
});
