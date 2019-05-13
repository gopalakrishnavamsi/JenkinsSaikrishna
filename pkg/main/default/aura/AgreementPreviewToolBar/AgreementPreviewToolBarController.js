({

  rename: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	actions.rename(agreement, component);

  },

  delete: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	actions.delete(agreement, component);
  },

  internalReview: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	actions.internalReview(agreement, component);
  },

  externalReview: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	actions.externalReview(agreement, component);
  },

  upload: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	actions.upload(component);
  },

  share: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	actions.share(agreement, component);
  }
  
});