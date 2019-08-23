({
  showToast: function(component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.set('v.showToast', true);
  },

  hideToast: function(component) {
    component.find('toast').close();
  },

  loadAgreements: function(component, event, helper) {
    component.set('v.loading', true);
    helper.setNameSpace(component, event, helper);
    helper.getAgreements(component, event, helper);
    component.set('v.isAgreementLoaded',true) ;
  },

  createImportComponent: function(component) {
    component.set('v.isAgreementLoaded',false);
    $A.createComponent(
      'c:AgreementsImport',
      {
        showModal: true,
        recordId: component.get('v.recordId')
      },
      function (componentBody) {
        if (component.isValid()) {
          var targetCmp = component.find('importModal');
          var body = targetCmp.get('v.body');
          targetCmp.set('v.body', []);
          body.push(componentBody);
          targetCmp.set('v.body', body);
        }
      }
    );
  },

  setNameSpace: function(component, event, helper) {
    //set the namespace attribute
    var action = component.get('c.getNameSpace');
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.namespace', response.getReturnValue());
        component.set('v.isDocuSignNegotiator', true);
      } else {
        var errorMessage = stringUtils.getErrorMessage(response);
        if (errorMessage === $A.get('$Label.c.MustBeDocuSignNegotiator')) {
          component.set('v.isDocuSignNegotiator', false);
        }
        helper.showToast(component, errorMessage, 'error');
      }
    });
    $A.enqueueAction(action);
  },

  getAgreements: function(component, event, helper) {
    component.set('v.loading', true);
    var recordId = component.get('v.recordId');
    var action = component.get('c.getAgreements');

    action.setParams({
      sourceObjectId: recordId
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.agreements', response.getReturnValue());
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  }
});
