({
  init: function (component) {
    var steps = component.get('v.steps');
    steps = [$A.get('$Label.c.AddObjectsStep'), $A.get('$Label.c.AddMergeFieldsStep'), $A.get('$Label.c.WordTemplatesStep'), $A.get('$Label.c.PreviewStep'), $A.get('$Label.c.PublishStep')];
    component.set('v.steps', steps);

    var templateId = component.get('v.templateId');
    if ($A.util.isEmpty(templateId)) {
      templateId = null;
    }
    component.set('v.saving', true);
    var action = component.get('c.getConfiguration');
    action.setParams({
      templateId: templateId
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        var results = response.getReturnValue();
        results.allObjects.sort(function (a, b) {
          if (a.label > b.label) {
            return 1;
          } else {
            return -1;
          }
        });
        component.set('v.config', results.template);
        component.set('v.files', results.template.generated);
        component.set('v.availableObjects', results.allObjects);
        component.set('v.commonObjects', results.commonObjects);

        var labelByApiName = {};
        results.allObjects.forEach(function (object) {
          var objectKey = object.name;
          var objectName = object.label;
          labelByApiName[objectKey] = objectName;
        });
        component.set('v.labelByApiName', labelByApiName);

        if ($A.util.isEmpty(templateId)) {
          component.set('v.templateId', results.template.id);
        }

        if (results.template.stepsCompleted >= steps.length) {
          component.set('v.currentStep', 0);
          component.set('v.isCompleted', true);
        } else {
          component.set('v.currentStep', results.template.stepsCompleted);
          component.set('v.isCompleted', false);
        }
        component.set('v.saving', false);
      }

      if (state === "ERROR") {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        component.set('v.errMsg', errorMessage);
        component.set('v.saving', false);
      }
    });
    $A.enqueueAction(action);
  },

  publishedButtons: function (component, event, helper) {
    var config = component.get('v.config');
    config.stepsCompleted++;
    component.set('v.config', config);
    component.set('v.isCompleted', true);
    helper.saveData(component);
  },

  nextStep: function (component, event, helper) {
    var stepIndex = component.get('v.currentStep') + 1;
    helper.goToStep(component, stepIndex);
  },

  previousStep: function (component, event, helper) {
    helper.goToStep(component, component.get('v.currentStep') - 1);
  },

  selectStep: function (component, event, helper) {
    var config = component.get('v.config');
    var maxStepsAllowed = config.stepsCompleted + 1;
    var selectedStep = parseInt(event.currentTarget.dataset.step, 10);

    if (selectedStep == 4 && !config.hasPreviewedDocuments) {
      return;
    }

    if (selectedStep <= maxStepsAllowed) {
      helper.goToStep(component, selectedStep);
    }
  },

  showExitModal: function (component, event, helper) {
    var config = component.get('v.config');
    if (config.isSample) {
      helper.goToRecord(component);
    } else {
      component.find('exitModal').show();
    }
  },

  goToRecord: function (component, event, helper) {
    helper.goToRecord(component);
  },

  saveAndNavigate: function (component, event, helper) {
    // Save and navigate
    component.find('exitModal').hide();
    helper.saveData(component).then($A.getCallback(function () {
      helper.goToRecord(component);
    }));
  },

  showToast: function (component, event) {
    var data = event.getParam('data');
    window.clearTimeout(component.toastTimeout);

    component.set('v.showToast', true);
    component.set('v.toastMsg', data.msg);
    component.set('v.toastVariant', data.variant);

    if (data.variant != 'error') {
      component.toastTimeout = window.setTimeout($A.getCallback(function () {
        component.set('v.showToast', false);
      }), 3000);
    }
  },

  hideToast: function (component) {
    component.set('v.showToast', false);
  },

  editDetails: function (component) {
    var recordNameInput = component.find('record-name-input');
    recordNameInput.set('v.value', component.get('v.config').name);
    component.find('edit-modal').show();

    window.setTimeout($A.getCallback(function () {
      recordNameInput.focus();
    }), 250);
  },

  saveDetails: function (component, event, helper) {
    var config = component.get('v.config');
    config.name = component.find('record-name-input').get('v.value');
    component.set('v.config', config);
    component.find('edit-modal').hide();
    helper.saveData(component);
  },

  closeWhatYouWillNeedModal: function (component, event, helper) {
    var isChecked = component.get('v.updateShowWhatYouWillNeedModal');
    if (isChecked) {
      helper.updateShowWhatYouWillNeedModalSettings(component);
    }
    component.set('v.showWhatYouWillNeedModal', false);
  },

  updateWhatYouWillNeedModalSettings: function (component) {
    var isChecked = component.find('dontShowAgainCheckBox').get('v.checked');
    component.set('v.updateShowWhatYouWillNeedModal', isChecked);
  }
});