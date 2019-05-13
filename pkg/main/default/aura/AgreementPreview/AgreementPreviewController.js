({

  handleInit: function(component, event, helper) {
    if (component.get('v.isClassic')) {
      //Centering for Lighting Application Tabs
      //setTimeout(() => window.scrollTo(10, 10), 100);
    }
    console.log('Landed in Init');
  },

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