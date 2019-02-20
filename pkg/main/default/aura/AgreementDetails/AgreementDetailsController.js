({
	init : function(component, event, helper) {
		var list= ['Signed by Cathy Customer on 10/26/2018',
				   'External review completed by Cathy Customer on 10/27/2018',
				   'Agreement created on 10/26/2018'];
        component.set("v.timelineDetails", list);
	},

    showTimeLine : function(component, event, helper) {
        var button = component.find("showActivityButton");
        var currentValue = component.get("v.showTimeLine");
        if (currentValue === false) {
            component.set("v.showTimeLine", true);
            button.set("v.label", "Hide Activity");
        }
        else {
            component.set("v.showTimeLine", false);
            button.set("v.label", "Show Activity");
        }
    },

	showInternalApprovalModal: function(component, event, helper) {
	    component.set('v.showSendForApprovalModal', true);
    },

    closeInternalApprovalModal: function(component, event, helper) {
        component.set('v.showSendForApprovalModal', false);
    },

    showExternalReviewModal: function(component, event, helper) {
        component.set('v.showSendForExternalReviewModal', true);
    },

    closeExternalReviewModal: function(component, event, helper) {
        component.set('v.showSendForExternalReviewModal', false);
    },

    showDeleteModal: function(component, event, helper) {
        component.set('v.showDeleteModal', true);
    },

    closeDeleteModal: function(component, event, helper) {
        component.set('v.showDeleteModal', false);
    }

})