({
    createUploadComponent: function(component, event, helper) {
        $A.createComponent(
            "c:AgreementsUpload",
            {
                "showModal" : true,
            },
            function(componentBody) {
                if(component.isValid()) {
                    var targetCmp = component.find('uploadModal');
                    var body = targetCmp.get("v.body");
                    targetCmp.set("v.body", []);
                    body.push(componentBody);
                    targetCmp.set("v.body", body);
                }
            }
        );
    },

    createDeleteComponent: function(component, event, helper) {
        $A.createComponent(
            "c:DeleteAgreement",
            {
                "showModal" : true,
            },
            function(componentBody) {
                if(component.isValid()) {
                    var targetCmp = component.find('deleteModal');
                    var body = targetCmp.get("v.body");
                    targetCmp.set("v.body", []);
                    body.push(componentBody);
                    targetCmp.set("v.body", body);
                }
            }
        );
    },

    createInternalApprovalComponent: function(component, event, helper) {
        $A.createComponent(
            "c:AgreementsInternalReview",
            {
                "showModal" : true,
            },
            function(componentBody) {
                if(component.isValid()) {
                    var targetCmp = component.find('internalApprovalModal');
                    var body = targetCmp.get("v.body");
                    targetCmp.set("v.body", []);
                    body.push(componentBody);
                    targetCmp.set("v.body", body);
                }
            }
        );
    },

    createExternalReviewComponent: function(component, event, helper) {
        $A.createComponent(
            "c:AgreementsExternalReview",
            {
                "showModal" : true,
            },
            function(componentBody) {
                if(component.isValid()) {
                    var targetCmp = component.find('externalReviewModal');
                    var body = targetCmp.get("v.body");
                    targetCmp.set("v.body", []);
                    body.push(componentBody);
                    targetCmp.set("v.body", body);
                }
            }
        );
    }
})