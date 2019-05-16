({
  initialize: function (component) {
    component.set('v.currentStep', '1');
    component.set('v.disableSalesforceFileImport', true);
  },

  uploadFilesFromPC: function (component, event, helper) {
    component.set('v.currentStep', '3');
    helper.uploadFile(component);
  },

  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  setLoading: function (component, loading) {
    component.set('v.loading', loading === true);
  },

  reloadAgreementsSpace: function (component) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: true
    });
    evt.fire();
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
    if (doc) {
      doc.selected = selected;
      doc.formattedSize = doc.size ? stringUtils.formatSize(doc.size) : '';
      doc.formattedLastModified = doc.lastModified
        ? new Date(doc.lastModified).toLocaleString()
        : "";
    }
    return doc;
  },

  uploadFile: function (component) {
    var self = this;
    self.setLoading(component, true);
    var sourceId = component.get('v.recordId');
    var limitedAccessToken = component.get('c.generateUploadToken');
    limitedAccessToken.setParams({
      objectId: sourceId
    });
    limitedAccessToken.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        try {
          var options = {
            iconPath: $A.get('$Resource.scmwidgetsspritemap'),
            accessTokenFn: function () {
              return new Promise((resolve, reject) => {
                limitedAccessToken.setCallback(this, function (response) {
                  var state = response.getState();
                  if (state === 'SUCCESS') {
                    resolve(response.getReturnValue().token);
                  } else if (state === 'ERROR') {
                    reject(response.getError());
                  }
                });
                $A.enqueueAction(limitedAccessToken);
              });
            },
            apiBaseDomain: result.apiBaseUrl,
            accountId: result.accountId.value
          };
          var uploadWidget = new SpringCM.Widgets.Upload(options);
          uploadWidget.render('#upload-wrapper');
          component.set('v.widget', uploadWidget);
          component.set('v.entityId', result.entityId);
          self.setLoading(component, false);
        } catch (error) {
          self.showToast(component, error, 'error');
          self.setLoading(component, false);
        }
      } else {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        self.setLoading(component, false);
        self.showToast(component, errorMessage, 'error');
      }
    });
    $A.enqueueAction(limitedAccessToken);
  },

  uploadContent: function (component, event, helper) {
    component.set('v.loading', true);
    var widget = component.get('v.widget');
    var folderId = component.get('v.entityId');
    try {
      widget
        .uploadNewDocument(folderId.value)
        .then(function (response) {
          helper.showToast(component, 'File uploaded successfully', 'success');
          helper.completeImport(component, event, helper);
        })
        .catch(function (error) {
          helper.showToast(component, 'Error Uploading File', 'error');
          helper.completeImport(component, event, helper);
        });
    } catch (error) {
      helper.showToast(component, 'Error Uploading File', 'error');
      helper.completeImport(component, event, helper);
    }
  },

  publishAgreement: function (component, event, helper) {
    var self = this;
    //set loading to true
    self.setLoading(component, true);

    //get selected file
    var salesforceFiles = component.get('v.salesforceFiles');
    var selectedFile;
    salesforceFiles.forEach(function (file) {
      if (file.selected) {
        selectedFile = file;
      }
    });

    var recordId = component.get('v.recordId');
    var action = component.get('c.createAgreementInEOSFolder');
    action.setParams({
      sfContentVersionId: selectedFile.sourceId,
      sourceObjectId: recordId,
      documentName: selectedFile.name
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result.status === 'Success') {
          //TODO: return uploaded file from Controller
          var importedFile = {
            name: selectedFile.name,
            formattedSize: selectedFile.formattedSize,
            extension: selectedFile.extension
          };
          component.set('v.importedFile', importedFile);
          component.set('v.currentStep', "4");
          self.setLoading(component, false);
        } else if (result.status === 'Processing') {
          self.showToast(component, result.message, 'warning');
          self.reloadAgreementsSpace(component);
          self.close(component);
        } else {
          self.showToast(component, result.message, 'error');
          self.reloadAgreementsSpace(component);
          self.close(component);
        }
      } else if (state === 'ERROR') {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        self.showToast(component, errorMessage, 'error');
      }
      self.setLoading(component, false);
    });
    $A.enqueueAction(action);
  },

  setSelectedFiles: function (component, selectedValue) {
    var salesforceFiles = component.get('v.salesforceFiles');
    salesforceFiles.forEach(function (file) {
      if (file.sourceId === selectedValue) {
        file.selected = true;
      } else {
        file.selected = false;
      }
    });
    component.set('v.salesforceFiles', salesforceFiles);
    component.set('v.disableSalesforceFileImport', false);
  },

  completeImport: function (component, event, helper) {
    helper.reloadAgreementsSpace(component);
    helper.close(component);
  }
});
