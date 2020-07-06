({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized')) {
      var products = component.get('v.products');
      if (!$A.util.isUndefinedOrNull(products)) {
        products.forEach(function (product) {
          if (product.name === 'e_sign') {
            component.set('v.isESignatureEnabled', product.status === 'active');
            component.set('v.isESignatureTrialExpired', product.isExpired);
          }
        });
      }
    }
    helper.createEnvelope(component, component.get('v.recordId'), component.get('v.sObjectName'));
  },

  handleErrorMessage: function (component, message) {
    if (message !== null && message.getParam('errorMessage') !== null) {
      var toast = component.find('ds-toast');
      if (toast) {
        toast.show('error', message.getParam('errorMessage'));
      }
    }
  },

  setExpirationDate: function (component, event, helper) {
    var expireAfterDays = component.get('v.envelope.notifications.expireAfterDays');
    if (!$A.util.isUndefinedOrNull(expireAfterDays)) {
      component.set('v.expiresOn', helper.getExpirationDate(expireAfterDays));
    }
  },

  continueAndTag: function (component, event, helper) {
    var documents = component.get('v.documents');
    var hasDocuments = documents.some(function (d) {
      return d.selected;
    });
    var envelope = component.get('v.envelope');
    envelope.documents = helper.getDocumentsForSending(documents, component.get('v.template'));
    envelope.recipients = helper.getRecipientsForSending(component.get('v.recipients'), hasDocuments, component.get('v.defaultRoles'));
    helper.tagEnvelope(component, envelope);
  },

  addTemplate: function (component, event, helper) {
    var firstTemplate = component.get('v.availableTemplates')[0];
    helper.updateTemplate(component, $A.util.isUndefinedOrNull(firstTemplate) ? null : firstTemplate.id.value);
  },

  setTemplate: function (component, event, helper) {
    var focusCatcher = component.find('focus-catcher').getElement(); // Avoids base component bug; see .cmp file for more information
    focusCatcher.focus();
    focusCatcher.blur();
    helper.updateTemplate(component, event.getSource().get('v.value'));
  },

  removeTemplate: function (component, event, helper) {
    helper.updateTemplate(component, null);
  },

  addRecipient: function (component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient(null, 'Signer'));
    component.set('v.recipients', recipients);
  },

  addCarbonCopy: function (component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient(null, 'CarbonCopy'));
    component.set('v.recipients', recipients);
  },

  removeRecipient: function (component, event) {
    var recipients = component.get('v.recipients');
    recipients.splice(event.getSource().get('v.value'), 1);
    component.set('v.recipients', recipients);
  },

  cancel: function (component, event, helper) {
    helper.cancelSend(component);
  },

  goBack: function (component) {
    component.set('v.activeStep', (component.get('v.activeStep') - 1));
  },

  goNext: function (component) {
    component.set('v.activeStep', (component.get('v.activeStep') + 1));
  },

  toggleAdvancedOptions: function (component) {
    component.set('v.showAdvancedOptions', !component.get('v.showAdvancedOptions'));
  },

  handleFileSelected: function (component, event, helper) {
    helper.handleFilesChange(component);
  },

  handleActiveStepChange: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component));
    var activeStep = component.get('v.activeStep');
    if (activeStep === 0) { // Documents
      component.set('v.recipients', helper.resetRecipients(component.get('v.recipients')));
      component.set('v.areRecipientsSet', false);
    } else if (activeStep === 1 && !component.get('v.areRecipientsSet')) { // Recipients
      var documents = component.get('v.documents');
      var fileCheckboxes = helper.enforceArray(component.find('file-checkbox'));
      var selectedFileTitles = '';

      fileCheckboxes.forEach(function (file) {
        if (typeof (file) !== 'undefined' && file.get('v.checked')) {
          selectedFileTitles += ', ' + documents[file.get('v.value')].name;
        }
      });
      selectedFileTitles = selectedFileTitles.slice(2);
      component.set('v.selectedFileTitles', selectedFileTitles);
      component.set('v.recipients', helper.getRecipients(
        component.get('v.recipients'),
        component.get('v.placeholderRecipients'),
        component.get('v.template'),
        component.get('v.defaultRoles')));
      component.set('v.areRecipientsSet', true);
    }
  },

  setNextButtonState: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component));
  },

  handleRecipientChange: function (component, event, helper) {
    helper.resolveRecipient(component, event.getParam('data'));
  },

  onUploadComplete: function (component, event, helper) {
    var params = event.getParams();
    if (params.success === true) {
      // Reload files
      helper.handleUploadFinished(component);
    }
  },

  onRecipientsChange: function (component, event, helper) {
    component.set('v.disableNext', !helper.getValidity(component));
  },

  onSendComplete: function (component, event, helper) {
    if (!$A.util.isUndefinedOrNull(event)) {
      event.stopPropagation();
      helper.endSendForSignature(component, event.getParam('status'), event.getParam('properties'));
    }
  }
});
