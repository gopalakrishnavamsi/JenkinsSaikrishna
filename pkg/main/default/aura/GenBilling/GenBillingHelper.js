({
  initSetup : function(component, getResult) {
    var helper = this;
    var template = component.get('v.template');
    if(getResult > 0){
        template.hasAutomationExists = true;
    } else if($A.util.isEmpty(template.invoiceMappings)) {
        //defined invoice mapping attributes which needs to store on dynamic field on genTemplate object
        template.invoiceMappings = {
            isAutomateInvoice: false,
            sendEmail: false,
            emailSubject : 'Invoice Delivery',
            emailMessage : 'Please find attached the invoice for previous month.',
            emailAddresses: []
        };
       helper.setAutomateValidity(component, true);
    }
	component.set('v.template', template);
  },
    
  //updating validity on each selection of check boxes and email attributes
  setAutomateValidity: function(component, value) {
	var template = component.get('v.template');
	template.hasAutomateValidity = value;
	component.set('v.template', template);
  },

  //checking email Subject, Message and recipients are selected or not
  setSendEmailValidity: function(component) {
    var helper = this;
	var template = component.get('v.template.invoiceMappings');
    helper.setAutomateValidity(component, !(!$A.util.isEmpty(template.emailSubject)
                                            && !$A.util.isEmpty(template.emailMessage)
                                            && !$A.util.isEmpty(template.emailAddresses)));                             
  },
    
  callServer: function (component, method, param, callback) {
    var action = component.get(method);
    if (param) {
        action.setParams(param);
    }
    action.setCallback(this, callback);
    $A.enqueueAction(action);
  },
    
  showToast: function (component, msg, variant) {
    var evt = component.getEvent('showToast');
    evt.setParams({
      data: {
        msg: msg,
        variant: variant
      }
    });
    evt.fire();
  },
})