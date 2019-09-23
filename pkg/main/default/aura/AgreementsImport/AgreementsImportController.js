({
  initialize: function (component, event, helper) {
    helper.initialize(component);
  },

  initializeSalesforceFileImport: function (component, event, helper) {
    helper.fetchSalesforceFiles(component, event, helper);
  },

  initializePcFileImport: function (component, event, helper) {
    helper.setupFileUploadWidget(component, event, helper);
  },

  salesforceFileImportTriggered: function (component, event, helper) {
    helper.importSalesforceFile(component, event, helper);
    helper.isEsignEnabled(component);
  },

  pcFileImportTriggered: function (component, event, helper) {
    helper.importFileFromPc(component, event, helper);
    helper.isEsignEnabled(component);
  },

  salesforceFileCheckboxToggle: function (component, event, helper) {
    //checkbox checked
    if (event.getSource().get('v.checked')) {
      var selectedValue = event.getSource().get('v.value');
      helper.setSelectedFiles(component, selectedValue);
    }
    //checkbox unchecked
    else {
      component.set('v.disableSalesforceFileImport', true);
    }
  },

  doneButtonClicked: function (component, event, helper) {
    helper.completeImport(component, event, helper);
  },

  navigateToFirstStep: function (component) {
    component.set('v.currentStep', '1');
  },

  cancelButtonClicked: function (component, event, helper) {
    helper.close(component);
  },

  backButtonClicked: function (component) {
    component.set('v.currentStep', '1');
  },

  createInternalApprovalComponent: function (component) {
    var agreementDetails = component.get('v.agreementDetails');
    $A.createComponent(
      'c:AgreementsInternalApproval',
      {
        showModal: true,
        agreementDetails: agreementDetails,
        sourceId: component.get('v.recordId')
      },
      function (componentBody) {
        if (component.isValid()) {
          component.set('v.showModal', false);
          var targetCmp = component.find('internalApprovalModal');
          var body = targetCmp.get('v.body');
          targetCmp.set('v.body', []);
          body.push(componentBody);
          targetCmp.set('v.body', body);
        }
      }
    );
  },

  createExternalReviewComponent: function (component) {
    var agreementDetails = component.get('v.agreementDetails');
    $A.createComponent(
      'c:AgreementsExternalReview',
      {
        showModal: true,
        agreementDetails: agreementDetails,
        sourceId: component.get('v.recordId')
      },
      function (componentBody) {
        if (component.isValid()) {
          component.set('v.showModal', false);
          var targetCmp = component.find('externalReviewModal');
          var body = targetCmp.get('v.body');
          targetCmp.set('v.body', []);
          body.push(componentBody);
          targetCmp.set('v.body', body);
        }
      }
    );
  },

  navigateToSendForSignature: function (component,event,helper) {
    helper.navigateToSendForSignature(component);
  }
});
