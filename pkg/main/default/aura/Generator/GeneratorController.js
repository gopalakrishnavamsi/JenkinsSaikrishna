({
  onChangeIsAuthorized: function (component, event, helper) {
    var isAuthorized = component.get('v.isAuthorized');
    if (isAuthorized) {
      var config = component.get('v.config');
      helper.checkMultiCurrency(component);

      if ($A.util.isEmpty(config)) {
        var action = component.get('c.getTemplate');

        action.setParams({
          templateId: component.get('v.templateId')
        });

        action.setCallback(this, function (response) {
          if (response.getState() === 'SUCCESS') {
            var results = response.getReturnValue();
            component.set('v.config', results);
            component.set('v.templateFiles', results.generated);
            helper.setupData(component);
          } else {
            component.set('v.errType', 'error');
            component.set('v.errMsg', stringUtils.getErrorMessage(response));
          }
        });
        $A.enqueueAction(action);
      } else {
        component.set('v.isLoading', true);
        // TODO: Verify has Gen license, trial not expired, etc.
        helper.setupData(component);
        component.set('v.isLoading', false);
      }
    }
  },

  generateDocs: function (component, event, helper) {
    helper.getRecordData(component);
  },

  checkRemaingFiles: function (component) {
    var files = component.get('v.templateFiles');
    var selected = [];

    files.forEach(function (el) {
      if (el.isChecked) {
        selected.push(el);
      }
    });

    component.set('v.disableGenerateButton', selected.length === 0);
  },

  removeFocusCatcher: function (component, event) {
    event.currentTarget.remove();
  },

  sendForSignature: function (component, event, helper) {
    helper.sendForSignature(component);
  },

  goBack: function (component) {
    navUtils.navigateToSObject(component.get('v.recordId'));
  },

  previewFile: function (component, event) {
    var fileId = event.currentTarget.getAttribute('data-fileId');
    navUtils.navigateToUrl('/' + fileId);
  },

  downloadFile: function (component, event) {
    var fileId = event.currentTarget.getAttribute('data-fileId');
    navUtils.navigateToUrl($A.get('$Label.c.DocumentPreviewLink') + fileId);
  }
});
