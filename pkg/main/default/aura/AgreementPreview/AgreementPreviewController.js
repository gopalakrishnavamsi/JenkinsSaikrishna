({

  handleInit: function(component, event, helper) {
    console.log('component.get("v.pageReference").state.agreementId');
    // var getAgreement = component.get('c.getAgreement');
    // getAgreement.setParams({
    //   id: component.get("v.pageReference").state.agreementId;
    // })
  },

  onLoad: function(component, event, helper) {
    component.set('v.SpringService', SpringCM.Widgets);
    component.set('v.AgreementActionManager', new AgreementActionManager('modalContent', component));
  }

});