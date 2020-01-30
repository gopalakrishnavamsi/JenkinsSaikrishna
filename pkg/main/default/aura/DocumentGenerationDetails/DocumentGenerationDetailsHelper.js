({
  getGenTemplates: function (component, event, helper) {
    component.set('v.loading', true);
    var getGenTemplates = component.get('c.getGenTemplates');
    getGenTemplates.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var templates = response.getReturnValue();
        component.set('v.genTemplates', templates);
        if (!$A.util.isEmpty(templates)) {
          var templateRows = [];
          templates.forEach(function (template) {
            templateRows.push({
              name: template.name,
              sourceObject: $A.util.isUndefinedOrNull(template.sourceObject) ? null : template.sourceObject,
              lastModifiedDate: template.lastModifiedDate,
              link: '/' + template.id
            });
          });
          component.set('v.data', templateRows);
          component.set('v.columns', [
            {
              label: $A.get('$Label.c.NameLabel'),
              fieldName: 'link',
              type: 'url',
              typeAttributes: {label: {fieldName: 'name'}, target: '_blank'}
            },
            {
              label: $A.get('$Label.c.MainDataSource'),
              fieldName: 'sourceObject',
              type: 'text'
            },
            {
              label: $A.get('$Label.c.LastModfiedDateLabel'),
              fieldName: 'lastModifiedDate',
              type: 'date',
              typeAttributes: {year: 'numeric', month: 'long', day: '2-digit', hour: '2-digit', minute: '2-digit'}
            }
          ]);
        }
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    }));
    $A.enqueueAction(getGenTemplates);
  },

  createNewGenTemplate: function (component, event, helper) {
    helper.createComponent('genTemplateNavigator', component, 'c:GenTemplateNavigator',
      {
        loading: true,
        isRedirectOnCancel: false,
        isFromSetupWizard: true,
        navigateToNewTemplateUrl: component.get('v.navigateToNewTemplateUrl')
      }
    );
  },

  createComponent: function (anchor, component, componentName, attributes) {
    $A.createComponent(
      componentName,
      attributes,
      $A.getCallback(function (componentBody) {
          if (component.isValid()) {
            var targetCmp = component.find(anchor);
            var body = targetCmp.get('v.body');
            targetCmp.set('v.body', []);
            body.push(componentBody);
            targetCmp.set('v.body', body);
          }
        }
      ));
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  }
});