({
  init: function (component, event, helper) {
    helper.loadCurrentLevelFieldOptions(component, event, helper);
  },

  validate: function () {
    return new Promise(
      $A.getCallback(function (resolve) {
        resolve();
      })
    );
  },

  uploadStart: function (component) {
    component.set('v.currentAction', $A.get('$Label.c.Uploading'));
  },

  uploadedFile: function (component, event, helper) {
    var data = event.getParam('data');
    var template = component.get('v.template');

    component.set('v.currentAction', '');

    if (data.success) {
      var file = data.file;
      file.isNew = true;
      var files = component.get('v.files');

      files.push(file);

      if (template.name === 'Untitled') {
        template.name = file.title.substring(0, 80);
        component.set('v.template', template);
      }

      component.set('v.files', files);

      helper.showToast(
        component,
        $A.get('$Label.c.FileUploadSuccessMsg'),
        'success'
      );
    } else {
      helper.showToast(
        component,
        $A.get('$Label.c.FileUploadFailMsg'),
        'error'
      );
    }
  },

  removeFile: function (component, event, helper) {
    var files = component.get('v.files');
    var fileIndex = parseInt(event.getSource().get('v.value'), 10);
    var action = component.get('c.deleteContentDocument');
    component.set('v.currentAction', $A.get('$Label.c.Removing'));

    action.setParams({
      contentVersionId: files.splice(fileIndex, 1)[0].id
    });

    action.setCallback(this, function (response) {
      component.set('v.currentAction', '');
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(
          component,
          $A.get('$Label.c.FileUploadSuccessDeleteMsg'),
          'success'
        );
        component.set('v.files', files);
        if (files.length < 2) {
          component
            .find('documentGenerationOptionCheckbox')
            .set('v.checked', true);
        }
      } else if (state === 'ERROR') {
        helper.showToast(
          component,
          $A.get('$Label.c.FileUploadFailDeleteMsg'),
          'error'
        );
      }
    });

    $A.enqueueAction(action);
  },

  saveDocumentRule: function (component, event, helper) {
    helper.saveDocumentRule(component, event);
  },

  clearDocumentRule: function (component, event, helper) {
    helper.clearDocumentRule(component, event);
  }
});