({
  initialize: function (component, helper) {
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
            envelope.style = helper.getStyleDetails(envelope.status);
            envelope.status = helper.getStatusLabel(envelope.status);
            envelope.recipients.forEach(function (recipient) {
              recipient.style = helper.getStyleDetails(recipient.status);
              recipient.status = helper.getStatusLabel(recipient.status);
              recipient.completed = $A.util.isEmpty(recipient.completed) ? null : new Date(recipient.completed).toLocaleString().replace(/,/g, '');
              recipient.sent = $A.util.isEmpty(recipient.sent) ? null : new Date(recipient.sent).toLocaleString().replace(/,/g, '');
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

  setError: function (component, response) {
    if (component && response) {
      var errors = response.getError();
      var errMsg = errors;
      if (!$A.util.isEmpty(errors)) {
        errMsg = errors[0].message;
      }
      component.set('v.errorMessage', errMsg);
    }
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
      case 'autoresponded':
        result = $A.get('$Label.c.Autoresponded');
        break;
      case 'authenticationfailed':
        result = $A.get('$Label.c.Authenticationfailed');
        break;
      default:
        break;
    }
    return result;
  },

  getStyleDetails: function (status) {
    var details = {};
    switch (status) {
      case 'created':
        details.icon = 'utility:record_create';
        details.color = 'ds-timeline__orange';
        details.container = 'ds-timeline__pending icon-padding';
        break;
      case 'sent':
        details.icon = 'custom:custom105';
        details.color = 'ds-timeline__orange';
        details.container = 'ds-timeline__pending';
        break;
      case 'delivered':
        details.icon = 'action:preview';
        details.color = 'ds-timeline__orange';
        details.container = 'ds-timeline__pending icon-padding slds-p-around_none';
        break;
      case 'canceled':
      case 'declined':
      case 'voided':
        details.icon = 'action:remove';
        details.color = 'ds-timeline__red';
        details.container = 'ds-timeline__negative icon-padding';
        break;
      case 'completed':
      case 'signed':
        details.icon = 'standard:task2';
        details.color = 'ds-timeline__green';
        details.container = 'ds-timeline__positive';
        break;
      case 'autoresponded':
        details.icon = 'utility:warning'
        details.color = 'ds-timeline__red';
        details.container = 'ds-timeline__negative icon-padding';
        break;
      case 'authenticationfailed':
        details.icon = 'utility:block_visitor';
        details.color = 'ds-timeline__red';
        details.container = 'ds-timeline__negative icon-padding';
        break;
      default:
        details.icon = 'utility:warning';
        details.color = 'ds-timeline__red';
        details.container = 'ds-timeline__negative icon-padding';
        break;
    }

    return details;
  }
});