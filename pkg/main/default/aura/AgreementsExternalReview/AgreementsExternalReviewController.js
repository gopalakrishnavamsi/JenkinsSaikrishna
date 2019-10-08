({
  onInit: function (component, event, helper) {
    helper.initializeComponent(component, event, helper);
  },

  handleRecipientChange: function (component, event, helper) {
    helper.resolveRecipient(component, event.getParam('data'));
  },

  backButtonClicked: function (component, event, helper) {
    helper.backButtonClicked(component, event, helper);
  },

  nextButtonClicked: function (component, event, helper) {
    helper.nextButtonClicked(component, event, helper);
  },

  onDueDateChange: function (component, event, helper) {
    helper.setDueDateInDays(component);
  },

  handlePillCloseEvent: function (component, event, helper) {
    helper.initializeRecipients(component);
  },

  handleDisableDueDate: function (component, event, helper) {
    helper.setDisableDueDate(component);
  }

});
