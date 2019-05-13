({

  onLoad: function(component, event, helper) {
    var sourceId = component.get("v.sourceId");
    var agreementId = component.get("v.agreementId");
    var action = component.get('c.getNameSpace');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var manager = new AgreementActionManager('modalContent', response.getReturnValue());
        manager.getAgreement(agreementId, sourceId, component)
        .then(function(agreement) {
          component.set('v.Agreement', agreement);
          component.set('v.AgreementActionManager', manager);
          component.set('v.loading', false); 
        });   
      }
    });
    $A.enqueueAction(action);  
    component.set('v.SpringService', SpringCM.Widgets);  
  }

});