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
            r = helper.addRecipientProperties(r);
            r.role = {}; // TODO: Roles only apply to templates for now.
          });
        }
        if (!$A.util.isEmpty(result.templates)) {
          result.templates.forEach(function (template) {
            template.selected = false;
            if (!$A.util.isEmpty(template.recipients)) {
              template.recipients.forEach(function (r) {
                helper.addRecipientProperties(r);
                r.templateId = template.id.value;
              });
            }
          });
        }
        result.envelope.notifications = helper.setExpiration(result.envelope.notifications, result.envelope.notifications.expireAfterDays, result.envelope.notifications.expireWarnDays);
        component.set('v.expiresOn', helper.getExpirationDate(result.envelope.notifications.expireAfterDays));
        component.set('v.envelope', result.envelope);
        component.set('v.defaultEmailSubject', result.envelope.emailSubject);
        component.set('v.defaultEmailMessage', result.envelope.emailMessage);
        component.set('v.availableTemplates', result.templates);
        component.set('v.documents', result.documents);
        component.set('v.recipients', result.recipients);
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
    if (!!doc) {
      doc.selected = !!selected;
      doc.formattedSize = !!doc.size ? _formatSize(doc.size) : '';
      doc.formattedLastModified = !!doc.lastModified ? new Date(doc.lastModified).toLocaleString() : '';
    }
    return doc;
  },

  addRecipientProperties: function (recipient) {
    if (recipient) {
      recipient.templateId = null;
      if ($A.util.isUndefinedOrNull(recipient.emailSettings)) {
        recipient.emailSettings = {};
      }
      if ($A.util.isUndefinedOrNull(recipient.authentication)) {
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

  updateTemplate: function (component, helper, templateId) {
    var availableTemplates = component.get('v.availableTemplates');

    availableTemplates.forEach(function (t) {
      if (t.id.value === templateId) {
        var envelope = component.get('v.envelope');
        if (t.notifications != null) {
          envelope.notifications = helper.setExpiration(helper.setReminders(envelope.notifications, t.notifications.remindAfterDays, t.notifications.remindFrequencyDays), t.notifications.expireAfterDays, t.notifications.expireWarnDays);
        } else {
          envelope.notifications = helper.resetNotificationSettings(envelope.notifications, helper);
        }
        t.emailSubject = $A.util.isEmpty(t.emailSubject) ? envelope.emailSubject : t.emailSubject;
        t.emailMessage = $A.util.isEmpty(t.emailMessage) ? envelope.emailMessage : t.emailMessage;
        component.set('v.envelope', envelope);
        t.selected = true;
        component.set('v.template', t);
      } else {
        t.selected = false;
        t.recipients.forEach(function (tr) {
          tr.source = {};
        });
      }
    });
    if ($A.util.isUndefinedOrNull(templateId)) {
      component.set('v.template', null);
    }
    component.set('v.availableTemplates', availableTemplates);
  },

  newRecipient: function (recipient) {
    // TODO: Override all properties with customizations
    var isDefined = !$A.util.isUndefinedOrNull(recipient);
    return {
      source: isDefined ? recipient.source : {},
      name: isDefined ? recipient.name : null,
      email: isDefined ? recipient.email : null,
      hostName: isDefined ? recipient.hostName : null,
      hostEmail: isDefined ? recipient.hostEmail : null,
      role: {},
      type: 'Signer',
      authentication: {},
      note: null,
      emailSettings: {}
    };
  },

  getSourceId: function (x) {
    if ($A.util.isUndefinedOrNull(x)) return null;

    var sourceId = null;
    if (!$A.util.isEmpty(x.sourceId)) {
      sourceId = x.sourceId;
    } else if (!$A.util.isUndefinedOrNull(x.source) && !$A.util.isEmpty(x.source.id)) {
      sourceId = x.source.id;
    }
    return sourceId;
  },

  getValidity: function (component, helper) {
    switch (component.get('v.activeStep')) {
      case 0:
        return !!(component.get('v.filesSelected') || !$A.util.isUndefinedOrNull(component.get('v.template')));
      case 1:
        return !$A.util.isEmpty(component.get('v.recipients'));
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
    var fileCheckboxes = helper.enforceArray(component.find('file-checkbox'));

    for (var i = 0; i < fileCheckboxes.length; i++) {
      if (fileCheckboxes[i].get('v.checked')) {
        component.set('v.filesSelected', true);
        return;
      }
    }

    component.set('v.filesSelected', false);
  },

  getDocumentsForSending: function (documents, template) {
    var sequence = 1;
    var docs = [];
    if (!$A.util.isEmpty(documents)) {
      documents.forEach(function (d) {
        if (!!d.selected) {
          docs.push({
            sequence: sequence++,
            type: d.type,
            name: d.name,
            extension: d.extension,
            size: d.size,
            lastModified: d.lastModified,
            sourceId: d.sourceId
          });
        }
      });
    }
    if (!$A.util.isUndefinedOrNull(template)) {
      docs.push({
        sequence: sequence++,
        type: 'Template',
        name: template.name,
        extension: null,
        size: null,
        lastModified: template.lastModified,
        sourceId: template.id.value
      });
    }
    return docs;
  },

  getRecipientsForSending: function (helper, recipients, hasDocuments, defaultRoles) {
    var rs = [];
    var sequence = 1;
    if (!$A.util.isEmpty(recipients)) {
      recipients.forEach(function (r) {
        if (helper.isValidRecipient(r) && (!$A.util.isEmpty(r.templateId) || hasDocuments)) {
          r.sequence = sequence++;
          r.role = helper.isRoleDefined(r.role) ? r.role : helper.getNextRole(defaultRoles);
          delete r.templateId;
          delete r.original;
          rs.push(r);
        }
      });
    }
    return rs;
  },

  isRoleDefined: function (role) {
    return !$A.util.isUndefinedOrNull(role) && !$A.util.isEmpty(role.name);
  },

  getNextRole: function (defaultRoles) {
    return $A.util.isEmpty(defaultRoles) ? null : defaultRoles.shift();
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
  },

  valueOrElse: function (value, orElse) {
    return $A.util.isEmpty(value) ? orElse : value;
  },

  mergeTemplateRecipient: function (helper, templateRecipient, recipient) {
    if ($A.util.isUndefinedOrNull(templateRecipient)) return recipient;
    if ($A.util.isUndefinedOrNull(recipient)) return templateRecipient;

    if ($A.util.isUndefinedOrNull(templateRecipient.authentication)) templateRecipient.authentication = {};
    if ($A.util.isUndefinedOrNull(recipient.authentication)) recipient.authentication = {};
    if ($A.util.isUndefinedOrNull(templateRecipient.emailSettings)) templateRecipient.emailSettings = {};
    if ($A.util.isUndefinedOrNull(recipient.emailSettings)) recipient.emailSettings = {};

    return {
      templateId: templateRecipient.templateId,
      original: recipient,
      type: templateRecipient.type,
      routingOrder: templateRecipient.routingOrder,
      role: templateRecipient.role,
      name: helper.valueOrElse(templateRecipient.name, recipient.name),
      email: helper.valueOrElse(templateRecipient.email, recipient.email),
      signingGroup: helper.valueOrElse(templateRecipient.signingGroup, recipient.signingGroup),
      phone: recipient.phone,
      authentication: {
        accessCode: helper.valueOrElse(templateRecipient.authentication.accessCode, recipient.authentication.accessCode),
        idCheckRequired: helper.valueOrElse(templateRecipient.authentication.idCheckRequired, recipient.authentication.idCheckRequired),
        smsPhoneNumbers: helper.valueOrElse(templateRecipient.authentication.smsPhoneNumbers, recipient.authentication.smsPhoneNumbers)
      },
      note: helper.valueOrElse(templateRecipient.note, recipient.note),
      emailSettings: {
        language: helper.valueOrElse(templateRecipient.emailSettings.language, recipient.emailSettings.language),
        languageLabel: helper.valueOrElse(templateRecipient.emailSettings.languageLabel, recipient.emailSettings.languageLabel),
        subject: helper.valueOrElse(templateRecipient.emailSettings.subject, recipient.emailSettings.subject),
        message: helper.valueOrElse(templateRecipient.emailSettings.message, recipient.emailSettings.message)
      },
      hostName: helper.valueOrElse(templateRecipient.hostName, recipient.hostName),
      hostEmail: helper.valueOrElse(templateRecipient.hostEmail, recipient.hostEmail),
      signNow: helper.valueOrElse(templateRecipient.signNow, recipient.signNow),
      source: recipient.source
    };
  },

  isValidRecipient: function (recipient) {
    return !$A.util.isUndefinedOrNull(recipient) && ((!$A.util.isEmpty(recipient.name) && !$A.util.isEmpty(recipient.email)) || (!$A.util.isUndefinedOrNull(recipient.signingGroup) && !$A.util.isEmpty(recipient.signingGroup.name))) && ($A.util.isEmpty(recipient.templateId) || (!$A.util.isUndefinedOrNull(recipient.role) && !$A.util.isEmpty(recipient.role.name)));
  },

  resetRecipients: function (helper, recipients) {
    var rs = [];
    if (!$A.util.isEmpty(recipients)) {
      recipients.forEach(function (r) {
        if ($A.util.isEmpty(r.templateId)) {
          rs.push(r);
        } else if (!$A.util.isUndefinedOrNull(r.original)) {
          r = r.original;
          rs.push(r);
        }
      });
    }
    return rs;
  },

  getRecipients: function (helper, recipients, template) {
    var rs = [];
    var ri = 0;
    if (!$A.util.isEmpty(recipients)) {
      if (!$A.util.isUndefinedOrNull(template) && !$A.util.isEmpty(template.recipients)) {
        // Add or merge template recipients
        template.recipients.forEach(function (tr) {
          if (ri < recipients.length && !helper.isValidRecipient(tr)) {
            rs.push(helper.mergeTemplateRecipient(helper, tr, recipients[ri++]));
          } else {
            rs.push(tr);
          }
        });
      }

      // Add any leftover recipients
      for (var i = ri; i < recipients.length; i++) {
        rs.push(recipients[i]);
      }
    }
    return rs;
  },

  resolveRecipient: function (component, helper, recipient) {
    if ($A.util.isUndefinedOrNull(recipient) || helper.isValidRecipient(recipient)) return;

    var sourceId = helper.getSourceId(recipient);
    if ($A.util.isEmpty(sourceId)) return;

    var rr = component.get('c.resolveRecipient');
    rr.setParams({
      sourceId: sourceId
    });
    rr.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var result = response.getReturnValue();
        if (!$A.util.isUndefinedOrNull(result)) {
          var updated = false;
          var rs = component.get('v.recipients');
          rs.forEach(function (r) {
            // Update email, phone, full source for new recipient
            if (helper.getSourceId(r) === sourceId) {
              r.email = result.email;
              r.phone = result.phone;
              r.source = result.source;
              updated = true;
            }
          });
          // Prevent rebinding if nothing has changed.
          if (updated) {
            component.set('v.recipients', rs);
            component.set('v.disableNext', false);
          }
        }
      } else {
        helper.setError(component, _getErrorMessage(response));
      }
    });
    $A.enqueueAction(rr);
  }
});
