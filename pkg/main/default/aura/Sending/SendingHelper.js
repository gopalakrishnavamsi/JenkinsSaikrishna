({
  SEND_FOR_SIGNATURE: 'Send for Signature',

  createEnvelope: function (component, sourceId, sourceType) {
    this.timeEvent(component, this.SEND_FOR_SIGNATURE);
    this.addEventProperties(component, {
      'Product': 'eSignature',
      'Source Object': stringUtils.sanitizeObjectName(sourceType)
    });
    var self = this;
    if (component.get('v.isESignatureEnabled')) {
      var updated = false;
      var files = component.get('v.files');
      var loadDefaultContacts = component.get('v.loadDefaultContacts');
      var envelopeTemplateId = component.get('v.envelopeTemplateId');
      var fromEnvelopeTemplate = !$A.util.isEmpty(envelopeTemplateId);
      var action = fromEnvelopeTemplate ? component.get('c.createDraftEnvelopeFromTemplate') : component.get('c.createDraftEnvelope');
      var parameters = fromEnvelopeTemplate ? {
        envelopeConfigurationId: envelopeTemplateId,
        sourceId: sourceId
      } : {
        sourceId: sourceId,
        files: files,
        loadDefaultContacts: loadDefaultContacts
      };
      this.invokeAction(component, action, parameters,
        function (result) {
          // Add front-end properties to documents
          var documents = fromEnvelopeTemplate ? result.envelope.documents : result.documents;
          var recipients = fromEnvelopeTemplate ? result.envelope.recipients : result.recipients;
          if (!$A.util.isEmpty(documents)) {
            documents.forEach(function (d) {
              var isFileSelected = !$A.util.isEmpty(files) && (files.indexOf(d.sourceId) >= 0);
              self.addDocumentProperties(d, isFileSelected);
              if (isFileSelected) {
                updated = true;
              }
            });
          }

          documents.sort(function (a, b) {
            if (!a['selected'] && b['selected'])
              return 1;
            if (a['selected'] && !b['selected'])
              return -1;
            return a['selected'] - b['selected'];
          });

          if (!updated && !$A.util.isEmpty(documents) && !documents[0].isEmptyTemplate) {
            documents[0].selected = true;
            updated = true;
          }

          var placeholders = component.get('v.placeholderRecipients');
          if (!$A.util.isEmpty(placeholders) && !$A.util.isEmpty(placeholders.recipients)) {
            placeholders.recipients.forEach(function (r) {
              r.isPlaceHolder = true;
            });
            recipients = placeholders.recipients.concat(recipients || []);
          }
          var defaultRoles = result.defaultRoles.reduce(function (rolesMap, role) {
            rolesMap[role.name.toLowerCase()] = role;
            return rolesMap;
          }, {});
          result.envelope.notifications = $A.util.isUndefinedOrNull(result.envelope.notifications)
            ? {}
            : self.setExpiration(
              result.envelope.notifications,
              result.envelope.notifications.expireAfterDays,
              result.envelope.notifications.expireWarnDays);
          component.set(
            'v.expiresOn',
            self.getExpirationDate(result.envelope.notifications.expireAfterDays)
          );
          component.set('v.envelope', result.envelope);
          component.set('v.defaultEmailSubject', result.envelope.emailSubject);
          component.set('v.defaultEmailMessage', result.envelope.emailMessage);
          component.set('v.availableTemplates', result.templates);
          component.set('v.documents', documents);
          component.set('v.recipients', recipients);
          component.set('v.defaultRoles', defaultRoles);
          component.set('v.emailLocalizations', result.emailLocalizations);
          component.set(
            'v.isEmailLocalizationEnabled',
            !$A.util.isEmpty(result.emailLocalizations)
          );
          if (updated) {
            component.set('v.disableNext', false);
            /*
            self.handleFilesChange(component); // Uncomment this line for EXISTING sending experience
            */
          }

          // Renders LWC component for NEW sending experience
          self.beginSendForSignature(component); // Comment this line for EXISTING sending experience
        }
      );
    }
  },

  beginSendForSignature: function (component) {
    this.createComponent(
      'sendingExperience',
      component,
      'c:sendingConfig',
      {
        recordId: component.get('v.recordId'),
        envelope: component.get('v.envelope'),
        notifications: component.get('v.envelope').notifications,
        documents: component.get('v.documents'),
        recipients: component.get('v.recipients'),
        defaultRoles: component.get('v.defaultRoles'),
        files: component.get('v.files'),
        sendNow: component.get('v.sendNow'),
        forbidEnvelopeChanges: component.get('v.lock'),
        onsendcomplete: component.getReference('c.onSendComplete')
      });
  },

  endSendForSignature: function (component, status, properties) {
    switch (status) {
      case 'failure':
        this.trackError(component, this.SEND_FOR_SIGNATURE, properties, 'Failed to send for signature');
        break;

      case 'canceled':
        this.trackCancel(component, this.SEND_FOR_SIGNATURE, properties);
        break;

      default: // success
        this.trackSuccess(component, this.SEND_FOR_SIGNATURE, properties);
        break;
    }
  },

  addPlaceholderProperties: function (placeholder, routingOrder, defaultRoles) {
    var self = this;
    return {
      envelopeRecipientId: placeholder ? placeholder.envelopeRecipientId : null,
      type: 'Signer',
      routingOrder: routingOrder,
      role: placeholder ? self.resolveRole({name: placeholder.role, value: null}, defaultRoles) : null,
      name: null,
      email: null,
      signingGroup: null,
      phone: null,
      authentication: null,
      note: null,
      emailSettings: null,
      hostName: null,
      hostEmail: null,
      signNow: false,
      source: null
    };
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

  newRecipient: function (recipient, type) {
    // TODO: Override all properties with customizations
    var isDefined = !$A.util.isUndefinedOrNull(recipient);
    return {
      envelopeRecipientId: isDefined ? recipient.envelopeRecipientId : null,
      source: isDefined ? recipient.source : {},
      name: isDefined ? recipient.name : null,
      email: isDefined ? recipient.email : null,
      hostName: isDefined ? recipient.hostName : null,
      hostEmail: isDefined ? recipient.hostEmail : null,
      role: {},
      type: type,
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
        var recipients = component.get('v.recipients');
        return !$A.util.isEmpty(recipients) && !recipients.map(function (rt) {
          return rt.name;
        }).includes(null);
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
      var routingOrder = recipients.reduce(function (ro, r) {
        return r && r.routingOrder > ro ? r.routingOrder : ro;
      }, 0);

      recipients.forEach(function (r) {
        if (self.isValidRecipient(r) && (!$A.util.isEmpty(r.templateId) || hasDocuments)) {
          r.sequence = sequence++;
          if ($A.util.isEmpty(r.routingOrder)) r.routingOrder = ++routingOrder;
          r.role = self.isRoleDefined(r.role)
            ? r.role
            : self.getNextRole(defaultRoles);
          delete r.templateId;
          delete r.locked;
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
    var nextRole = $A.util.isEmpty(defaultRoles) ? null : defaultRoles[Object.keys(defaultRoles)[0]];

    if (!$A.util.isUndefinedOrNull(nextRole)) delete defaultRoles[Object.keys(defaultRoles)[0]];

    return nextRole;
  },

  tagEnvelope: function (component, envelope) {
    this.setLoading(component, true);
    var self = this;
    var sendNow = component.get('v.sendNow') === true;
    var eventParams = {
      'Using Template': !$A.util.isUndefinedOrNull(component.get('v.template')),
      'Documents': envelope.documents.length,
      'Recipients': envelope.recipients.length
    };
    var error = '';
    var sendEnvelope = component.get('c.sendEnvelope');
    sendEnvelope.setParams({
      // HACK: Stringify-ing JSON to work around @AuraEnabled method limitations.
      envelopeJson: JSON.stringify(envelope),
      sendNow: sendNow,
      updateNow: true
    });
    sendEnvelope.setCallback(self, function (response1) {
      if (response1.getState() === 'SUCCESS') {
        if (sendNow) {
          self.deleteDocument(component);
          self.trackSuccess(component, self.SEND_FOR_SIGNATURE, eventParams);
          navUtils.navigateToSObject(component.get('v.recordId'));
        } else {
          var getTaggerUrl = component.get('c.getTaggerUrl');
          getTaggerUrl.setParams({
            envelopeJson: JSON.stringify(response1.getReturnValue())
          });
          getTaggerUrl.setCallback(self, function (response2) {
            if (response1.getState() === 'SUCCESS') {
              self.trackSuccess(component, self.SEND_FOR_SIGNATURE, eventParams);
              navUtils.navigateToUrl(response2.getReturnValue());
            } else {
              error = self.getErrorMessage(response2);
              self.trackError(component, self.SEND_FOR_SIGNATURE, eventParams, 'Get tagger URL error');
              self.showToast(component, error, 'error');
            }
          });
          $A.enqueueAction(getTaggerUrl);
        }
      } else {
        error = self.getErrorMessage(response1);
        self.trackError(component, self.SEND_FOR_SIGNATURE, eventParams, 'Create envelope error');
        self.showToast(component, error, 'error');
      }
    });
    $A.enqueueAction(sendEnvelope);
  },

  valueOrElse: function (value, orElse) {
    return $A.util.isEmpty(value) ? orElse : value;
  },

  mergePlaceholderRecipient: function (placeholder, recipient, sequence, defaultRoles) {
    var self = this;
    if ($A.util.isUndefinedOrNull(placeholder)) {
      recipient.role = self.resolveRole(recipient.role, defaultRoles);
      return recipient;
    }

    return {
      original: recipient,
      envelopeRecipientId: placeholder.envelopeRecipientId,
      type: recipient.type,
      routingOrder: sequence,
      role: self.resolveRole({
        name: placeholder.role,
        value: null
      }, defaultRoles),
      name: recipient.name,
      email: recipient.email,
      signingGroup: recipient.signingGroup,
      phone: recipient.phone,
      authentication: recipient.authentication,
      note: recipient.note,
      emailSettings: recipient.emailSettings,
      hostName: recipient.hostName,
      hostEmail: recipient.hostEmail,
      signNow: recipient.signNow,
      source: recipient.source
    };
  },

  resolveRole: function (role, defaultRoles) {
    if (!$A.util.isEmpty(role)
      && !$A.util.isUndefinedOrNull(role.name)
      && !$A.util.isUndefinedOrNull(defaultRoles[role.name.toLowerCase()])
    ) {
      delete defaultRoles[role.name.toLowerCase()];
    }
    return role;
  },

  mergeTemplateRecipient: function (templateRecipient, recipient, defaultRoles) {
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
    var self = this;
    return {
      templateId: templateRecipient.templateId,
      locked: false,
      original: recipient,
      envelopeRecipientId: recipient.envelopeRecipientId,
      type: templateRecipient.type,
      routingOrder: templateRecipient.routingOrder,
      role: self.resolveRole(templateRecipient.role, defaultRoles),
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

  getRecipients: function (recipients, placeholders, template, defaultRoles) {
    var self = this;
    var rs = [];
    var ri = 0;
    var usingTemplate = false;

    if (!$A.util.isEmpty(placeholders) && !$A.util.isEmpty(placeholders.recipients)) {
      usingTemplate = true;
      placeholders.recipients.forEach(function (ph) {
        if (!$A.util.isEmpty(recipients) && ri < recipients.length) {
          //#StartHere
          var currentRecipient = recipients[ri++];
          rs.push(self.mergePlaceholderRecipient(ph, currentRecipient, ri, defaultRoles));
        } else {
          rs.push(self.addPlaceholderProperties(ph, ++ri, defaultRoles));
        }
      });
    }

    if (!$A.util.isUndefinedOrNull(template) && !$A.util.isEmpty(template.recipients)) {
      // Add or merge template recipients
      usingTemplate = true;
      template.recipients.forEach(function (tr) {
        if (ri < recipients.length && !self.isValidRecipient(tr)) {
          rs.push(self.mergeTemplateRecipient(tr, recipients[ri++], defaultRoles));
        } else {
          tr.role = self.resolveRole(tr.role, defaultRoles);
          tr.locked = true;
          rs.push(tr);
        }
      });
    }

    if (!usingTemplate && !$A.util.isEmpty(recipients)) {
      for (var i = ri; i < recipients.length; i++) {
        rs.push(recipients[i]);
      }
    }

    return rs;
  },

  resetRecipients: function (recipients) {
    return $A.util.isEmpty(recipients) ? [] : recipients.map(function (r) {
      return $A.util.isUndefinedOrNull(r.original) ? r : r.original;
    });
  },

  resolveRecipient: function (component, recipient) {
    var self = this;
    var sourceId = self.getSourceId(recipient);
    if (!$A.util.isUndefinedOrNull(sourceId)) {
      if (recipient.source.deleted) {
        self.removeRecipientName(component, sourceId);
      } else {
        self.addRecipientName(component, sourceId);
      }
    }
  },

  removeRecipientName: function (component, sourceId) {
    var self = this;
    var recipients = component.get('v.recipients');
    recipients.forEach(function (rt) {
      if (self.getSourceId(rt) === sourceId) {
        rt.name = null;
      }
    });
    component.set('v.recipients', recipients);
  },

  addRecipientName: function (component, sourceId) {
    var self = this;
    var action = component.get('c.resolveRecipient');
    var parameters = {
      sourceId: sourceId
    };
    self.invokeAction(component, action, parameters, function (recipientData) {
        self.updateNewRecipient(component, sourceId, recipientData);
      }
    );
  },

  updateNewRecipient: function (component, sourceId, recipientData) {
    var self = this;
    var rs = component.get('v.recipients');
    rs.forEach(function (r) {
      // Update name, email, phone, full source for new recipient
      if (self.getSourceId(r) === sourceId) {
        r.name = recipientData.name;
        r.email = recipientData.email;
        r.phone = recipientData.phone;
        r.source = recipientData.source;
      }
    });
    component.set('v.recipients', rs);
  },

  cancelSend: function (component) {
    this.trackCancel(component, this.SEND_FOR_SIGNATURE);
    var isOnlineEditor = component.get('v.lock') === true && component.get('v.sendNow') === true;
    if (isOnlineEditor) {
      this.deleteDocument(component);
    }
    navUtils.navigateToSObject(component.get('v.recordId'));
  },

  deleteDocument: function (component) {
    var files = component.get('v.files');
    if (!$A.util.isEmpty(files)) {
      this.invokeAction(component, component.get('c.deleteDocument'),
        {
          scmFile: files[0]
        }
      );
    }
  }
});
