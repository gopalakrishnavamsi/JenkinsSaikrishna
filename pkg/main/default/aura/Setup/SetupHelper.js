({
  getState: function (component, event, helper) {
    var showSetupSpinner = component.get('v.showSetupSpinner');
    showSetupSpinner();
    var getLoginStatus = component.get('c.getLogin');
    getLoginStatus.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var login = response.getReturnValue();
        var isLoggedIn = login && login.status === 'Success';
        component.set('v.login', login);
        component.set('v.isLoggedIn', isLoggedIn);
        component.set('v.isPlatformAuthorized', login.isPlatformAuthorized);
        component.set(
          'v.login.selectedAccountNumber',
          !isLoggedIn ||
          $A.util.isUndefinedOrNull(login) ||
          $A.util.isEmpty(login.accounts)
            ? null
            : login.accounts[0].accountNumber
        );
        // TODO: Fix trial accounts. GET /oauth/userinfo response includes no account plan information.
        component.set('v.isTrial', false);
        component.set('v.isTrialExpired', false);
        //Invoke logic for rendering either Authentication / Esign / CLM components based on authentication states and account products
        helper.renderSetupView(component, event, helper);
      } else {
        var showSetupComponent = component.get('v.showSetupComponent');
        showSetupComponent();
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    }));

    $A.enqueueAction(getLoginStatus);
  },

  renderSetupView: function (component, event, helper) {
    var isLoggedIn = component.get('v.isLoggedIn');
    var isPlatformAuthorized = component.get('v.isPlatformAuthorized');

    //Not logged in then create the Login component
    if (!isLoggedIn) {
      helper.createComponent('setupContent', component, 'c:Login',
        {
          beginOAuth: component.get('v.beginOAuth'),
          beginSpringOAuth: component.get('v.beginSpringOAuth'),
          login: component.get('v.login')
        }
      );
    } else {
      //logged in
      //fetch the products
      helper.fetchAccountProducts(component)
        .then($A.getCallback(function (response) {
          component.set('v.products', response);
          var eSignFound = false;
          var genFound = false;
          var clmFound = false;
          var negotiateFound = false;
          //No valid products on the account handle case here
          component.get('v.products').forEach(function (product) {
            if (product.name === 'e_sign') {
              eSignFound = true;
            } else if (product.name === 'gen') {
              genFound = true;
            } else if (product.name === 'clm') {
              clmFound = true;
            } else if (product.name === 'negotiate') {
              negotiateFound = true;
            }
          });

          //Authorized and clm product found. load clm admin interface
          if (isPlatformAuthorized && clmFound) {
            helper.createComponent('setupContent', component, 'c:CLMSetupLayout', {login: component.get('v.login')});
          }

          //Authorized and non clm product found. currently either gen or negotiate
          else if (isPlatformAuthorized && (eSignFound || genFound || negotiateFound)) {
            helper.createComponent('setupContent', component, 'c:SetupWizard', {
              login: component.get('v.login'),
              products: component.get('v.products'),
              showSetupSpinner: component.get('v.showSetupSpinner'),
              showSetupComponent: component.get('v.showSetupComponent')
            });
          }

          //Not Authorized but contains only esign load the esign admin experience
          else if (!isPlatformAuthorized &&
            eSignFound &&
            !clmFound &&
            !genFound &&
            !negotiateFound) {
            helper.createComponent('setupContent', component, 'c:SetupWizard', {
              login: component.get('v.login'),
              products: component.get('v.products'),
              showSetupSpinner: component.get('v.showSetupSpinner'),
              showSetupComponent: component.get('v.showSetupComponent')
            });
          }

          //Not Authorized and contains either gen, clm , negotiate
          else if (!isPlatformAuthorized && (eSignFound || genFound || negotiateFound)) {
            helper.createComponent('setupContent', component, 'c:Login',
              {
                beginOAuth: component.get('v.beginOAuth'),
                beginSpringOAuth: component.get('v.beginSpringOAuth'),
                login: component.get('v.login')
              }
            );
          }
        }))
        .catch(function (error) {
          helper.showToast(component, error, 'error');
        });
    }
  },

  createComponent: function (anchor, component, componentName, attributes) {
    $A.createComponent(
      componentName,
      attributes,
      $A.getCallback(function (componentBody) {
          if (component.isValid()) {
            var targetCmp = component.find(anchor);
            var body = targetCmp.get('v.body');
            targetCmp.set('v.body', []);
            body.push(componentBody);
            targetCmp.set('v.body', body);
            var showSetupComponent = component.get('v.showSetupComponent');
            showSetupComponent();
          }
        }
      ));
  },

  showToast: function (component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.set('v.showToast', true);
  },

  hideToast: function (component) {
    component.find('toast').close();
  },

  fetchAccountProducts: function (component) {
    var getProductsAction = component.get('c.getProductsOnAccount');
    return new Promise($A.getCallback(function (resolve, reject) {
      getProductsAction.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      }));
      $A.enqueueAction(getProductsAction);
    }));
  },

  triggerLogout: function (component, event, helper) {
    var showSetupSpinner = component.get('v.showSetupSpinner');
    showSetupSpinner();
    helper.logout(component)
      .then($A.getCallback(function () {
          helper.getState(component, event, helper);
        }
      ))
      .catch($A.getCallback(function (error) {
        var showSetupComponent = component.get('v.showSetupComponent');
        showSetupComponent();
        helper.showToast(component, error, 'error');
      }));
  },

  logout: function (component) {
    var logoutAction = component.get('c.logout');
    logoutAction.setParams({
      resetUsers: true
    });
    return new Promise($A.getCallback(function (resolve, reject) {
      logoutAction.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var loginInformation = response.getReturnValue();
          resolve(loginInformation);
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(logoutAction);
    }));
  }
});
