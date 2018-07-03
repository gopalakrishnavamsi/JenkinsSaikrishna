({
  onInit: function (component, event, helper) {
    // var namespace = component.get('c.namespace');
    // component.set('v.labels', {
    //   EnvelopeStatus: $A.get('$Label.' + namespace + '.EnvelopeStatus')
    // });
    component.set('v.loading', true);
    var getStatus = component.get('c.getStatus');
    getStatus.setParams({
      sourceId: component.get('v.recordId')
    });

    getStatus.setCallback(this, function (response) {
      var status = response.getState();
      if (status === 'SUCCESS') {
        var envelopes = response.getReturnValue();
        if (!$A.util.isEmpty(envelopes)) {
          envelopes.forEach(function (envelope) {
            if (envelope.expires) {
              envelope.expires = {
                value: new Date(envelope.expires),
                daysBetween: helper.getDaysBetween(envelope.expires)
              };
            }
            envelope.sent = {
              value: new Date(envelope.sent),
              daysBetween: helper.getDaysBetween(envelope.sent)
            };
            envelope.lastStatusUpdate = {
              value: new Date(envelope.lastStatusUpdate),
              daysBetween: helper.getDaysBetween(envelope.lastStatusUpdate)
            };
            envelope.recipients.forEach(function (recipient) {
              recipient.completed = $A.util.isEmpty(recipient.completed) ? null : new Date(recipient.completed).toLocaleString().replace(/,/g, '');
              recipient.sent = $A.util.isEmpty(recipient.completed) ? null : new Date(recipient.completed).toLocaleString().replace(/,/g, '');
              if (recipient.sent) {
                recipient.sent = {
                  value: new Date(recipient.sent),
                  daysBetween: helper.getDaysBetween(recipient.sent)
                };
              }

              if (recipient.completed) {
                recipient.completed = {
                  value: new Date(recipient.completed),
                  daysBetween: helper.getDaysBetween(recipient.completed)
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
        var errors = response.getError();
        var errMsg = errors;
        if (!$A.util.isEmpty(errors)) {
          errMsg = errors[0].message;
        }
        console.error(errMsg);
        component.set('v.errorMessage', errMsg);
      }
    });
    $A.enqueueAction(getStatus);
  },

  handleEnvelopeNameClick: function (component, event, helper) {
    var recipientId = event.currentTarget.dataset.sender;
    var navEvt = $A.get('e.force:navigateToSObject');
    if (!$A.util.isEmpty(navEvt)) {
      navEvt.setParams({
        'recordId': recipientId, 'slideDevName': 'detail'
      });
      navEvt.fire();
    }
  },

  toggleRecipientDetails: function (component, event, helper) {
    var targetEnvelopeIndex = parseInt(event.currentTarget.dataset.envelopeIndex, 10);
    var targetIndex = parseInt(event.currentTarget.dataset.index, 10);
    var recipients = component.find('recipient');

    recipients = Array.isArray(recipients) ? recipients : [recipients];

    for (var i = 0; i < recipients.length; i++) {
      if (parseInt(recipients[i].getElement().dataset.envelopeIndex, 10) === targetEnvelopeIndex && parseInt(recipients[i].getElement().dataset.index, 10) === targetIndex) {
        $A.util.toggleClass(recipients[i].getElement(), 'ds-recipient_details-shown');
        break;
      }
    }
  },

  handleViewAllClick: function (component, event, helper) {
    var listViews = component.get('c.getEnvelopeListView');
    listViews.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var errMsg = JSON.parse(response.getReturnValue()).errMsg;
        if ($A.util.isEmpty(errMsg)) {
          var listView = JSON.parse(response.getReturnValue()).results.listView;
          var navEvent = $A.get('e.force:navigateToList');
          navEvent.setParams({
            "listViewId": listView.Id, "listViewName": listView.Name, "scope": /*namespaceApi +*/ 'Envelope__c'
          });
          navEvent.fire();
        }
      }
    });
    $A.enqueueAction(listViews);
  },

  toggleEnvelopeDetails: function (component, event, helper) {
    var targetIndex = parseInt(event.getSource().get('v.value'), 10);
    var envelopes = component.find('envelope');

    envelopes = Array.isArray(envelopes) ? envelopes : [envelopes];

    for (var i = 0; i < envelopes.length; i++) {
      if (parseInt(envelopes[i].getElement().dataset.index, 10) === targetIndex) {
        $A.util.toggleClass(envelopes[i].getElement(), 'slds-is-open');
        break;
      }
    }
  }
});
