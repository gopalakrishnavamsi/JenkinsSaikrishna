({
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
