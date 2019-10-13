({
  onChangeIsAuthorized: function (component, event, helper) {
    var products = component.get('v.products');
    if (!$A.util.isUndefinedOrNull(products)) {
      products.forEach(function (product) {
        if (product.name === 'gen') {
          component.set('v.isGenEnabled', true);
        }
      });
    }
    helper.initSetup(component);
  },

  publishedButtons: function (component, event, helper) {
    var config = component.get('v.config');
    config.stepsCompleted++;
    component.set('v.config', config);
    component.set('v.isCompleted', true);
    helper.saveData(component, false);
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

    if (selectedStep === 4 && !config.hasPreviewedDocuments) {
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
    helper.saveData(component, true);
  },

  showToast: function (component, event) {
    var data = event.getParam('data');
    window.clearTimeout(component.toastTimeout);

    component.set('v.showToast', true);
    component.set('v.toastMsg', data.msg);
    component.set('v.toastVariant', data.variant);

    if (data.variant !== 'error') {
      component.toastTimeout = window.setTimeout(
        $A.getCallback(function () {
          component.set('v.showToast', false);
        }),
        3000
      );
    }
  },

  hideToast: function (component) {
    component.set('v.showToast', false);
  },

  editDetails: function (component) {
    var recordNameInput = component.find('record-name-input');
    recordNameInput.set('v.value', component.get('v.config').name);
    component.find('edit-modal').show();

    window.setTimeout(
      $A.getCallback(function () {
        recordNameInput.focus();
      }),
      250
    );
  },

  saveDetails: function (component, event, helper) {
    var config = component.get('v.config');
    config.name = component.find('record-name-input').get('v.value');
    component.set('v.config', config);
    component.find('edit-modal').hide();
    helper.saveData(component, false);
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
