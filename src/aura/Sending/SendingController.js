({
  initialize: function (component, event, helper) {
    helper.createEnvelope(component, helper, component.get('v.recordId'));
  },

  handleUpload: function (component, event, helper) {
    var labels = component.labels;
    if (component.get('v.uploadMessage') === $A.get('$Label.c.UploadSuccessful')) {
      helper.handleUploadFinished(component, event, helper);
    }
  },

  setExpirationDate: function (component, event, helper) {
    var expireAfterDays = component.get('v.envelope.notifications.expireAfterDays');
    if (!$A.util.isUndefinedOrNull(expireAfterDays)) {
      component.set('v.expiresOn', helper.getExpirationDate(expireAfterDays));
    }
  },

  continueAndTag: function (component, event, helper) {
    component.set('v.loading', true);
    if (component.get('v.showToast')) {
      component.set('v.showToast', false);
    }

    var envelope = component.get('v.envelope');
    envelope.documents = helper.getSelectedDocuments(component.get('v.templates'), component.get('v.documents'));
    envelope.recipients = helper.getSelectedRecipients(component.get('v.recipients'), component.get('v.defaultRoles'));

    helper.tagEnvelope(component, helper, envelope);
  },

  addTemplate: function (component, event, helper) {
    var templates = component.get('v.templates');
    var availableTemplates = component.get('v.availableTemplates');
    var selectedTemplate;

    if (templates.length === 0) {
      selectedTemplate = availableTemplates[templates.length];
    } else {
      for (var i = 0; i < availableTemplates.length; i++) {
        if (!availableTemplates[i].selected) {
          selectedTemplate = availableTemplates[i];
          break;
        }
      }
    }

    templates[templates.length] = selectedTemplate;
    component.set('v.templates', templates);
    helper.setTemplateSettings(component, event, helper, selectedTemplate);
  },

  removeTemplate: function (component, event, helper) {
    var targetIndex = event.getSource().get('v.value');
    var templates = component.get('v.templates');
    var availableTemplates = component.get('v.availableTemplates');

    availableTemplates.forEach(function (template) {
      if (template.id.value === templates[targetIndex].id.value) {
        template.selected = false;
        template.recipients.forEach(function (recipient) {
          recipient.id = null;
        });
      }
    });

    templates.splice(targetIndex, 1);

    if ($A.util.isEmpty(templates)) {
      var envelope = component.get('v.envelope');
      envelope.notifications = helper.resetNotificationSettings(envelope.notifications, helper);
      // TODO: Necessary to null out email subject and message?
      // envelope.emailSubject = null;
      // envelope.emailMessage = null;
      helper.handleFilesChange(component, event, helper);
    }
    component.set('v.templates', templates);
    component.set('v.availableTemplates', availableTemplates);
  },

  removeRecipient: function (component, event, helper) {
    var targetIndex = event.getSource().get('v.value');
    var recipientSettings = component.get('v.recipients');

    recipientSettings.splice(targetIndex, 1);
    component.set('v.recipients', recipientSettings);
  },

  setTemplate: function (component, event, helper) {
    var focusCatcher = component.find('focus-catcher').getElement(); // Avoids base component bug; see .cmp file for more information

    focusCatcher.focus();
    focusCatcher.blur();
    helper.setTemplateSettings(component, event, helper, null);
  },

  cancel: function (component, event, helper) {
    component.set('v.loading', true);
    var envelopeId = component.get('v.envelope.id');
    if (envelopeId) {
      var deleteEnvelope = component.get('c.deleteEnvelope');
      deleteEnvelope.setParams({
        envelopeId: envelopeId
      });
      deleteEnvelope.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          var sourceId = component.get('v.recordId');
          if (sourceId) {
            _navigateToSObject(sourceId);
          }
        } else {
          helper.setError(component, _getErrorMessage(response));
          component.set('v.loading', false);
        }
      });
      $A.enqueueAction(deleteEnvelope);
    }


  },

  goBack: function (component, event, helper) {
    component.set('v.activeStep', (component.get('v.activeStep') - 1));
  },

  goNext: function (component, event, helper) {
    component.set('v.activeStep', (component.get('v.activeStep') + 1));
  },

  toggleAdvancedOptions: function (component, event, helper) {
    component.set('v.showAdvancedOptions', !component.get('v.showAdvancedOptions'));
  },

  addRecipient: function (component, event, helper) {
    helper.addBlankRecipient(component);
  },

  handleFileSelected: function (component, event, helper) {
    helper.handleFilesChange(component, event, helper);
  },

  handleActiveStepChange: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component));

    if (component.get('v.activeStep') === 1) {
      var documents = component.get('v.documents');
      var fileCheckboxes = helper.enforceArray(component.find('file-checkbox'));
      var selectedFileTitles = '';

      fileCheckboxes.forEach(function (file, index) {
        if (typeof(file) !== 'undefined' && file.get('v.checked')) {
          selectedFileTitles += ', ' + documents[file.get('v.value')].name;
        }
      });
      selectedFileTitles = selectedFileTitles.slice(2);
      component.set('v.selectedFileTitles', selectedFileTitles);
    }
  },

  setNextButtonState: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component));
  }
});
