({
  initialize: function(component, helper) {
    var init = component.get('c.newController');
    init.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var apexController = response.getReturnValue();
        component.set('v.namespace', apexController.namespace);
        component.set('v.labels', apexController.labels);
        this.getStatus(component, helper);
      } else {
        this.setError(component, response);
      }
    });
    $A.enqueueAction(init);
  },

  getStatus: function(component, helper) {
    var gs = component.get('c.getStatus');
    gs.setParams({
      sourceId: component.get('v.recordId')
    });

    gs.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var envelopes = response.getReturnValue();
        if (!$A.util.isEmpty(envelopes)) {
          var labels = component.get('v.labels');
          envelopes.forEach(function (envelope) {
            envelope.status = helper.getStatusLabel(envelope.status, labels);
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
              recipient.status = helper.getStatusLabel(recipient.status, labels);
              recipient.completed = $A.util.isEmpty(recipient.completed) ? null : new Date(recipient.completed).toLocaleString().replace(/,/g, '');
              recipient.sent = $A.util.isEmpty(recipient.completed) ? null : new Date(recipient.completed).toLocaleString().replace(/,/g, '');
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

  getStatusLabel: function(status, labels) {
    var result = '';
    switch (status) {
      case 'created':
        result = labels.Created;
        break;
      case 'sent':
        result = labels.Sent;
        break;
      case 'delivered':
        result = labels.Delivered;
        break;
      case 'declined':
        result = labels.Declined;
        break;
      case 'voided':
        result = labels.Voided;
        break;
      case 'signed':
        result = labels.Signed;
        break;
      case 'completed':
        result = labels.Completed;
        break;
      default:
        break;
    }
    return result;
  }
});
