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
    addRecipient: function (component, event, helper) {
        var recipients = component.get('v.recipients');
        recipients.push(helper.newRecipient());
        component.set('v.recipients', recipients);
    },
    removeRecipient: function (component, event, helper) {
        var recipients = component.get('v.recipients');
        recipients.splice(event.getSource().get('v.value'), 1);
        component.set('v.recipients', recipients);
    },
    onApproverDrag : function(component, event, helper) {
        if (event.currentTarget.id && parseInt(event.currentTarget.id) !== 'undefined') {
            component.set('v.draggedId', parseInt(event.currentTarget.id));
            console.log('dragged id '+parseInt(event.currentTarget.id));
        }
    },
    allowDrop :function(component, event, helper) {
        event.preventDefault();
    },
    onApproverDrop : function(component, event, helper) {
        if (event.currentTarget.id && parseInt(event.currentTarget.id) !== 'undefined') {
            component.set('v.droppedId', parseInt(event.currentTarget.id));
            console.log('dropped id '+parseInt(event.currentTarget.id));
        }

        var draggedId = component.get('v.draggedId');
        var droppedId = component.get('v.droppedId');
        var recipients = component.get('v.recipients');

        if(draggedId !== 'undefined'
            && droppedId !== 'undefined'
            && recipients !== 'undefined') {

            if(recipients[droppedId] !== 'undefined'
                && recipients[draggedId] !== 'undefined'
                && recipients[draggedId].name !== 'undefined'
                && recipients[draggedId].name !== ''
                && recipients[droppedId].name !== 'undefined'
                && recipients[droppedId].name !== '') {
                    var temp = recipients[draggedId];
                    recipients.splice(draggedId, 1);
                    recipients.splice(droppedId, 0, temp);
                    component.set('v.recipients', recipients);
                }
        }
        else {
            console.log('Entered else');
        }
    },

    setApprovalOrder: function(component, event, helper) {
        //set the attribute showApprovalOrder based on Checkbox value
        var isChecked = component.find('approvalOrderCheckbox').get('v.checked');
        component.set('v.showApprovalOrder', isChecked);
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
            helper.showToast(component, 'Your document has been sent for approval.', 'success')
        }
    }
})