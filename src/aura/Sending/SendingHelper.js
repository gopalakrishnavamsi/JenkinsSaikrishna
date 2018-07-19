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
        var result = response.getReturnValue();
        ;
        // Add front-end properties to documents
        if (!$A.util.isEmpty(result.documents)) {
          result.documents.forEach(function (d) {
            helper.addDocumentProperties(d, false);
          });
        }
        if (!$A.util.isEmpty(result.recipients)) {
          result.recipients.forEach(function (r) {
            r = helper.addRecipientProperties(r, false);
            r.role = {}; // TODO: Roles only apply to templates for now.
          });
        }
        if (!$A.util.isEmpty(result.templates)) {
          result.templates.forEach(function (template) {
            template.selected = false;
            if (!$A.util.isEmpty(template.recipients)) {
              template.recipients.forEach(helper.addRecipientProperties);
            }
          });
        }
        result.envelope.notifications = helper.setExpiration(result.envelope.notifications, result.envelope.notifications.expireAfterDays, result.envelope.notifications.expireWarnDays);
        component.set('v.expiresOn', helper.getExpirationDate(result.envelope.notifications.expireAfterDays));
        component.set('v.envelope', result.envelope);
        component.set('v.availableTemplates', result.templates);
        component.set('v.documents', result.documents);
        component.set('v.availableRecipients', result.recipients);
        component.set('v.defaultRoles', result.defaultRoles);
        component.set('v.emailLocalizations', result.emailLocalizations);
        component.set('v.isEmailLocalizationEnabled', !$A.util.isEmpty(result.emailLocalizations));
        component.set('v.loading', false);
      } else {
        helper.setError(component, _getErrorMessage(response));
      }
    });
    $A.enqueueAction(createDraftEnvelope);
  },

  setReminders: function (notifications, remindAfterDays, remindFrequencyDays) {
    if ($A.util.isEmpty(notifications)) {
      notifications = {};
    }

    notifications.remind = !$A.util.isUndefinedOrNull(remindAfterDays);
    notifications.remindAfterDays = $A.util.isUndefinedOrNull(remindAfterDays) ? null : parseInt(remindAfterDays, 10);
    notifications.remindFrequencyDays = $A.util.isUndefinedOrNull(remindFrequencyDays) ? null : parseInt(remindFrequencyDays, 10);

    return notifications;
  },

  // TODO: Validate expiry assumptions. Does NDSE force expiration after 120 days?
  setExpiration: function (notifications, expireAfterDays, expireWarnDays) {
    if ($A.util.isEmpty(notifications)) {
      notifications = {};
    }

    notifications.expires = true;
    notifications.expireAfterDays = $A.util.isUndefinedOrNull(expireAfterDays) ? 120 : parseInt(expireAfterDays, 10);
    notifications.expireWarnDays = $A.util.isUndefinedOrNull(expireWarnDays) ? null : parseInt(expireWarnDays, 10);

    return notifications;
  },

  getExpirationDate: function (expireAfterDays) {
    if ($A.util.isUndefinedOrNull(expireAfterDays)) {
      return null;
    }
    var expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + parseInt(expireAfterDays, 10));
    return expirationDate.toLocaleDateString();
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

  navigateToUrl: function (url) {
    var navEvt = $A.get('e.force:navigateToURL');
    if (!$A.util.isEmpty(navEvt)) {
      navEvt.setParams({
        'url': url
      });
      navEvt.fire();
    }
  },

  enforceArray: function (results) {
    return Array.isArray(results) ? results : [results];
  },

  resetNotificationSettings: function (notifications, helper) {
    return helper.setExpiration(helper.setReminders(notifications), 120);
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
        var envelope = component.get('v.envelope');
        if (template.notifications != null) {
          envelope.notifications = helper.setExpiration(helper.setReminders(envelope.notifications, template.notifications.remindAfterDays, template.notifications.remindFrequencyDays), template.notifications.expireAfterDays, template.notifications.expireWarnDays);
        } else {
          envelope.notifications = helper.resetNotificationSettings(envelope.notifications, helper);
        }
        envelope.emailSubject = template.emailSubject;
        envelope.emailMessage = template.emailMessage;
        component.set('v.envelope', envelope);
        template.selected = true;
      }
    });
    component.set('v.availableTemplates', availableTemplates);
  },

  addBlankRecipient: function (component, recipient) {
    var recipients = component.get('v.recipients');
    var isRecipientDefined = !$A.util.isEmpty(recipient);
    var newRecipient = {
      source: isRecipientDefined ? recipient.source : null,
      name: isRecipientDefined ? recipient.name : null,
      email: isRecipientDefined ? recipient.email : null,
      hostName: isRecipientDefined ? recipient.hostName : null,
      hostEmail: isRecipientDefined ? recipient.hostEmail : null,
      role: {},
      type: 'Signer',
      authentication: {},
      note: null,
      emailSettings: {}
    };
    if (isRecipientDefined) {
      if (!$A.util.isEmpty(recipients[0]) && $A.util.isEmpty(recipients[0].id)) {
        recipients[0].source = recipient.source;
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
    var availableTemplates = component.get('v.availableTemplates');
    var selectedTemplate;

    availableTemplates.forEach(function (template) {
      if (templates[targetIndex].id.value === template.id.value) {
        template.selected = false;
        template.recipients.forEach(function (tr) {
          tr.source = {};
        });
      } else if (event.getSource().get('v.value') === template.id.value) {
        selectedTemplate = template;
      }
    });
    templates[targetIndex] = selectedTemplate;
    component.set('v.availableTemplates', availableTemplates);
    component.set('v.templates', templates);
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
            var recipient = recipients[i];
            if (!$A.util.isEmpty(recipient.source) && !$A.util.isEmpty(recipient.source.id)) {
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
    var availableRecipients = component.get('v.availableRecipients');
    var fileCheckboxes = helper.enforceArray(component.find('file-checkbox'));

    if (!component.get('v.filesSelected')) {
      availableRecipients.forEach(function (recipient) {
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
  },

  getSelectedDocuments: function (templates, documents) {
    var sequence = 1;
    var docs = [];
    if (!$A.util.isEmpty(templates)) {
      templates.forEach(function (t) {
        if (!!t.selected) {
          docs.push({
            sequence: sequence++, type: 'Template', name: t.name, created: t.created, sourceId: t.id.value
          });
        }
      });
    }
    if (!$A.util.isEmpty(documents)) {
      documents.forEach(function (d) {
        if (!!d.selected) {
          docs.push({
            sequence: sequence++,
            type: d.type,
            name: d.name,
            extension: d.extension,
            size: d.size,
            created: d.created,
            sourceId: d.sourceId
          });
        }
      });
    }
    return docs;
  },

  getSelectedRecipients: function (recipients, defaultRoles) {
    var rs = [];

    if (!$A.util.isEmpty(recipients)) {
      recipients.forEach(function (r) {
        if ($A.util.isEmpty(r.role)) {
          r.role = $A.util.isEmpty(defaultRoles) ? {name: String((Math.random() * 100000) + 1)} : defaultRoles.shift();
        }
        rs.push(r);
      });
    }

    return rs;
  },

  tagEnvelope: function (component, helper, envelope) {
    var updateEnvelope = component.get('c.updateEnvelope');
    updateEnvelope.setParams({
      // HACK: Stringify-ing JSON to work around @AuraEnabled method limitations.
      envelopeJson: JSON.stringify(envelope)
    });
    updateEnvelope.setCallback(this, function (r1) {
      if (r1.getState() !== 'SUCCESS') {
        helper.setError(component, _getErrorMessage(r1));
      } else {
        var sendEnvelope = component.get('c.sendEnvelope');
        sendEnvelope.setParams({
          envelopeJson: JSON.stringify(r1.getReturnValue())
        });
        sendEnvelope.setCallback(this, function (r2) {
          if (r2.getState() !== 'SUCCESS') {
            helper.setError(component, _getErrorMessage(r2));
          } else {
            var getTaggerUrl = component.get('c.getTaggerUrl');
            getTaggerUrl.setParams({
              envelopeJson: JSON.stringify(r2.getReturnValue())
            });
            getTaggerUrl.setCallback(this, function (r3) {
              if (r3.getState() !== 'SUCCESS') {
                helper.setError(component, _getErrorMessage(r3));
              } else {
                helper.navigateToUrl(r3.getReturnValue());
              }
            });
            $A.enqueueAction(getTaggerUrl);
          }
        });
        $A.enqueueAction(sendEnvelope);
      }
    });
    $A.enqueueAction(updateEnvelope);
  }
});
