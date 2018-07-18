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

  handleExpiresOn: function (component, event, helper) {
    helper.setExpiry(component, component.get('v.envelope.notifications.expireAfterDays'));
  },

  navigateToTagging: function (component, event, helper) {
    component.set('v.loading', true);

    if (component.get('v.showToast')) {
      component.set('v.showToast', false);
    }
    var getEmptyEnvelope = component.get('c.getEmptyEnvelope');
    var sendEnvelope = component.get('c.sendEnvelope');
    var getTaggingUrl = component.get('c.getTaggingUrl');
    var recipientSettings = component.get('v.recipients');
    var templates = component.get('v.templates');
    var templateIds = [];
    var documents = [];
    recipientSettings.forEach(function (recipient, index) {
      if ($A.util.isEmpty(recipient.id)) {
        recipientSettings.splice(index, 1);
      }
    });

    templates.forEach(function (template) {
      template.recipients.forEach(function (recipient) {
        templateIds.push(template.id.value);
        if (recipient.id) {
          recipient.templateId = template.id.value;
          recipientSettings.push(recipient);
        }
      });
    });

    component.get('v.documents').forEach(function (document) {
      if (document.checked) {
        documents.push(document);
      }
    });

    var envelopeParams = {
      templateIds: templateIds,
      emailSubject: component.get('v.envelope.emailSubject'),
      emailMessage: component.get('v.envelope.emailMessage'),
      language: component.get('v.language'), // TODO: Determine whether we need envelope.language
      notifications: {
        remind: component.get('v.envelope.notifications.remind'),
        remindAfterDays: component.get('v.envelope.notifications.remindAfterDays'),
        remindFrequencyDays: component.get('v.envelope.notifications.remindFrequencyDays'),
        expires: component.get('v.envelope.notifications.expires'),
        expireAfterDays: component.get('v.envelope.notifications.expireAfterDays'),
        expireWarnDays: component.get('v.envelope.notifications.expireWarnDays'),
      }
    };

    getEmptyEnvelope.setParams({
      recordId: component.get('v.recordId'),
      recipientData: JSON.stringify(recipientSettings),
      documentData: JSON.stringify(documents),
      envelopeData: JSON.stringify(envelopeParams)
    });

    getEmptyEnvelope.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        var errMsg = JSON.parse(response.getReturnValue()).errMsg;
        if ($A.util.isEmpty(errMsg)) {
          var envelope = JSON.parse(response.getReturnValue()).results.envelope;

          sendEnvelope.setParams({
            envelopeId: envelope
          });
          sendEnvelope.setCallback(this, function (response) {
            var status = response.getState();
            if (status === "SUCCESS") {
              var errMsg = JSON.parse(response.getReturnValue()).errMsg;
              if ($A.util.isEmpty(errMsg)) {
                var newEnvelope = JSON.parse(response.getReturnValue()).results.envelope;

                getTaggingUrl.setParams({
                  envelopeId: newEnvelope,
                  returnUrl: window.location.origin + '/' + component.get('v.recordId')
                });
                getTaggingUrl.setCallback(this, function (response) {
                  var status = response.getState();
                  if (status === "SUCCESS") {
                    var errMsg = JSON.parse(response.getReturnValue()).errMsg;
                    if ($A.util.isEmpty(errMsg)) {
                      var taggingUrl = JSON.parse(response.getReturnValue()).results.taggingUrl;
                      helper.navigateToDocuSign(component, event, taggingUrl);
                    } else {
                      component.set('v.loading', false);
                      component.set('v.message', errMsg);
                      component.set('v.mode', 'error');
                      component.set('v.showToast', true);
                    }
                  } else {
                    var errMsg = response.getError()[0].message;
                    component.set('v.loading', false);
                    component.set('v.message', errMsg);
                    component.set('v.mode', 'error');
                    component.set('v.showToast', true);
                  }
                });
                $A.enqueueAction(getTaggingUrl);
              } else {
                component.set('v.loading', false);
                component.set('v.message', errMsg);
                component.set('v.mode', 'error');
                component.set('v.showToast', true);
              }
            } else {
              var errMsg = response.getError()[0].message;
              component.set('v.loading', false);
              component.set('v.message', errMsg);
              component.set('v.mode', 'error');
              component.set('v.showToast', true);
            }
          });
          $A.enqueueAction(sendEnvelope);
        } else {
          component.set('v.loading', false);
          component.set('v.message', errMsg);
          component.set('v.mode', 'error');
          component.set('v.showToast', true);
        }
      } else {
        var errMsg = response.getError()[0].message;
        component.set('v.loading', false);
        component.set('v.message', errMsg);
        component.set('v.mode', 'error');
        component.set('v.showToast', true);
      }
    });
    $A.enqueueAction(getEmptyEnvelope);
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
      helper.resetNotificationSettings(component, event, helper);
      component.set('v.emailMessage', null);
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
    var envelopeId = component.get('v.envelope.id');
    if (envelopeId) {
      var deleteEnvelope = component.get('c.deleteEnvelope');
      deleteEnvelope.setParams({
        envelopeId: envelopeId
      });
      deleteEnvelope.setCallback(this, function (response) {
        if (response.getState() !== 'SUCCESS') {
          helper.setError(component, _getErrorMessage(response));
        }
      });
      $A.enqueueAction(deleteEnvelope);
    }

    var sourceId = component.get('v.recordId');
    if (sourceId) {
      _navigateToSObject(sourceId);
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
