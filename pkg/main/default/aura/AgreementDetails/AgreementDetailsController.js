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
	    helper.createInternalApprovalComponent(component, event, helper);
    },

    showExternalReviewModal: function(component, event, helper) {
        helper.createExternalReviewComponent(component, event, helper);
    },

    showDeleteModal: function(component, event, helper) {
        helper.createDeleteComponent(component, event, helper);
    },

    showUploadModal: function(component, event, helper) {
        helper.createUploadComponent(component, event, helper);
    }
})