({
  initializeComponent: function(component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient());
    component.set('v.recipients', recipients);
    component.set('v.currentStep', '1');
    var dueDateElement = component.find('externalReviewDueDate');
    if (dueDateElement)
      dueDateElement.set(
        'v.value',
        new Date(new Date().valueOf() + 86400000 * 30)
          .toISOString()
          .slice(0, 10)
      );
  },

  backButtonClicked: function(component, event, helper) {
    var currentStep = component.get('v.currentStep');
    if (currentStep === '1') {
      helper.close(component);
    }
    if (currentStep === '2') {
      component.set('v.currentStep', '1');
    }
  },

  nextButtonClicked: function(component, event, helper) {
    var currentStep = component.get('v.currentStep');
    if (currentStep === '1') {
      component.set('v.currentStep', '2');
    }
    if (currentStep === '2') {
      helper.triggerSendForExternalReview(component);
    }
  },

  reloadAgreementsSpace: function(component) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: true
    });
    evt.fire();
  },

  getErrorMessage: function(response) {
    // TODO: Use uiHelper library.
    var message = '';
    if (response) {
      var errors = response.getError();
      message = errors;
      if (Array.isArray(errors) && errors.length > 0) {
        message = errors[0].message;
      }
    }
    return message;
  },

  resolveRecipient: function(component, recipient) {
    var self = this;
    var sourceId = self.getSourceId(recipient);
    if ($A.util.isEmpty(sourceId)) return;

    var rr = component.get('c.resolveRecipient');
    rr.setParams({
      sourceId: sourceId
    });
    rr.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var result = response.getReturnValue();
        if (!$A.util.isUndefinedOrNull(result)) {
          var updated = false;
          var rs = component.get('v.recipients');
          rs.forEach(function(r) {
            // Update name, email, phone, full source for new recipient
            if (self.getSourceId(r) === sourceId) {
              r.name = result.name;
              r.email = result.email;
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
        self.showToast(component, self.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(rr);
  },

  newRecipient: function(recipient) {
    var isDefined = !$A.util.isUndefinedOrNull(recipient);
    return {
      name: isDefined ? recipient.name : null,
      email: isDefined ? recipient.email : null,
      source: isDefined ? recipient.source : {}
    };
  },

  getSourceId: function(x) {
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

  show: function(component) {
    component.find('externalReviewAgreementsModal').show();
  },

  close: function(component) {
    component.destroy();
  },

  showToast: function(component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  setDueDateInDays: function(component) {
    var dueDate = component.get('v.dueDate'); //date selected by end user
    var dateToday = new Date().toISOString().slice(0, 10); // today's date
    var daysDifference = Math.floor(
      (Date.parse(dueDate) - Date.parse(dateToday)) / 86400000
    );
    if (daysDifference && daysDifference >= 0) {
      component.set('v.requestExpirationDays', daysDifference);
    } else {
      component.set('v.requestExpirationDays', 0);
    }
  },

  initializeRecipients: function(component) {
    var recipients = component.get('v.recipients');
    recipients.forEach(function(recipient) {
      recipient.name = null;
      recipient.email = null;
      recipient.source = {};
    });
    component.set('v.recipients', recipients);
  },

  triggerSendForExternalReview: function(component) {
    component.set('v.loading', true);
    var self = this;
    var agreementDetails = component.get('v.agreementDetails');
    var recipients = component.get('v.recipients');
    var sourceId = component.get('v.sourceId');

    var documentIdList = [];
    documentIdList.push(agreementDetails.id.value);

    var emailSubject = component.get('v.emailSubject');
    var emailBody = component.get('v.emailBody');

    var requestExpirationDays;
    if (!component.get('v.disableDueDate')) {
      requestExpirationDays = component.get('v.requestExpirationDays');
    } else {
      requestExpirationDays = 0;
    }

    var action = component.get('c.sendForExternalReview');

    action.setParams({
      agreementName: agreementDetails.name,
      sourceId: sourceId,
      documentsIds: documentIdList,
      reviewersJson: JSON.stringify(recipients),
      subject: emailSubject,
      body: emailBody,
      expiresInNumberOfDays: requestExpirationDays
    });
    action.setCallback(this, function(response) {
      var state = response.getState();

      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result.status === 'Waiting') {
          self.showToast(component, result.message, 'success');
          self.reloadAgreementsSpace(component);
          self.close(component);
        } else if (result.status === 'Executing') {
          self.showToast(component, result.message, 'warning');
          self.reloadAgreementsSpace(component);
          self.close(component);
        } else {
          self.showToast(component, result.message, 'error');
          self.reloadAgreementsSpace(component);
          self.close(component);
        }
      } else if (state === 'ERROR') {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        self.showToast(component, errorMessage, 'error');
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  }
});
