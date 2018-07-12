({
  init: function (component, event, helper) {
    var getInitData = component.get('c.getInitData');
    var getAccount = component.get('c.getDocuSignAccount');

    component.set('v.loading', true);
    getInitData.setParams({
      recordId: component.get('v.recordId')
    });

    getAccount.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var errMsg = JSON.parse(response.getReturnValue()).errMsg;
        if ($A.util.isEmpty(errMsg)) {
          getInitData.setCallback(this, function (response) {
            var status = response.getState();
            if (status === "SUCCESS") {
              var errMsg = JSON.parse(response.getReturnValue()).errMsg;
              if ($A.util.isEmpty(errMsg)) {
                var data = JSON.parse(response.getReturnValue()).results.data;
                component.labels = data.labels;
                var templates = data.templates;
                var documents = data.documents;
                var recipients = data.recipients;
                var recipientType = data.recipientType;
                var expirationDate = new Date();
                expirationDate = expirationDate.setDate(expirationDate.getDate() + component.get('v.expireAfterDays'));
                documents.forEach(function (document) {
                  document.checked = false;
                  document.CreatedDate = new Date(document.CreatedDate).toLocaleString().replace(/,/g, '');
                  document.ContentSize = helper.formatSize(document.ContentSize, 0);
                });
                //make attribute on templates to hold selected value, if empty authentication or email settings make objects to write to
                templates.forEach(function (template) {
                  template.selected = false;
                  template.recipients.forEach(function (recipient) {
                    if ($A.util.isEmpty(recipient.emailSettings)) {
                      recipient.emailSettings = {};
                    }
                    if ($A.util.isEmpty(recipient.authentication)) {
                      recipient.authentication = {};
                    }
                  });
                });
                component.set('v.docuSignTemplates', templates);
                component.set('v.documents', documents);
                component.set('v.selectedRecipients', recipients);
                component.set('v.recipientType', recipientType);
                component.set('v.expiresOn', expirationDate);
                component.set('v.loading', false);
              } else {
                component.set('v.loading', false);
                component.set('v.message', errMsg);
                component.set('v.mode', 'error');
                component.set('v.showToast', true);
              }
            } else {
              var errMsg = JSON.parse(response.getReturnValue()).errMsg;
              component.set('v.loading', false);
              component.set('v.message', errMsg);
              component.set('v.mode', 'error');
              component.set('v.showToast', true);
            }
          });
          $A.enqueueAction(getInitData);

          helper.addBlankRecipient(component);
        } else {
          component.set('v.loading', false);
          component.set('v.message', errMsg);
          component.set('v.mode', 'error');
          component.set('v.showToast', true);
        }
      } else {
        var errMsg = JSON.parse(response.getReturnValue()).errMsg;
        component.set('v.loading', false);
        component.set('v.message', errMsg);
        component.set('v.mode', 'error');
        component.set('v.showToast', true);
      }
    });
    $A.enqueueAction(getAccount);
  },

  handleUpload: function (component, event, helper) {
    var labels = component.labels;
    if (component.get('v.uploadMessage') === labels.Upload_Success) {
      helper.handleUploadFinished(component, event, helper);
    }
  },

  handleExpiresOn: function (component, event, helper) {
    var expirationDate = new Date();
    var expireAfterDays = component.get('v.expireAfterDays');
    if ($A.util.isEmpty(expireAfterDays)) {
      expireAfterDays = 120;
      component.set('v.expireAfterDays', expireAfterDays);
    }
    expirationDate = expirationDate.setDate(expirationDate.getDate() + parseInt(expireAfterDays, 10));

    component.set('v.expiresOn', expirationDate);
  },

  navigateToTagging: function (component, event, helper) {
    component.set('v.loading', true);

    if (component.get('v.showToast')) {
      component.set('v.showToast', false);
    }
    var getEmptyEnvelope = component.get('c.getEmptyEnvelope');
    var sendEnvelope = component.get('c.sendEnvelope');
    var getTaggingUrl = component.get('c.getTaggingUrl');
    var recipientSettings = component.get('v.recipientSettings');
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
      emailSubject: component.get('v.emailSubject'),
      emailMessage: component.get('v.emailMessage'),
      language: component.get('v.language'),
      notifications: {
        remind: component.get('v.remind'),
        remindAfterDays: component.get('v.remindAfterDays'),
        remindFrequencyDays: component.get('v.remindFrequencyDays'),
        expires: component.get('v.expires'),
        expireAfterDays: component.get('v.expireAfterDays'),
        expireWarnDays: component.get('v.expireWarnDays'),
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
                  returnUrl: window.location.origin + '/one/one.app#/sObject/' + component.get('v.recordId') + '/view'
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
    var docuSignTemplates = component.get('v.docuSignTemplates');
    var selectedTemplate;

    if (templates.length === 0) {
      selectedTemplate = docuSignTemplates[templates.length];
    } else {
      for (var i = 0; i < docuSignTemplates.length; i++) {
        if (!docuSignTemplates[i].selected) {
          selectedTemplate = docuSignTemplates[i];
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
    var docuSignTemplates = component.get('v.docuSignTemplates');

    docuSignTemplates.forEach(function (template) {
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
    component.set('v.docuSignTemplates', docuSignTemplates);
  },

  removeRecipient: function (component, event, helper) {
    var targetIndex = event.getSource().get('v.value');
    var recipientSettings = component.get('v.recipientSettings');

    recipientSettings.splice(targetIndex, 1);
    component.set('v.recipientSettings', recipientSettings);
  },

  setLoadingState: function (component, event, helper) {
    component.set('v.loading', false);
  },

  setTemplate: function (component, event, helper) {
    var focusCatcher = component.find('focus-catcher').getElement(); // Avoids base component bug; see .cmp file for more information

    focusCatcher.focus();
    focusCatcher.blur();
    helper.setTemplateSettings(component, event, helper, null);
  },

  cancel: function (component, event, helper) {
    helper.navigateBackToRecord(component, event, helper);
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
          selectedFileTitles += ', ' + documents[file.get('v.value')].Title;
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
