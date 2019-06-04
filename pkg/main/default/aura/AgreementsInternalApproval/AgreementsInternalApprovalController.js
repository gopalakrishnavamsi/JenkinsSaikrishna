({
  onInit: function(component, event, helper) {
    helper.onInit(component, event, helper);
  },

  handleRecipientChange: function(component, event, helper) {
    helper.resolveRecipient(component, event.getParam('data'));
  },

  addRecipient: function(component, event, helper) {
    helper.addRecipient(component, event, helper);
  },

  removeRecipient: function (component, event, helper) {
    helper.removeRecipient(component, event);
  },

  onApproverDrag: function (component, event, helper) {
    helper.onApproverDrag(component, event);
  },

  allowDrop: function(component, event) {
    event.preventDefault();
  },

  onApproverDrop: function (component, event, helper) {
    helper.onApproverDrop(component, event);
  },

  setApprovalOrder: function (component, event, helper) {
    helper.setApprovalOrder(component);
  },

  backButtonClicked: function(component, event, helper) {
    helper.backButtonClicked(component, event, helper);
  },

  nextButtonClicked: function(component, event, helper) {
    helper.nextButtonClicked(component, event, helper);
  },

  handlePillCloseEvent: function(/*component, event, helper*/) {
    //TODO: Add the logic for updating the recipients array on this pill handle close event.
  }
});
