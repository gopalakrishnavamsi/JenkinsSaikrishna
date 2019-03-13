({
    onInit: function (component, event, helper) {
        var agreementDetails = { name: "FreshSoftware-Quote.docx", url: "https://sampleUrl/001S000000x824BIAQ" };
        component.set('v.agreementDetails', agreementDetails);
    },

    copyButtonClicked: function (component, event, helper) {
        component.set('v.linkCopied', true);
    }
})
