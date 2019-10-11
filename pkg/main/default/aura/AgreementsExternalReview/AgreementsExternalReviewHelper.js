({
  initializeComponent: function (component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient());
    var now = new Date();
    var minimumDueDate = helper.getDateWithDaysOffset(now, 1);
    component.set('v.recipients', recipients);
    component.set('v.currentStep', '1');
    component.set('v.minimumDueDate', helper.getFormattedDate(minimumDueDate));
    var dueDateElement = component.find('externalReviewDueDate');
    var dueDate = helper.getDateWithDaysOffset(now, 30);
    if (dueDateElement) {
      dueDateElement.set('v.value', helper.getFormattedDate(dueDate));
    }
  },

  backButtonClicked: function (component, event, helper) {
    var currentStep = component.get('v.currentStep');
    if (currentStep === '1') {
      helper.close(component);
    }
    if (currentStep === '2') {
      component.set('v.currentStep', '1');
    }
  },

  nextButtonClicked: function (component, event, helper) {
    var currentStep = component.get('v.currentStep');
    var dueDate = component.get('v.dueDate');
    var minimumDueDate = component.get('v.minimumDueDate');
    var disableDueDate = component.get('v.disableDueDate');
    var daysDifference = helper.computeDaysDifference(dueDate, minimumDueDate);
    var dueDateValidation = disableDueDate || daysDifference >= 0;
    if (currentStep === '1' && dueDateValidation) {
      component.set('v.currentStep', '2');
    }
    if (currentStep === '2') {
      helper.triggerSendForExternalReview(component);
    }
  },

  reloadAgreementsSpace: function (component) {
    component.getEvent('reloadEvent').fire();
  },

  getErrorMessage: function (response) {
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

  resolveRecipient: function (component, recipient) {
    var self = this;
    var sourceId = self.getSourceId(recipient);
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

  newRecipient: function (recipient) {
    var isDefined = !$A.util.isUndefinedOrNull(recipient);
    return {
      name: isDefined ? recipient.name : null,
      email: isDefined ? recipient.email : null,
      source: isDefined ? recipient.source : {}
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

  show: function (component) {
    component.find('externalReviewAgreementsModal').show();
  },

  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  setDueDateInDays: function (component, event, helper) {
    var dueDate = component.get('v.dueDate'); //date selected by end user
    var dateToday = helper.getFormattedDate(new Date()); // today's date
    var daysDifference = helper.computeDaysDifference(dueDate, dateToday);
    component.set('v.requestExpirationDays', daysDifference);
  },

  initializeRecipients: function (component) {
    var recipients = component.get('v.recipients');
    recipients.forEach(function (recipient) {
      recipient.name = null;
      recipient.email = null;
      recipient.source = {};
    });
    component.set('v.recipients', recipients);
  },

  triggerSendForExternalReview: function (component) {
    component.set('v.loading', true);
    var self = this;
    var agreementDetails = component.get('v.agreementDetails');
    var recipients = component.get('v.recipients');
    var sourceId = component.get('v.sourceId');

    var documentIdList = [];
    documentIdList.push(agreementDetails.id.value);

    var emailSubject = component.get('v.emailSubject');
    var emailBody = component.get('v.emailBody');
    var requestExpirationDays = component.get('v.requestExpirationDays');

    if (component.get('v.disableDueDate') || requestExpirationDays < 0) {
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

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
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
      } else {
        self.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  },

  computeDaysDifference: function (endDate, startDate) {
    return Math.ceil(
      (Date.parse(endDate) - Date.parse(startDate)) / (86400 * 1000)
    );
  },

  // add or subtract days from given date
  getDateWithDaysOffset: function (date, days) {
    return new Date(date.valueOf() + 86400 * 1000 * days);
  },

  // output date format: 'YYYY-MM-DD'
  getFormattedDate: function (date) {
    return date.toISOString().slice(0, 10);
  }
});
