({
    close: function (component, event, helper) {
        component.destroy();
    },

    showToast: function (component, message, mode) {
        var evt = component.getEvent('toastEvent');
        evt.setParams({
            show: true, message: message, mode: mode
        });
        evt.fire();
    },

    setLoading: function (component, loading) {
        component.set('v.loading', loading === true);
    },

    getSalesforceFiles: function (component) {
        var self = this;
        self.setLoading(component, true);
        var getSalesforceFiles = component.get('c.getLinkedDocuments');
        getSalesforceFiles.setParams({
            sourceId: component.get('v.recordId')
        });
        getSalesforceFiles.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                var result = response.getReturnValue();
                // Add front-end properties to documents
                if (!$A.util.isEmpty(result)) {
                    result.forEach(function (d) {
                        self.addDocumentProperties(d, false);
                    });
                }
                component.set('v.salesforceFiles', result);
            } else {
                self.showToast(component, self.getErrorMessage(response), 'error');
            }
            self.setLoading(component, false);
            component.set('v.currentStep', '2');
        });

        $A.enqueueAction(getSalesforceFiles);
    },

    addDocumentProperties: function (doc, selected) {
        if (!!doc) {
            doc.selected = !!selected;
            doc.formattedSize = !!doc.size ? stringUtils.formatSize(doc.size) : '';
            doc.formattedLastModified = !!doc.lastModified ? new Date(doc.lastModified).toLocaleString() : '';
        }
        return doc;
    },
})
