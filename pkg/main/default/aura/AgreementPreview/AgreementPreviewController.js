({

  onLoad: function(component, event, helper) {
    var sourceId = component.get("v.sourceId");
    var agreementId = component.get("v.agreementId");
    var action = component.get('c.getNameSpace');
    var uiHelper = new UIHelper(function () {
      return component.getEvent('loadingEvent');
    }, function () {
      return component.getEvent('toastEvent');
    });
    component.set('v.uiHelper', uiHelper);    
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var manager = new AgreementActionManager('modalContent', response.getReturnValue());
        manager.getAgreement(agreementId, sourceId, component)
        .then(function(agreement) {
          component.set('v.agreement', agreement);
          component.set('v.agreementActionManager', manager);
          component.set('v.loading', false); 
        }).catch(function(error) {
          uiHelper.showToast(uiHelper.ToastMode.ERROR, error);
        });   
      }
      else if (state === "ERROR") uiHelper.showToast(uiHelper.ToastMode.ERROR, uiHelper.getErrorMessage(response));
    });
    $A.enqueueAction(action);  
  }

});