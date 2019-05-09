({

  handleToolbarAction: function(component, event, helper) {
  	var actions = component.get('v.AgreementActionManager');
  	var agreement = component.get('v.agreement');
  	var selectedAction = event.target.getAttribute('data-sfid');
  	switch(selectedAction) {
  		case 'Rename':
  			actions.rename(agreement);
  			break;
  		case 'Delete':
  			actions.delete(agreement);	
  			break;
  		case 'InternalReview':
  			actions.internalReview(agreement);
  			break;
  		case 'ExternalReview':
  			actions.externalReview(agreement);
  			break;
  		case 'upload':
  			actions.upload();
  			break;	
  	}
  }
  
});