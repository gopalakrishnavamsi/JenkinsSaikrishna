({
  getAuthStatus: function (component) {
    var uiHelper = component.get('v.uiHelper');

    var onSuccess = function (authStatus) {
      if (authStatus) {
        this.getProductsOnAccount(component);
        component.set('v.fetchingOAuthStatus', false);
        component.set('v.isAuthorized', authStatus.isAuthorized);
        component.set('v.isConsentRequired', authStatus.isConsentRequired);
        component.set('v.userStatusMessage', authStatus.message);
        component.set('v.eventOrigins', authStatus.eventOrigins);
      }

      if (!component.get('v.isAuthorized')) {
        $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
      }
      var loadingEvent = component.getEvent('loadingEvent');
      loadingEvent.setParam('isLoading', authStatus.isAuthorized);
      loadingEvent.fire();
    };

    uiHelper.invokeAction(component.get('c.getAuthStatus'), null, onSuccess);
  },

  beginOAuth: function (component) {
    var uiHelper = component.get('v.uiHelper');

    var openOAuthWindow = function (loginUrl) {
      var width = 600;
      var height = 600;
      var left = screen.width / 2 - width / 2;
      var top = screen.height / 2 - height / 2;

      var onMessage = function (event) {
        if (component && component.isValid()) {
          // event must originate from Visualforce page on our domain
          if (component.get('v.eventOrigins').indexOf(event.origin) !== -1) {
            window.removeEventListener('message', onMessage);
            var success = event.data.loginInformation && event.data.loginInformation.status === 'Success';
            component.set('v.isAuthorized', success);
            component.set('v.isConsentRequired', !success);
            if (component.get('v.isAuthorized')) {
              this.getProductsOnAccount(component);
              $A.util.addClass(component.find('ds-app-auth'), 'slds-hide');
            } else {
              $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
            }
            event.source.close();
          }
        }
      };

      var oauthWindow = window.open(stringUtils.unescapeHtml(loginUrl), 'ds-oauth', 'width=' + width + ',height=' + height + ',left=' + left + ',top=' + top);
      window.addEventListener('message', $A.getCallback(onMessage));
      oauthWindow.focus();
    };

    uiHelper.invokeAction(component.get('c.beginOAuth'), {target: window.location.origin}, openOAuthWindow);
  },

  getProductsOnAccount: function (component) {
    var helper = this;
    var getProductsAction = component.get('c.getProductsOnAccount');
    getProductsAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var products = response.getReturnValue();
        component.set('v.products', products);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(getProductsAction);
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  }
});
