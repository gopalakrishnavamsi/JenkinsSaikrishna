({
  createEnvelope: function (component, sourceId) {
    var self = this;
    var selectedDocumentIds = decodeURIComponent(component.get('v.files')).split(',');
    var updated = false;
    this.invokeAction(
      component,
      component.get('c.createDraftEnvelope'),
      {
        sourceId: sourceId
      },
      function (result) {
        // Add front-end properties to documents
        if (!$A.util.isEmpty(result.documents)) {
          result.documents.forEach(function (d) {
            var isFileSelected = selectedDocumentIds.indexOf(d.sourceId) >= 0;
            self.addDocumentProperties(d, isFileSelected);
            if (isFileSelected) {
              updated = true;
            }
          });
        }

        result.documents.sort(function (a, b) {
          if (!a['selected'] && b['selected'])
            return 1;
          if (a['selected'] && !b['selected'])
            return -1;
          return a['selected'] - b['selected'];
        });

        if (!updated && !$A.util.isEmpty(result.documents)) {
          result.documents[0].selected = true;
          updated = true;
        }

        if (!$A.util.isEmpty(result.recipients)) {
          result.recipients.forEach(function (r) {
            r = self.addRecipientProperties(r);
            r.role = {}; // TODO: Roles only apply to templates for now.
          });
        }
        if (!$A.util.isEmpty(result.templates)) {
          result.templates.forEach(function (template) {
            template.selected = false;
            if (!$A.util.isEmpty(template.recipients)) {
              template.recipients.forEach(function (r) {
                self.addRecipientProperties(r);
                r.templateId = template.id.value;
              });
            }
          });
        }
        result.envelope.notifications = self.setExpiration(
          result.envelope.notifications,
          result.envelope.notifications.expireAfterDays,
          result.envelope.notifications.expireWarnDays
        );
        component.set(
          'v.expiresOn',
          self.getExpirationDate(result.envelope.notifications.expireAfterDays)
        );
        component.set('v.envelope', result.envelope);
        component.set('v.defaultEmailSubject', result.envelope.emailSubject);
        component.set('v.defaultEmailMessage', result.envelope.emailMessage);
        component.set('v.availableTemplates', result.templates);
        component.set('v.documents', result.documents);
        component.set('v.recipients', result.recipients);
        component.set('v.defaultRoles', result.defaultRoles);
        component.set('v.emailLocalizations', result.emailLocalizations);
        component.set(
          'v.isEmailLocalizationEnabled',
          !$A.util.isEmpty(result.emailLocalizations)
        );
        if (updated) {
          component.set('v.disableNext', false);
          self.handleFilesChange(component);
        }
      }
    );
  },

  setReminders: function (notifications, remindAfterDays, remindFrequencyDays) {
    if ($A.util.isEmpty(notifications)) {
      notifications = {};
    }

    notifications.remind = !$A.util.isUndefinedOrNull(remindAfterDays);
    notifications.remindAfterDays = $A.util.isUndefinedOrNull(remindAfterDays)
      ? null
      : parseInt(remindAfterDays, 10);
    notifications.remindFrequencyDays = $A.util.isUndefinedOrNull(
      remindFrequencyDays
    )
      ? null
      : parseInt(remindFrequencyDays, 10);

    return notifications;
  },

  // TODO: Validate expiry assumptions. Does NDSE force expiration after 120 days?
  setExpiration: function (notifications, expireAfterDays, expireWarnDays) {
    if ($A.util.isEmpty(notifications)) {
      notifications = {};
    }

    notifications.expires = true;
    notifications.expireAfterDays = $A.util.isUndefinedOrNull(expireAfterDays)
      ? 120
      : parseInt(expireAfterDays, 10);
    notifications.expireWarnDays = $A.util.isUndefinedOrNull(expireWarnDays)
      ? null
      : parseInt(expireWarnDays, 10);

    return notifications;
  },

  getExpirationDate: function (expireAfterDays) {
    if ($A.util.isUndefinedOrNull(expireAfterDays)) {
      return null;
    }
    var expirationDate = new Date();
    expirationDate.setDate(
      expirationDate.getDate() + parseInt(expireAfterDays, 10)
    );
    return expirationDate.toLocaleDateString();
  },

  addDocumentProperties: function (doc, selected) {
    if (doc) {
      doc.selected = selected === true;
      doc.formattedSize = doc.size ? stringUtils.formatSize(doc.size) : '';
      doc.formattedLastModified = doc.lastModified
        ? new Date(doc.lastModified).toLocaleString()
        : '';
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

  enforceArray: function (results) {
    return Array.isArray(results) ? results : [results];
  },

  resetNotificationSettings: function (notifications) {
    return this.setExpiration(this.setReminders(notifications), 120);
  },

  updateTemplate: function (component, templateId) {
    var self = this;
    var availableTemplates = component.get('v.availableTemplates');

    availableTemplates.forEach(function (t) {
      if (t.id.value === templateId) {
        var envelope = component.get('v.envelope');
        if (t.notifications !== null) {
          envelope.notifications = self.setExpiration(
            self.setReminders(
              envelope.notifications,
              t.notifications.remindAfterDays,
              t.notifications.remindFrequencyDays
            ),
            t.notifications.expireAfterDays,
            t.notifications.expireWarnDays
          );
        } else {
          envelope.notifications = self.resetNotificationSettings(
            envelope.notifications
          );
        }
        t.emailSubject = $A.util.isEmpty(t.emailSubject)
          ? envelope.emailSubject
          : t.emailSubject;
        t.emailMessage = $A.util.isEmpty(t.emailMessage)
          ? envelope.emailMessage
          : t.emailMessage;
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
    } else if (
      !$A.util.isUndefinedOrNull(x.source) &&
      !$A.util.isEmpty(x.source.id)
    ) {
      sourceId = x.source.id;
    }
    return sourceId;
  },

  getValidity: function (component) {
    switch (component.get('v.activeStep')) {
      case 0:
        return !!(
          component.get('v.filesSelected') ||
          !$A.util.isUndefinedOrNull(component.get('v.template'))
        );
      case 1:
        return !$A.util.isEmpty(component.get('v.recipients'));
      case 2:
        return !$A.util.isEmpty(
          component.find('envelope-subject-input').get('v.value')
        );
    }
  },

  handleUploadFinished: function (component) {
    var self = this;
    this.invokeAction(
      component,
      component.get('c.getLinkedDocuments'),
      {
        sourceId: component.get('v.recordId')
      },
      function (docs) {
        var existingDocuments = component.get('v.documents');
        docs.forEach(function (doc) {
          var alreadyAttached = existingDocuments.filter(function (d) {
            return d.sourceId.match(doc.sourceId);
          });
          // if filter returns no match then this file doesn't already exist
          if ($A.util.isEmpty(alreadyAttached)) {
            doc = self.addDocumentProperties(doc, true);
            existingDocuments.push(doc);
          }
        });
        component.set('v.documents', existingDocuments);
        self.handleFilesChange(component);
        component.set('v.filesSelected', true);
      }
    );
  },

  handleFilesChange: function (component) {
    var fileCheckboxes = this.enforceArray(component.find('file-checkbox'));

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
        if (d.selected) {
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

  getRecipientsForSending: function (recipients, hasDocuments, defaultRoles) {
    var self = this;
    var rs = [];
    var sequence = 1;
    if (!$A.util.isEmpty(recipients)) {
      recipients.forEach(function (r) {
        if (
          self.isValidRecipient(r) &&
          (!$A.util.isEmpty(r.templateId) || hasDocuments)
        ) {
          r.routingOrder = r.sequence = sequence++;
          r.role = self.isRoleDefined(r.role)
            ? r.role
            : self.getNextRole(defaultRoles);
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

  tagEnvelope: function (component, envelope) {
    this.setLoading(component, true);
    var self = this;
    var sendEnvelope = component.get('c.sendEnvelope');
    sendEnvelope.setParams({
      // HACK: Stringify-ing JSON to work around @AuraEnabled method limitations.
      envelopeJson: JSON.stringify(envelope)
    });
    sendEnvelope.setCallback(self, function (response1) {
      if (response1.getState() === 'SUCCESS') {
        var getTaggerUrl = component.get('c.getTaggerUrl');
        getTaggerUrl.setParams({
          envelopeJson: JSON.stringify(response1.getReturnValue())
        });
        getTaggerUrl.setCallback(self, function (response2) {
          if (response1.getState() === 'SUCCESS') {
            navUtils.navigateToUrl(response2.getReturnValue());
          } else {
            self.showToast(component, self.getErrorMessage(response2), 'error');
          }
        });
        $A.enqueueAction(getTaggerUrl);
      } else {
        self.showToast(component, self.getErrorMessage(response1), 'error');
      }
    });
    $A.enqueueAction(sendEnvelope);
  },

  valueOrElse: function (value, orElse) {
    return $A.util.isEmpty(value) ? orElse : value;
  },

  mergeTemplateRecipient: function (templateRecipient, recipient) {
    if ($A.util.isUndefinedOrNull(templateRecipient)) return recipient;
    if ($A.util.isUndefinedOrNull(recipient)) return templateRecipient;

    if ($A.util.isUndefinedOrNull(templateRecipient.authentication))
      templateRecipient.authentication = {};
    if ($A.util.isUndefinedOrNull(recipient.authentication))
      recipient.authentication = {};
    if ($A.util.isUndefinedOrNull(templateRecipient.emailSettings))
      templateRecipient.emailSettings = {};
    if ($A.util.isUndefinedOrNull(recipient.emailSettings))
      recipient.emailSettings = {};

    return {
      templateId: templateRecipient.templateId,
      original: recipient,
      type: templateRecipient.type,
      routingOrder: templateRecipient.routingOrder,
      role: templateRecipient.role,
      name: this.valueOrElse(templateRecipient.name, recipient.name),
      email: this.valueOrElse(templateRecipient.email, recipient.email),
      signingGroup: this.valueOrElse(
        templateRecipient.signingGroup,
        recipient.signingGroup
      ),
      phone: recipient.phone,
      authentication: {
        accessCode: this.valueOrElse(
          templateRecipient.authentication.accessCode,
          recipient.authentication.accessCode
        ),
        idCheckRequired: this.valueOrElse(
          templateRecipient.authentication.idCheckRequired,
          recipient.authentication.idCheckRequired
        ),
        smsPhoneNumbers: this.valueOrElse(
          templateRecipient.authentication.smsPhoneNumbers,
          recipient.authentication.smsPhoneNumbers
        )
      },
      note: this.valueOrElse(templateRecipient.note, recipient.note),
      emailSettings: {
        language: this.valueOrElse(
          templateRecipient.emailSettings.language,
          recipient.emailSettings.language
        ),
        languageLabel: this.valueOrElse(
          templateRecipient.emailSettings.languageLabel,
          recipient.emailSettings.languageLabel
        ),
        subject: this.valueOrElse(
          templateRecipient.emailSettings.subject,
          recipient.emailSettings.subject
        ),
        message: this.valueOrElse(
          templateRecipient.emailSettings.message,
          recipient.emailSettings.message
        )
      },
      hostName: this.valueOrElse(
        templateRecipient.hostName,
        recipient.hostName
      ),
      hostEmail: this.valueOrElse(
        templateRecipient.hostEmail,
        recipient.hostEmail
      ),
      signNow: this.valueOrElse(templateRecipient.signNow, recipient.signNow),
      source: recipient.source
    };
  },

  isValidRecipient: function (recipient) {
    return (
      !$A.util.isUndefinedOrNull(recipient) &&
      ((!$A.util.isEmpty(recipient.name) &&
        !$A.util.isEmpty(recipient.email)) ||
        (!$A.util.isUndefinedOrNull(recipient.signingGroup) &&
          !$A.util.isEmpty(recipient.signingGroup.name))) &&
      ($A.util.isEmpty(recipient.templateId) ||
        (!$A.util.isUndefinedOrNull(recipient.role) &&
          !$A.util.isEmpty(recipient.role.name)))
    );
  },

  resetRecipients: function (recipients) {
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

  getRecipients: function (recipients, template) {
    var self = this;
    var rs = [];
    var ri = 0;
    if (!$A.util.isEmpty(recipients)) {
      if (
        !$A.util.isUndefinedOrNull(template) &&
        !$A.util.isEmpty(template.recipients)
      ) {
        // Add or merge template recipients
        template.recipients.forEach(function (tr) {
          if (ri < recipients.length && !self.isValidRecipient(tr)) {
            rs.push(self.mergeTemplateRecipient(tr, recipients[ri++]));
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

  resolveRecipient: function (component, recipient) {
    var self = this;
    var sourceId = self.getSourceId(recipient);
    this.invokeAction(
      component,
      component.get('c.resolveRecipient'),
      {
        sourceId: sourceId
      },
      function (result) {
        if (!$A.util.isUndefinedOrNull(result)) {
          var updated = false;
          var rs = component.get('v.recipients');
          rs.forEach(function (r) {
            // Update name, email, phone, full source for new recipient
            if (self.getSourceId(r) === sourceId) {
              r.name = result.name;
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
      }
    );
  }
});
