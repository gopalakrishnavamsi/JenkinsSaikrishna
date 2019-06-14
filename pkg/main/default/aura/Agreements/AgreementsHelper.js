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
  },

  createImportComponent: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      actions.import(component.get('v.recordId'), component);
    } catch (err) {
      this.showToast(component, err, 'error');
    }
  },

  setNameSpace: function(component, event, helper) {
    //set the namespace attribute
    var action = component.get('c.getNameSpace');
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.namespace', response.getReturnValue());
        var manager = new AgreementActionManager(
          'importModal',
          response.getReturnValue()
        );
        component.set('v.agreementActionManager', manager); 
      } else if (state === 'ERROR') {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
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
      } else if (state === 'ERROR') {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        helper.showToast(component, errorMessage, 'error');
      }
      component.set('v.loading', false);
    });
    $A.enqueueAction(action);
  }
});
