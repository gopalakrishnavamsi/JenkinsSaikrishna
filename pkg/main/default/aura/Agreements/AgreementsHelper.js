({
	showToast: function (component, message, mode) {
        component.set('v.message', message);
        component.set('v.mode', mode);
        component.set('v.showToast', true);
    },

	hideToast: function (component) {
        component.find('toast').close();
    },

    createImportComponent: function(component, event, helper) {
        $A.createComponent(
            "c:AgreementsImport",
            {
                "showModal" : true,
                "recordId" : component.get('v.recordId')
            },
            function(componentBody) {
                if(component.isValid()) {
                    var targetCmp = component.find('importModal');
                    var body = targetCmp.get("v.body");
                    targetCmp.set("v.body", []);
                    body.push(componentBody);
                    targetCmp.set("v.body", body);
                }
            }
        );
    }
})