({
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

  formatSize: function (bytes, decimals) {
    if (bytes === 0) {
      return '0 Bytes';
    }

    var constant = 1024;
    var decimals = decimals || 2;
    var exponents = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var factor = Math.floor(Math.log(bytes) / Math.log(constant));

    return parseFloat((bytes / Math.pow(constant, factor)).toFixed(decimals)) + ' ' + exponents[factor];
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
    var docuSignTemplates = component.get('v.docuSignTemplates');

    docuSignTemplates.forEach(function (template, index) {
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
    component.set('v.docuSignTemplates', docuSignTemplates);
  },

  setCurrentEditSelection: function (component, event) {
    var source = event.getSource();
    var selection = {
      index: source.get('v.index')
    };

    component.set('v.currentEditSelection', selection);
  },

  addBlankRecipient: function (component, recipient) {
    var recipientSettings = component.get('v.recipientSettings');

    var newRecipient = {
      id: $A.util.isEmpty(recipient) ? null : recipient.id,
      role: {},
      name: $A.util.isEmpty(recipient) ? null : recipient.name,
      recipientType: 'Signer',
      authentication: {},
      note: null,
      emailSettings: {}
    };

    if (recipient) {
      if (!$A.util.isEmpty(recipientSettings[0]) && $A.util.isEmpty(recipientSettings[0].id)) {
        recipientSettings[0].id = recipient.id;
        recipientSettings[0].name = recipient.name;
      } else {
        recipientSettings.push(newRecipient);
      }
    } else {
      recipientSettings.push(newRecipient);
    }
    component.set('v.recipientSettings', recipientSettings);
  },

  updateTemplates: function (component, event, helper, index) {
    var targetIndex = index;
    var templates = component.get('v.templates');
    var docuSignTemplates = component.get('v.docuSignTemplates');
    var selectedTemplate;

    docuSignTemplates.forEach(function (docuSignTemplate) {
      if (templates[targetIndex].id.value === docuSignTemplate.id.value) {
        docuSignTemplate.selected = false;
        docuSignTemplate.recipients.forEach(function (recipient) {
          recipient.id = null;
        });
      } else if (event.getSource().get('v.value') === docuSignTemplate.id.value) {
        selectedTemplate = docuSignTemplate;
      }
    });
    templates[targetIndex] = selectedTemplate;
    component.set('v.docuSignTemplates', docuSignTemplates);
    component.set('v.templates', templates);
  }, removeTemplateRecipients: function (component, event, helper, templateIndex) {
    var targetIndex = $A.util.isEmpty(templateIndex) ? event.getSource().get('v.value') : templateIndex;
    var templates = component.get('v.templates');
    var currentRecipients = component.get('v.recipientSettings');
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

    component.set('v.recipientSettings', updateRecipients);
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
          var recipientSettings = component.get('v.recipientSettings');

          for (var i = 0; i < recipientSettings.length; i++) {
            if (!$A.util.isEmpty(recipientSettings[i].id)) {
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
    var getNewDocuments = component.get('c.getRelatedDocuments');
    getNewDocuments.setParams({
      recordId: component.get('v.recordId')
    });

    getNewDocuments.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        var errMsg = JSON.parse(response.getReturnValue()).errMsg;
        if ($A.util.isEmpty(errMsg)) {
          var documents = JSON.parse(response.getReturnValue()).results.documents;
          documents.forEach(function (document) {
            var alreadyAttached = existingDocuments.filter(function (doc) {
              return doc.Id.match(document.Id);
            });

            //if filter returns no match then this file doesnt already exist
            if ($A.util.isEmpty(alreadyAttached)) {
              document.checked = true;
              document.CreatedDate = new Date(document.CreatedDate).toLocaleString().replace(/,/g, '');
              document.ContentSize = helper.formatSize(document.ContentSize, 0);
              existingDocuments.push(document);
            }
          });
          component.set('v.documents', existingDocuments);
          helper.handleFilesChange(component, event, helper);
          component.set('v.filesSelected', true);
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
    $A.enqueueAction(getNewDocuments);
  },

  handleFilesChange: function (component, event, helper) {
    var labels = component.labels;
    var templates = component.get('v.templates');
    var emailSubject = null;
    var documents = component.get('v.documents');
    var defaultRecipients = component.get('v.selectedRecipients');
    var fileCheckboxes = helper.enforceArray(component.find('file-checkbox'));

    if ($A.util.isEmpty(templates)) {
      documents.forEach(function (document) {
        if (document.checked) {
          $A.util.isEmpty(emailSubject) ? emailSubject = labels.Please_DocuSign + ' ' + document.Title + '.' + document.FileExtension : emailSubject += ', ' + document.Title + '.' + document.FileExtension;
        }
      });
      component.set('v.emailSubject', emailSubject);
    }

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
    if ($A.util.isEmpty(templates)) {
      component.set('v.emailSubject', null);
    }
    component.set('v.recipientSettings', []);
    component.set('v.filesSelected', false);
  }
});
