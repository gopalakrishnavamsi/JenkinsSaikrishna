({
  onInitialize: function (component, event, helper) {
      helper.callServer(component, 'c.invoiceAutomationExists', {},
      function (response) {
        if (response.getState() === 'SUCCESS') {
        	helper.initSetup(component, response.getReturnValue());
        } else {
          helper.showToast(component, stringUtils.getErrorMessage(response) , 'error');
        }
      });
  },
    
  setAutomateInvoice: function(component,event,helper) {
    helper.setAutomateValidity(component, !component.find('automate-invoice').get('v.checked'));
    var template = component.get('v.template.invoiceMappings');
      template.sendEmail= false;
      template.emailAddresses = [];
	component.set('v.template.invoiceMappings',template);
  },
    
  setInvoicebyEmail: function(component,event,helper) {  
	if(!component.find('send-invoice').get('v.checked')) {
        helper.setAutomateValidity(component, false);
    } else {
		helper.setSendEmailValidity(component);
    }
  },
    
  saveRecipient: function (component,event,helper) {
	component.set('v.template.invoiceMappings.emailAddresses', event.getParam('recipientslist'));
	helper.setSendEmailValidity(component);
  },
    
  setEmailValidity: function (component,event,helper) {
	helper.setSendEmailValidity(component);
  },
    
  validate: function () {
    return new Promise(
      $A.getCallback(function (resolve) {
        resolve();
        })
      );
  }
})