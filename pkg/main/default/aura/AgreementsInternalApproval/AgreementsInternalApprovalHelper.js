({
  onInit: function (component, event, helper) {
    //initialize recipients
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient());
    component.set('v.recipients', recipients);

    //set the current step to 1
    component.set('v.currentStep', '1');
  },

  resolveRecipient: function (component, recipient) {
    var self = this;
    self.setLoading(component, true);
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
      self.setLoading(component, false);
    });
    $A.enqueueAction(rr);
  },

  addRecipient: function (component, event, helper) {
    var recipients = component.get('v.recipients');
    recipients.push(helper.newRecipient());
    component.set('v.recipients', recipients);
  },

  removeRecipient: function (component, event) {
    var recipients = component.get('v.recipients');
    recipients.splice(event.getSource().get('v.value'), 1);
    component.set('v.recipients', recipients);
  },

  onApproverDrag: function (component, event) {
    event.dataTransfer.setData('Text', '');
    if (
      event.currentTarget.id &&
      !$A.util.isUndefinedOrNull(parseInt(event.currentTarget.id))
    ) {
      component.set('v.draggedId', parseInt(event.currentTarget.id));
    }
  },

  onApproverDrop: function (component, event) {
    if (
      event.currentTarget.id &&
      !$A.util.isUndefinedOrNull(parseInt(event.currentTarget.id))
    ) {
      component.set('v.droppedId', parseInt(event.currentTarget.id));
    }

    var draggedId = component.get('v.draggedId');
    var droppedId = component.get('v.droppedId');
    var recipients = component.get('v.recipients');

    if (
      draggedId !== 'undefined' &&
      droppedId !== 'undefined' &&
      recipients !== 'undefined'
    ) {
      if (
        recipients[droppedId] !== 'undefined' &&
        recipients[draggedId] !== 'undefined' &&
        recipients[draggedId].name !== 'undefined' &&
        recipients[draggedId].name !== '' &&
        recipients[droppedId].name !== 'undefined' &&
        recipients[droppedId].name !== ''
      ) {
        var temp = recipients[draggedId];
        recipients.splice(draggedId, 1);
        recipients.splice(droppedId, 0, temp);
        component.set('v.recipients', recipients);
      }
    }
  },

  setApprovalOrder: function (component) {
    //set the attribute showApprovalOrder based on Checkbox value
    var isChecked = component.find('approvalOrderCheckbox').get('v.checked');
    component.set('v.showApprovalOrder', isChecked);
  },

  backButtonClicked: function (component, event, helper) {
    var currentStep = component.get('v.currentStep');
    //currentStep is Select Recipients
    if (currentStep === '1') {
      helper.hide(component, event, helper);
    }
    //currentStep is Edit your Message then direct user back to Select Recipients screen
    if (currentStep === '2') {
      component.set('v.currentStep', '1');
    }
  },

  nextButtonClicked: function (component, event, helper) {
    var currentStep = component.get('v.currentStep');
    if (currentStep === '1') {
      //Proceed to the personalize message step
      component.set('v.currentStep', '2');
    }
    if (currentStep === '2') {
      //If successful hide the component
      helper.hide(component, event, helper);
      //set the current step to 1
      component.set('v.currentStep', '1');
      //display toast notification
      helper.showToast(
        component,
        $A.get('$Label.c.InternalApprovalSuccess'),
        'success'
      );
    }
  },

  newRecipient: function (recipient) {
    var isDefined = !$A.util.isUndefinedOrNull(recipient);
    return {
      name: isDefined ? recipient.name : null,
      email: isDefined ? recipient.email : null,
      source: isDefined ? recipient.source : {},
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

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true, message: message, mode: mode
    });
    evt.fire();
  },

  setLoading: function (component, loading) {
    component.set('v.loading', loading === true);
  },

  show: function (component) {
    component.find('internalApprovalAgreementsModal').show();
  },

  hide: function (component) {
    component.find('internalApprovalAgreementsModal').hide();
  }

});
