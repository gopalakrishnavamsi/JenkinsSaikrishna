({
  initialize: function (component, event, helper) {
    var emailLocalizations = component.get('v.emailLocalizations');
    component.set('v.isEmailLocalizationEnabled', !$A.util.isEmpty(emailLocalizations));
    var recipient = component.get('v.recipient');
    if (!!recipient) {
      component.set('v.recipientName', recipient.name);
      if (!!recipient.source) {
        component.set('v.recipientSourceId', recipient.source.id);
      }
    }
  },

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
    var recipient = component.get('v.recipient');
    recipient.name = component.get('v.recipientName');
    recipient.source = {
      id: component.get('v.recipientSourceId')
    };
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
  },

  onEmailLanguageChange: function(component, event, helper) {
    var newSelectedLanguage = component.find('email-language').get('v.value');
    var currentSelectedLanguage = component.get('v.selectedLanguage');
    if (newSelectedLanguage !== currentSelectedLanguage) {
      var emailLocalizations = component.get('v.emailLocalizations');
      for (var i = 0; i < emailLocalizations.length; i++) {
        var el = emailLocalizations[i];
        if (newSelectedLanguage === el.language) {
          component.find('email-subject').set('v.value', el.subject);
          component.find('email-message').set('v.value', el.message);
          break;
        }
      }
      component.set('v.selectedLanguage', newSelectedLanguage);
    }
  }
});
