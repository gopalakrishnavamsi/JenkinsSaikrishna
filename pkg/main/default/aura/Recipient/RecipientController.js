({
  initialize: function (component) {
    component.set('v.isEmailLocalizationEnabled', !$A.util.isEmpty(component.get('v.emailLocalizations')));
  },

  handleEditAccessAuthentication: function (component) {
    component.find('access-authentication-modal').set('v.showModal', true);

    setTimeout($A.getCallback(function () {
      component.find('authentication-input').focus();
    }), 250);
  },

  handleEditPrivateMessage: function (component) {
    //component.getEvent('onEditPrivateMessage').fire();
    component.find('private-message-modal').set('v.showModal', true);

    setTimeout($A.getCallback(function () {
      component.find('message-input').focus();
    }), 250);
  },

  handleEditCustomEmailMessage: function (component) {
    /*component.find('language-input').get('v.value');
    component.find('subject-input').get('v.value');
    component.find('body-input').get('v.value');
    component.getEvent('onEditCustomEmailMessage').fire();*/
    component.find('custom-email-message-modal').set('v.showModal', true);

    setTimeout($A.getCallback(function () {
      component.find('subject-input').focus();
    }), 250);
  },

  handleRecipientIdChange: function (component) {
    var recipient = component.get('v.recipient');
    var sId = component.get('v.sourceId');
    var recipientIsDeleted = $A.util.isEmpty(sId);
    if (!$A.util.isUndefinedOrNull(recipient)) {
      var e = component.getEvent('recipientIdChange');
      recipient.source = {
        id: sId || recipient.source.id,
        deleted: recipientIsDeleted
      };
      e.setParams({
        data: recipient
      });
      e.fire();
    }
  },

  closeAccessAuthenticationModal: function (component) {
    component.find('access-authentication-modal').set('v.showModal', false);
  },

  closePrivateMessageModal: function (component) {
    component.find('private-message-modal').set('v.showModal', false);
  },

  closeCustomEmailMessageModal: function (component) {
    component.find('custom-email-message-modal').set('v.showModal', false);
  },

  onEmailLanguageChange: function (component) {
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
