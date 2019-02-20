({
    onInit: function(component, event, helper) {
        //initialize recipients
        var recipients = component.get('v.recipients');
        recipients.push(helper.newRecipient());
        component.set('v.recipients', recipients);

        //set the current step to 1
        component.set('v.currentStep', '1');
    },
    handleRecipientChange: function (component, event, helper) {
        helper.resolveRecipient(component, event.getParam('data'));
    },
    backButtonClicked: function(component, event, helper) {
        var currentStep = component.get('v.currentStep');

        //currentStep is Select Recipients
        if (currentStep === '1') {
            helper.hide(component, event, helper);
        }

        //currentStep is Edit your Message then direct user back to Select Recipients screen
        if (currentStep === '2') {
            component.set('v.currentStep', '1');
        }

    },

    nextButtonClicked: function(component, event, helper) {
        var currentStep = component.get('v.currentStep');

        if (currentStep === '1') {
            //Proceed to the personalize message step
            component.set('v.currentStep', '2');
        }

        if (currentStep === '2') {
            //If successful hide the component
            helper.hide(component, event, helper);

            //set the current step to 1
            component.set('v.currentStep', '1');

            //display toast notification
            helper.showToast(component, 'Your document has been sent for review and copied to the DocuSign Agreements space', 'success')
        }
    }
})