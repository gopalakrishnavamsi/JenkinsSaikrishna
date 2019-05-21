({
  getAuthStatus: function (component) {
    var uiHelper = component.get('v.uiHelper');

    var onSuccess = function (authStatus) {
      if (authStatus) {
        component.set('v.isAuthorized', authStatus.isAuthorized);
        component.set('v.isConsentRequired', authStatus.isConsentRequired);
        component.set('v.userStatusMessage', authStatus.message);
        component.set('v.eventOrigin', authStatus.eventOrigin);
      }

      if (!component.get('v.isAuthorized')) {
        $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
      }
    };

    uiHelper.invokeAction(component.get('c.getAuthStatus'), null, onSuccess);
  },

  beginOAuth: function (component) {
    var uiHelper = component.get('v.uiHelper');

    var openOAuthWindow = function (loginUrl) {
      var width = 600;
      var height = 600;
      var left = (screen.width / 2) - (width / 2);
      var top = (screen.height / 2) - (height / 2);

      var onMessage = function (event) {
        if (component && component.isValid()) {
          // event must originate from Visualforce page on our domain
          if (event.origin === component.get('v.eventOrigin')) {
            window.removeEventListener('message', onMessage);
            var success = event.data.loginInformation && event.data.loginInformation.status === 'Success';
            component.set('v.isAuthorized', success);
            component.set('v.isConsentRequired', !success);
            event.source.close();
          }
        }
      };

      var oauthWindow = window.open(stringUtils.unescapeHtml(loginUrl), 'ds-oauth', 'width=' + width + ',height=' + height + ',left=' + left + ',top=' + top);
      window.addEventListener('message', $A.getCallback(onMessage));
      oauthWindow.focus();
    };

    uiHelper.invokeAction(component.get('c.beginOAuth'), {origin: window.location.origin}, openOAuthWindow);
  }
});
