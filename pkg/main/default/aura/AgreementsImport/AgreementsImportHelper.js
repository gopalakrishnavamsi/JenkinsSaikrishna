({
  initialize: function (component) {
    component.set('v.currentStep', '1');
    component.set('v.disableSalesforceFileImport', true);
  },

  fetchSalesforceFiles: function (component, event, helper) {
    component.set('v.currentStep', '2');
    component.set('v.loading', true);
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
            helper.addDocumentProperties(d, false);
          });
        }
        var fileSelection = result.filter(function (file) {
          var fileExtension = file.extension.toLowerCase();
          return fileExtension === 'pdf' || fileExtension === 'docx';
        });
        component.set('v.salesforceFiles', fileSelection);
      } else {
        helper.showToast(component, helper.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    });

    $A.enqueueAction(getSalesforceFiles);
  },

  setupFileUploadWidget: function (component, event, helper) {
    component.set('v.currentStep', '3');
    component.set('v.loading', true);
    var sourceId = component.get('v.recordId');
    var limitedAccessToken = component.get('c.generateUploadToken');
    limitedAccessToken.setParams({
      objectId: sourceId
    });
    limitedAccessToken.setCallback(this, function (response) {
      var state = response.getState();
      var result = response.getReturnValue();
      if (state === 'SUCCESS') {
        try {
          var options = {
            iconPath: $A.get('$Resource.scmwidgetsspritemap'),
            accessTokenFn: function () {
              return new Promise(function (resolve, reject) {
                limitedAccessToken.setCallback(this, function (response2) {
                  var state2 = response2.getState();
                  if (state2 === 'SUCCESS') {
                    resolve(response2.getReturnValue().token);
                  } else if (state2 === 'ERROR') {
                    reject(response2.getError());
                  }
                });
                $A.enqueueAction(limitedAccessToken);
              });
            },
            apiBaseDomain: result.apiUploadBaseUrl,
            accountId: result.accountId.value,
            allowedFileTypes: ['.pdf', '.docx']
          };
          var uploadWidget = new SpringCM.Widgets.Upload(options);
          uploadWidget.render('#upload-wrapper');
          component.set('v.widget', uploadWidget);
          component.set('v.entityId', result.entityId);
          component.set('v.loading', false);
        } catch (error) {
          helper.showToast(component, error, 'error');
          component.set('v.loading', false);
        }
      } else {
        component.set('v.loading', false);
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(limitedAccessToken);
  },

  importSalesforceFile: function (component, event, helper) {
    component.set('v.currentStep', '4');
    component.set('v.loading', true);
    component.set('v.uploadCompleteMessage', $A.get('$Label.c.SalesforceFileCopyComplete'));

    //get selected file
    var salesforceFiles = component.get('v.salesforceFiles');
    var selectedFile;
    salesforceFiles.forEach(function (file) {
      if (file.selected) {
        selectedFile = file;
      }
    });
    if (selectedFile) {
      var recordId = component.get('v.recordId');
      var action = component.get('c.createAgreementInEOSFolder');
      action.setParams({
        sfContentVersionId: selectedFile.sourceId,
        sourceObjectId: recordId,
        documentName: selectedFile.name + '.' + selectedFile.extension
      });
      action.setCallback(this, function (response) {
        if (response.getState() === 'SUCCESS') {
          var result = response.getReturnValue();
          if (result.status === 'Success') {
            //TODO: return uploaded file from Controller
            var importedFile = {
              name: selectedFile.name + '.' + selectedFile.extension,
              formattedSize: selectedFile.formattedSize,
              extension: selectedFile.extension
            };
            helper.displayCreatedAgreement(component, importedFile);
            helper.getAgreementDetails(result.agreementId.value, component);
          } else if (result.status === 'Processing') {
            helper.showToast(component, result.message, 'warning');
            helper.reloadAgreementsSpace(component);
            helper.close(component);
          } else {
            helper.showToast(component, result.message, 'error');
            helper.reloadAgreementsSpace(component);
            helper.close(component);
          }
        } else {
          helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        }
        component.set('v.loading', false);
      });
      $A.enqueueAction(action);
    }
  },

  getAgreementDetails: function (agreementId, component) {
    var action = component.get('c.getAgreement');
    action.setParams({
      agreementId: agreementId
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        component.set('v.agreementDetails', response.getReturnValue());
      } else if (state === 'ERROR') {
        this.showToast(component, 'Failed to get agreement details', 'error');
      }
    });
    $A.enqueueAction(action);
  },

  importFileFromPc: function (component, event, helper) {
    component.set('v.currentStep', '4');
    component.set('v.loading', true);
    component.set('v.uploadCompleteMessage', $A.get('$Label.c.UploadFileComplete'));
    var widget = component.get('v.widget');
    var folderId = component.get('v.entityId');
    try {
      widget
        .uploadNewDocument(folderId.value)
        .then(function (response) {
          var agreementId = helper.parseAgreementId(response.DownloadDocumentHref);
          var importedFile = {
            name: response.Name,
            formattedSize: response.NativeFileSize
              ? stringUtils.formatSize(response.NativeFileSize)
              : '',
            extension: 'docx',
            agreementId: agreementId
          };
          helper.displayCreatedAgreement(component, importedFile);
          helper.getAgreementDetails(agreementId, component);
        })
        .catch(function () {
          helper.showToast(component, 'Error Uploading File', 'error');
          helper.completeImport(component, event, helper);
        });
    } catch (error) {
      helper.showToast(component, 'Error Uploading File', 'error');
      helper.completeImport(component, event, helper);
    }
  },

  parseAgreementId: function (documentHref) {
    return documentHref.substring(documentHref.lastIndexOf('/') + 1);
  },

  displayCreatedAgreement: function (component, importedFile) {
    component.set('v.importedFile', importedFile);
    component.set('v.loading', false);
  },

  setSelectedFiles: function (component, selectedValue) {
    var salesforceFiles = component.get('v.salesforceFiles');
    salesforceFiles.forEach(function (file) {
      file.selected = file.sourceId === selectedValue;
    });
    component.set('v.salesforceFiles', salesforceFiles);
    component.set('v.disableSalesforceFileImport', false);
  },

  completeImport: function (component, event, helper) {
    helper.reloadAgreementsSpace(component);
    helper.close(component);
  },

  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  },

  reloadAgreementsSpace: function (component) {
    var reloadEvent = component.getEvent('loadingEvent');
    reloadEvent.setParams({
      isLoading: true
    });
    reloadEvent.fire();
  },

  addDocumentProperties: function (doc, selected) {
    if (doc) {
      doc.selected = selected;
      doc.formattedSize = doc.size ? stringUtils.formatSize(doc.size) : '';
      doc.formattedLastModified = doc.lastModified
        ? new Date(doc.lastModified).toLocaleString()
        : '';
    }
    return doc;
  },

  navigateToSendForSignature: function (component, event, helper) {
    component.set('v.isSendingForSignature', true);
    var salesforceFiles = component.get('v.salesforceFiles');
    var selectedFileId;
    salesforceFiles.forEach(function (file) {
      if (file.selected) {
        selectedFileId = file.sourceId;
      }
    });
    var isSalesforceFileAvailable = !$A.util.isUndefinedOrNull(selectedFileId);
    if (isSalesforceFileAvailable) {
      helper.sendForSignature(component, selectedFileId);
    } else {
      helper.exportFileAndSend(component, event, helper);
    }
  },

  sendForSignature: function (component, selectedFileId) {
    var helper = this;
    component.set('v.loading', true);
    var sendingAction = component.get('c.getSendingDeepLink');
    var sourceId = component.get('v.recordId');
    sendingAction.setParams({
      sourceId: sourceId,
      fileIdsInCommaSeparated: selectedFileId
    });
    sendingAction.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        navUtils.navigateToUrl(response.getReturnValue());
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(sendingAction);
  },

  exportFileAndSend: function (component, event, helper) {
    component.set('v.loading', true);
    var agreementId = component.get('v.importedFile').agreementId;
    var sourceId = component.get('v.recordId');
    var exportSalesforceAction = component.get('c.exportAgreementToSalesforce');
    exportSalesforceAction.setParams({
      sourceId: sourceId,
      agreementId: agreementId
    });
    exportSalesforceAction.setCallback(this, function (response) {
      component.set('v.loading', false);
      if (response.getState() === 'SUCCESS') {
        helper.sendForSignature(component, '');
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(exportSalesforceAction);
  }
});
