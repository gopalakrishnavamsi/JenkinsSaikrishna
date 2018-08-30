({
  initialize: function(component, helper) {
    var gs = component.get('c.getStatus');
    gs.setParams({
      sourceId: component.get('v.recordId'),
      recordLimit: 5
    });

    gs.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var envelopes = response.getReturnValue();
        if (!$A.util.isEmpty(envelopes)) {
          envelopes.forEach(function (envelope) {
            envelope.status = helper.getStatusLabel(envelope.status);
            if (envelope.expires) {
              envelope.expires = {
                value: new Date(envelope.expires), daysBetween: helper.getDaysBetween(envelope.expires)
              };
            }
            envelope.sent = {
              value: new Date(envelope.sent), daysBetween: helper.getDaysBetween(envelope.sent)
            };
            envelope.completed = {
              value: new Date(envelope.completed), daysBetween: helper.getDaysBetween(envelope.completed)
            };
            envelope.lastStatusUpdate = {
              value: new Date(envelope.lastStatusUpdate), daysBetween: helper.getDaysBetween(envelope.lastStatusUpdate)
            };
            envelope.recipients.forEach(function (recipient) {
              recipient.status = helper.getStatusLabel(recipient.status);
              recipient.completed = $A.util.isEmpty(recipient.completed) ? null : new Date(recipient.completed).toLocaleString().replace(/,/g, '');
              recipient.sent = $A.util.isEmpty(recipient.sent) ? null : new Date(recipient.sent).toLocaleString().replace(/,/g, '');
              if (recipient.sent) {
                recipient.sent = {
                  value: new Date(recipient.sent), daysBetween: helper.getDaysBetween(recipient.sent)
                };
              }

              if (recipient.completed) {
                recipient.completed = {
                  value: new Date(recipient.completed), daysBetween: helper.getDaysBetween(recipient.completed)
                };
              }
            });
          });
        } else {
          component.set('v.loading', false);
        }
        component.set('v.loading', false);
        component.set('v.envelopes', envelopes);
      } else {
        component.set('v.loading', false);
        this.setError(component, response);
      }
    });
    $A.enqueueAction(gs);
  },

  setError: function(component, response) {
    if (component && response) {
      var errors = response.getError();
      var errMsg = errors;
      if (!$A.util.isEmpty(errors)) {
        errMsg = errors[0].message;
      }
      console.error(errMsg);
      component.set('v.errorMessage', errMsg);
    }
  },

  getDaysBetween: function (date) {
    if ($A.util.isEmpty(date)) {
      return null;
    }
    var dateTime = (typeof(date.getTime) === 'undefined') ? this.getJavascriptDate(date).getTime() : date.getTime();
    var today = new Date().getTime();
    var oneDay = 24 * 60 * 60 * 1000;
    return Math.floor(Math.abs((today - dateTime) / oneDay));
  },

  getJavascriptDate: function (date) {
    return new Date(date);
  },

  getStatusLabel: function(status) {
    var result = '';
    switch (status) {
      case 'created':
        result = $A.get('$Label.c.Created');
        break;
      case 'sent':
        result = $A.get('$Label.c.Sent');
        break;
      case 'delivered':
        result = $A.get('$Label.c.Delivered');
        break;
      case 'declined':
        result = $A.get('$Label.c.Declined');
        break;
      case 'voided':
        result = $A.get('$Label.c.Voided');
        break;
      case 'signed':
        result = $A.get('$Label.c.Signed');
        break;
      case 'completed':
        result = $A.get('$Label.c.Completed');
        break;
      case 'canceled':
        result = $A.get('$Label.c.Canceled');
        break;
      default:
        break;
    }
    return result;
  }
});
