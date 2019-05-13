({

  rename: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.Agreement');
  	actions.rename(agreement, component);

  },

  delete: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.Agreement');
  	actions.delete(agreement, component);
  },

  internalReview: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.Agreement');
  	actions.internalReview(agreement, component);
  },

  externalReview: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.Agreement');
  	actions.externalReview(agreement, component);
  },

  upload: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.Agreement');
  	actions.upload(component);
  },

  share: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.Agreement');
  	actions.share(agreement, component);
  }
  
});