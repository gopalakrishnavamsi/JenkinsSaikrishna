({
  onLoad: function(component) {
    var manager = new AgreementActionManager(
      'importActionContainer',
      component.get('v.namespace')
    );
    component.set('v.agreementActionManager', manager);  
  },

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
  },

  pcFileImportTriggered: function (component, event, helper) {
    helper.importFileFromPc(component, event, helper);
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

  sendApproval: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      var sourceId = component.get('v.recordId');
      actions.internalApproval(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  sendExternalReview: function(component) {
    try {
      var actions = component.get('v.agreementActionManager');
      var agreement = component.get('v.agreementDetails');
      var sourceId = component.get('v.recordId');
      actions.externalReview(agreement, sourceId, component);
    } catch (err) {
      var uiHelper = component.get('v.uiHelper');
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  }

});
