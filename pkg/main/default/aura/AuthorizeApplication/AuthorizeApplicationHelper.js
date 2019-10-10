({
  getAuthStatus: function (component) {
    var uiHelper = component.get('v.uiHelper');
    var helper = this;
    var onSuccess = function (authStatus) {
      if (authStatus) {
        helper.getProductsOnAccount(component, authStatus.isAuthorized).then(
          $A.getCallback(function () {
            component.set('v.fetchingOAuthStatus', false);
            component.set('v.isAuthorized', authStatus.isAuthorized);
            component.set('v.isConsentRequired', authStatus.isConsentRequired);
            component.set('v.userStatusMessage', authStatus.message);
            component.set('v.eventOrigins', authStatus.eventOrigins);

            if (!component.get('v.isAuthorized')) {
              $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
            }
            var loadingEvent = component.getEvent('loadingEvent');
            loadingEvent.setParam('isLoading', authStatus.isAuthorized);
            loadingEvent.setParam('isAuthorizeEvent', true);
            loadingEvent.fire();
          })
        );
      }
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
              $A.getCallback(function () {
                if (success) {
                  $A.util.addClass(component.find('ds-app-auth'), 'slds-hide');
                } else {
                  $A.util.removeClass(component.find('ds-app-auth'), 'slds-hide');
                }
                component.set('v.isAuthorized', success);
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
              var products = response.getReturnValue();
              if (!$A.util.isUndefinedOrNull(products)) {
                products.forEach(function (product) {
                  if (product.name === 'e_sign') {
                    component.set('v.eSignProduct', true);
                  } else if (product.name === 'gen') {
                    component.set('v.genProduct', true);
                  } else if (product.name === 'negotiate') {
                    component.set('v.negotiateProduct', true);
                  } else if (product.name === 'clm') {
                    component.set('v.clmProduct', true);
                  }
                });
              }
            } else {
              helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
            }
            resolve();
          }));
          $A.enqueueAction(getProductsAction);
        } else {
          resolve();
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
