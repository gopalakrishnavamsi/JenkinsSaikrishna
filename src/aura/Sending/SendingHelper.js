({
  setError: function (component, message) {
    component.set('v.loading', false);
    component.set('v.message', message);
    component.set('v.mode', 'error');
    component.set('v.showToast', true);
  },

  createEnvelope: function (component, helper, sourceId) {
    component.set('v.loading', true);
    var createDraftEnvelope = component.get('c.createDraftEnvelope');
    createDraftEnvelope.setParams({
      sourceId: sourceId
    });
    createDraftEnvelope.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var draftEnvelope = response.getReturnValue();
        // Add front-end properties to documents
        if (!$A.util.isEmpty(draftEnvelope.documents)) {
          draftEnvelope.documents.forEach(function (d) {
            helper.addDocumentProperties(d, false);
          });
        }
        if (!$A.util.isEmpty(draftEnvelope.recipients)) {
          draftEnvelope.recipients.forEach(helper.addRecipientProperties);
        }
        if (!$A.util.isEmpty(draftEnvelope.templates)) {
          draftEnvelope.templates.forEach(function (template) {
            template.selected = false;
            if (!$A.util.isEmpty(template.recipients)) {
              template.recipients.forEach(helper.addRecipientProperties);
            }
          });
        }
        component.set('v.envelope', draftEnvelope.envelope);
        component.set('v.availableTemplates', draftEnvelope.templates);
        component.set('v.documents', draftEnvelope.documents);
        component.set('v.recipients', draftEnvelope.recipients);
        component.set('v.enabledLanguages', draftEnvelope.emailSettings);
        //component.set('v.emailSubject', draftEnvelope.envelope.emailSubject);
        component.set('v.loading', false);
      } else {
        helper.setError(component, _getErrorMessage(response));
      }
    });
    $A.enqueueAction(createDraftEnvelope);
  },

  addDocumentProperties: function (doc, selected) {
    if (doc) {
      doc.selected = !!selected;
      doc.formattedSize = !!doc.size ? _formatSize(doc.size) : '';
      doc.formattedCreated = !!doc.created ? new Date(doc.created).toLocaleString() : '';
    }
    return doc;
  },

  addRecipientProperties: function (recipient, selected) {
    if (recipient) {
      recipient.selected = !!selected;
      if ($A.util.isEmpty(recipient.emailSettings)) {
        recipient.emailSettings = {};
      }
      if ($A.util.isEmpty(recipient.authentication)) {
        recipient.authentication = {};
      }
    }
    return recipient;
  },

  navigateToDocuSign: function (component, event, url) {
    var navEvt = $A.get('e.force:navigateToURL');
    if (!$A.util.isEmpty(navEvt)) {
      navEvt.setParams({
        'url': url
      });
      navEvt.fire();
    }
  },

  navigateBackToRecord: function (component, event, url) {
    sforce.one.navigateToSObject(component.get('v.recordId'));
  },

  enforceArray: function (results) {
    return Array.isArray(results) ? results : [results];
  },

  resetNotificationSettings: function (component, event, helper) {
    component.set('v.remind', false);
    component.set('v.expires', true);
    component.set('v.expireAfterDays', 120);
    component.set('v.expireWarnDays', 0);
    component.set('v.remindAfterDays', 0);
    component.set('v.remindFrequencyDays', 0);
    var expirationDate = new Date();
    expirationDate = expirationDate.setDate(expirationDate.getDate() + component.get('v.expireAfterDays'));
    component.set('v.expiresOn', expirationDate);
  },

  setTemplateSettings: function (component, event, helper, selectedTemplate) {
    var templates = component.get('v.templates');
    var index = event.getSource().get('v.name');

    if (typeof(index) !== 'undefined') {
      if (!$A.util.isEmpty(templates[index])) {
        helper.updateTemplates(component, event, helper, index);
      }
    }

    var selectedTemplateId = $A.util.isEmpty(event.getSource().get('v.value')) ? selectedTemplate.id.value : event.getSource().get('v.value');
    var availableTemplates = component.get('v.availableTemplates');

    availableTemplates.forEach(function (template, index) {
      if (template.id.value === selectedTemplateId) {
        if (template.notifications != null) {
          component.set('v.remind', template.notifications.remind);
          component.set('v.expires', template.notifications.expires);
          component.set('v.expireAfterDays', template.notifications.expireAfterDays);
          component.set('v.expireWarnDays', template.notifications.expireWarnDays);
          component.set('v.remindAfterDays', template.notifications.remindAfterDays);
          component.set('v.remindFrequencyDays', template.notifications.remindAfterDays);
          var expirationDate = new Date();
          expirationDate = expirationDate.setDate(expirationDate.getDate() + component.get('v.expireAfterDays'));
          component.set('v.expiresOn', expirationDate);
        } else {
          helper.resetNotificationSettings(component, event, helper);
        }
        component.set('v.emailMessage', template.emailMessage);
        component.set('v.emailSubject', template.emailSubject);
        template.selected = true;
      }
    });
    component.set('v.availableTemplates', availableTemplates);
  },

  setCurrentEditSelection: function (component, event) {
    var source = event.getSource();
    var selection = {
      index: source.get('v.index')
    };

    component.set('v.currentEditSelection', selection);
  },

  addBlankRecipient: function (component, recipient) {
    var recipients = component.get('v.recipients');
    var newRecipient = {
      id: $A.util.isEmpty(recipient) ? null : recipient.id,
      role: {},
      name: $A.util.isEmpty(recipient) ? null : recipient.name,
      type: 'Signer',
      authentication: {},
      note: null,
      emailSettings: {}
    };
    if (recipient) {
      if (!$A.util.isEmpty(recipients[0]) && $A.util.isEmpty(recipients[0].id)) {
        recipients[0].id = recipient.id;
        recipients[0].name = recipient.name;
      } else {
        recipients.push(newRecipient);
      }
    } else {
      recipients.push(newRecipient);
    }
    component.set('v.recipients', recipients);
  },

  updateTemplates: function (component, event, helper, index) {
    var targetIndex = index;
    var templates = component.get('v.templates');
    var docuSignTemplates = component.get('v.availableTemplates');
    var selectedTemplate;

    availableTemplates.forEach(function (template) {
      if (templates[targetIndex].id.value === template.id.value) {
        template.selected = false;
        template.recipients.forEach(function (t) {
          recipient.id = null;
        });
      } else if (event.getSource().get('v.value') === template.id.value) {
        selectedTemplate = template;
      }
    });
    templates[targetIndex] = selectedTemplate;
    component.set('v.availableTemplates', availableTemplates);
    component.set('v.templates', templates);
  },

  removeTemplateRecipients: function (component, event, helper, templateIndex) {
    var targetIndex = $A.util.isEmpty(templateIndex) ? event.getSource().get('v.value') : templateIndex;
    var templates = component.get('v.templates');
    var currentRecipients = component.get('v.recipients');
    var updateRecipients = [];
    var tempalteIds = [];

    templates.forEach(function (template) {
      tempalteIds.push(template.id.value);
    });

    currentRecipients.forEach(function (recipient, index) {
      if (recipient.template) {
        if (tempalteIds.includes(recipient.template.id.value)) {
          updateRecipients.push(recipient);
        }
      } else {
        updateRecipients.push(recipient);
      }
    });

    component.set('v.recipients', updateRecipients);
  },

  getValidity: function (component) {
    switch (component.get('v.activeStep')) {
      case 0:
        return !!(component.get('v.filesSelected') || !$A.util.isEmpty(component.get('v.templates')));
      case 1:
        var templates = component.get('v.templates');
        if (!$A.util.isEmpty(templates)) {
          for (var i = 0; i < templates.length; i++) {
            if (!$A.util.isEmpty(templates[i].recipients)) {
              for (var n = 0; n < templates[i].recipients.length; n++) {
                if (!$A.util.isEmpty(templates[i].recipients[n].id)) {
                  return true;
                }
              }
            }
          }
        }

        if (component.get('v.filesSelected')) {
          var recipients = component.get('v.recipients');

          for (var i = 0; i < recipients.length; i++) {
            if (!$A.util.isEmpty(recipients[i].id)) {
              return true;
            }
          }
        }

        return false;
      case 2:
        return !$A.util.isEmpty(component.find('envelope-subject-input').get('v.value'));
    }
  },

  handleUploadFinished: function (component, event, helper) {
    var existingDocuments = component.get('v.documents');
    var getNewDocuments = component.get('c.getLinkedDocuments');
    getNewDocuments.setParams({
      sourceId: component.get('v.recordId')
    });
    getNewDocuments.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        var docs = response.getReturnValue();
        docs.forEach(function (doc) {
          var alreadyAttached = existingDocuments.filter(function (d) {
            return d.sourceId.match(doc.sourceId);
          });
          // if filter returns no match then this file doesn't already exist
          if ($A.util.isEmpty(alreadyAttached)) {
            doc = helper.addDocumentProperties(doc, true);
            existingDocuments.push(doc);
          }
        });
        component.set('v.documents', existingDocuments);
        helper.handleFilesChange(component, event, helper);
        component.set('v.filesSelected', true);
      } else {
        helper.setError(component, _getErrorMessage(response));
      }
    });
    $A.enqueueAction(getNewDocuments);
  },

  handleFilesChange: function (component, event, helper) {
    var defaultRecipients = component.get('v.selectedRecipients');
    var fileCheckboxes = helper.enforceArray(component.find('file-checkbox'));

    if (!component.get('v.filesSelected')) {
      defaultRecipients.forEach(function (recipient) {
        if (!$A.util.isEmpty(recipient)) {
          helper.addBlankRecipient(component, recipient);
        }
      });
    }

    for (var i = 0; i < fileCheckboxes.length; i++) {
      if (fileCheckboxes[i].get('v.checked')) {
        component.set('v.filesSelected', true);
        return;
      }
    }

    component.set('v.recipients', []);
    component.set('v.filesSelected', false);
  }
});
