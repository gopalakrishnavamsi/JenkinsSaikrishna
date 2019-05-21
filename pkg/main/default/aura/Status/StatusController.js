({
  onChangeIsAuthorized: function (component, event, helper) {
    if (component.get('v.isAuthorized')) {
      component.set('v.loading', true);
      helper.initialize(component, helper);
    }
  },

  toggleRecipientDetails: function (component, event) {
    var targetEnvelopeIndex = parseInt(event.currentTarget.dataset.envelopeIndex, 10);
    var targetIndex = parseInt(event.currentTarget.dataset.index, 10);
    var recipients = component.find('recipient');

    recipients = Array.isArray(recipients) ? recipients : [recipients];

    for (var i = 0; i < recipients.length; i++) {
      var element = recipients[i].getElement();
      if (parseInt(element.dataset.envelopeIndex, 10) === targetEnvelopeIndex && parseInt(element.dataset.index, 10) === targetIndex) {
        $A.util.toggleClass(element, 'ds-recipient_details-shown');
        break;
      }
    }
  },

  handleViewAllClick: function (component, event, helper) {
    var getStatusListViews = component.get('c.getStatusListViews');
    getStatusListViews.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var listViews = response.getReturnValue();
        if (!$A.util.isEmpty(listViews)) {
          var listView = listViews[0]; // TODO: Allow selection or default?
          var navEvent = $A.get('e.force:navigateToList');
          navEvent.setParams({
            listViewId: listView.Id, listViewName: listView.Name, scope: listView.SobjectType
          });
          navEvent.fire();
        }
      } else {
        helper.setError(component, response);
      }
    });
    $A.enqueueAction(getStatusListViews);
  },

  toggleEnvelopeDetails: function (component, event) {
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
