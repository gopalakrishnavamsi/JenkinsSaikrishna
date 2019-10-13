({
  getAuthStatus: function (component) {
    var uiHelper = component.get('v.uiHelper');
    var onSuccess = function (authStatus) {
      if (authStatus) {
        component.set('v.fetchingOAuthStatus', false);
        if(authStatus.isAuthorized) {
          component.set('v.products', authStatus.products);
        }
        component.set('v.isAuthorized', authStatus.isAuthorized);
        component.set('v.isConsentRequired', authStatus.isConsentRequired);
        component.set('v.userStatusMessage', authStatus.message);
        component.set('v.eventOrigins', authStatus.eventOrigins);
        if (!component.get('v.isAuthorized')) {
          $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
        }
      }
      var loadingEvent = component.getEvent('loadingEvent');
      loadingEvent.setParam('isLoading', authStatus.isAuthorized);
      loadingEvent.setParam('isAuthorizeEvent', true);
      loadingEvent.fire();
    };

    uiHelper.invokeAction(component.get('c.getAuthStatus'), null, onSuccess);
  },

  beginOAuth: function (component) {
    var uiHelper = component.get('v.uiHelper');
    var helper = this;
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
            helper.getProductsOnAccount(component, success).then(
              $A.getCallback(function (products) {
                component.set('v.products', products);
                component.set('v.isAuthorized', success);
                if (component.get('v.isAuthorized')) {
                  $A.util.addClass(component.find('ds-app-auth'), 'slds-hide');
                }else{
                  $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
                }
                component.set('v.isConsentRequired', !success);
                if (event.source) {
                  event.source.close();
                }
              })
            );
          }
        }
      };

      var oauthWindow = window.open(stringUtils.unescapeHtml(loginUrl), 'ds-oauth', 'width=' + width + ',height=' + height + ',left=' + left + ',top=' + top);
      window.addEventListener('message', $A.getCallback(onMessage));
      oauthWindow.focus();
    };

    uiHelper.invokeAction(component.get('c.beginOAuth'), {target: window.location.origin}, openOAuthWindow);
  },

  getProductsOnAccount: function (component, isAuthorized) {
    var helper = this;
    return new Promise(
      $A.getCallback(function (resolve) {
        if (isAuthorized) {
          var getProductsAction = component.get('c.getProductsOnAccount');
          getProductsAction.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
              resolve(response.getReturnValue());
            } else {
              helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
              resolve(null);
            }
          }));
          $A.enqueueAction(getProductsAction);
        }
      }));
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
