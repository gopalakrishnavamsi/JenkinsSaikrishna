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

    var documents = component.get('v.documents');
    var hasDocuments = documents.some(function (d) {
      return d.selected;
    });
    var envelope = component.get('v.envelope');
    envelope.documents = helper.getDocumentsForSending(documents, component.get('v.template'));
    envelope.recipients = helper.getRecipientsForSending(helper, component.get('v.recipients'), hasDocuments, component.get('v.defaultRoles'));

    helper.tagEnvelope(component, helper, envelope);
  },

  addTemplate: function (component, event, helper) {
    var firstTemplate = component.get('v.availableTemplates')[0];
    helper.updateTemplate(component, helper, $A.util.isUndefinedOrNull(firstTemplate) ? null : firstTemplate.id.value);
  },

  setTemplate: function (component, event, helper) {
    var focusCatcher = component.find('focus-catcher').getElement(); // Avoids base component bug; see .cmp file for more information
    focusCatcher.focus();
    focusCatcher.blur();
    helper.updateTemplate(component, helper, event.getSource().get('v.value'));
  },

  removeTemplate: function (component, event, helper) {
    helper.updateTemplate(component, helper, null);
    // helper.handleFilesChange(component, event, helper);
  },

  addRecipient: function (component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient());
    component.set('v.recipients', recipients);
  },

  removeRecipient: function (component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.splice(event.getSource().get('v.value'), 1);
    component.set('v.recipients', recipients);
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

  handleFileSelected: function (component, event, helper) {
    helper.handleFilesChange(component, event, helper);
  },

  handleActiveStepChange: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component, helper));
    var activeStep = component.get('v.activeStep');
    if (activeStep === 0) { // Documents
      component.set('v.recipients', helper.resetRecipients(helper, component.get('v.recipients')));
    } else if (activeStep === 1) { // Recipients
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
      component.set('v.recipients', helper.getRecipients(helper, component.get('v.recipients'), component.get('v.template')));
    }
  },

  setNextButtonState: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component, helper));
  },

  handleRecipientChange: function (component, event, helper) {
    helper.resolveRecipient(component, helper, event.getParam('data'));
  }
});
