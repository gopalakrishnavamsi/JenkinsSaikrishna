({
  handleEditAccessAuthentication: function (component, event, helper) {
    //component.getEvent('onEditAccessAuthentication').fire();
    component.find('access-authentication-modal').set('v.showModal', true);

    setTimeout($A.getCallback(function () {
      component.find('authentication-input').focus();
    }), 250);
  },

  handleEditPrivateMessage: function (component, event, helper) {
    //component.getEvent('onEditPrivateMessage').fire();
    component.find('private-message-modal').set('v.showModal', true);

    setTimeout($A.getCallback(function () {
      component.find('message-input').focus();
    }), 250);
  },

  handleEditCustomEmailMessage: function (component, event, helper) {
    /*component.find('language-input').get('v.value');
    component.find('subject-input').get('v.value');
    component.find('body-input').get('v.value');
    component.getEvent('onEditCustomEmailMessage').fire();*/
    component.find('custom-email-message-modal').set('v.showModal', true);

    setTimeout($A.getCallback(function () {
      component.find('subject-input').focus();
    }), 250);
  },

  handleRecipientIdChange: function (component, event, helper) {
    component.getEvent('recipientIdChange').fire();
  },

  closeAccessAuthenticationModal: function (component, event, helper) {
    component.find('access-authentication-modal').set('v.showModal', false);
  },

  closePrivateMessageModal: function (component, event, helper) {
    component.find('private-message-modal').set('v.showModal', false);
  },

  closeCustomEmailMessageModal: function (component, event, helper) {
    component.find('custom-email-message-modal').set('v.showModal', false);
  }
});
