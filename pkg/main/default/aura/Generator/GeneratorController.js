({
  init: function(component, event, helper) {
    var config = component.get('v.config');
    helper.checkMultiCurrency(component);

    if ($A.util.isEmpty(config)) {
      var action = component.get('c.getTemplate');

      action.setParams({
        templateId: component.get('v.templateId')
      });

      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var results = response.getReturnValue();
          component.set('v.config', results);
          component.set('v.templateFiles', results.generated);
          helper.setupData(component);
        } else if (state === 'ERROR') {
          var errorMessage = $A.get('$Label.c.ErrorMessage');
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              errorMessage += errors[0].message;
            }
          } else {
            errorMessage += $A.get('$Label.c.UnknownError');
          }
          component.set('v.errType', 'error');
          component.set('v.errMsg', errorMessage);
        }
      });
      $A.enqueueAction(action);
    } else {
      component.set('v.isLoading', true);
      // TODO: Verify has Gen license, trial not expired, etc.
      helper.setupData(component);
      component.set('v.isLoading', false);
    }
  },

  generateDocs: function(component, event, helper) {
    helper.getRecordData(component);
  },

  checkRemaingFiles: function(component) {
    var files = component.get('v.templateFiles');
    var selected = [];

    files.forEach(function(el) {
      if (el.isChecked) {
        selected.push(el);
      }
    });

    component.set('v.disableGenerateButton', selected.length === 0);
  },

  removeFocusCatcher: function(component, event) {
    event.currentTarget.remove();
  }
});
