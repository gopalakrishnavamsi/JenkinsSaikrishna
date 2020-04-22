({
  EXPORT_DOCUMENT: 'Export Gen Document',

  initDocumentGenerator: function (component) {
    var permission = component.get('v.permission');
    var products = component.get('v.products');
    var isExpired = false;
    var isActive = false;
    var self = this;
    if (!permission.isDocuSignGenerator) {
      self.showToast(component, $A.get('$Label.c.MustBeDocuSignGenerator'), 'error');
      component.set('v.loading', false);
      return;
    }
    component.set('v.loading', true);
    if (!$A.util.isEmpty(products)) {
      for (var i = 0; i < products.length; i++) {
        var product = products[i];
        if (product.name === 'gen') {
          isActive = product.status === 'active';
          isExpired = product.isExpired;
          break;
        }
      }
    }
    component.set('v.isGenTrialExpired', isExpired);
    component.set('v.isGenEnabled', isActive);
    if (isExpired) {
      component.set('v.loading', false);
      self.showToast(component, $A.get('$Label.c.GenTrialExpired'), 'error');
    } else if (!isActive) {
      component.set('v.loading', false);
      self.showToast(component, $A.get('$Label.c.GenNotConfigured'), 'error');
    } else if (permission.isDocuSignGenerator) {
      var renderOnlineEditorGenerator = component.get('v.renderOnlineEditorGenerator');
      renderOnlineEditorGenerator().then($A.getCallback(function () {
        self.uploadFileToSCM(component);
      })).catch($A.getCallback(function (err) {
        self.showToast(component, err, 'error');
      })).finally($A.getCallback(function () {
        component.set('v.loading', false);
      }));
    }
  },

  parseError: function (response) {
    if (!response) return Promise.resolve($A.get('$Label.c.UnknownError'));

    if (response.json) {
      return new Promise(function (resolve, reject) {
        response.json()
          .then(function (body) {
            var hasError = body && body.Error;
            resolve(stringUtils.format($A.get('$Label.c.ApiError_3'),
              hasError && body.Error.HttpStatusCode ? body.Error.HttpStatusCode : 0,
              hasError && body.Error.UserMessage ? body.Error.UserMessage : $A.get('$Label.c.UnknownError'),
              hasError && body.Error.ReferenceId ? body.Error.ReferenceId : ''));
          })
          .catch(function (err) {
            reject(err);
          });
      });
    } else {
      return Promise.resolve(response);
    }
  },

  uploadFileToSCM: function (component) {
    var self = this;
    var fileBytes;
    var exportGeneratedDocument = component.get('v.exportGeneratedDocument');
    component.set('v.isButtonEnabled', false);
    component.set('v.showButtonSpinner', true);
    self.getFileName(component);
    exportGeneratedDocument().then(function (htmlData) {
      fileBytes = htmlData;
      return self.getTempEOSFolderId(component);
    }).then($A.getCallback(function (folderId) {
      return self.getLimitedAccessToken(component, folderId.value);
    })).then($A.getCallback(function (uploadToken) {
      return SpringCM.Methods.Upload.uploadNewDocumentBytes(
        uploadToken.apiUploadBaseUrl,
        uploadToken.token,
        uploadToken.accountId.value,
        uploadToken.entityId.value,
        fileBytes,
        component.get('v.fileName') + '.html'
      );
    })).then($A.getCallback(function (response) {
      if (!response || !response.Href) throw $A.get('$Label.c.SCMHrefUndefined');
      var scmDocGuid = response.Href.substring(response.Href.lastIndexOf('/') + 1);
      component.set('v.scmFileGuid', scmDocGuid);
      component.set('v.isButtonEnabled', true);
    })).catch($A.getCallback(function (err) {
      self.parseError(err).then($A.getCallback(function (msg) {
        self.showToast(component, msg, 'error');
      }));
    })).finally($A.getCallback(function () {
      component.set('v.showButtonSpinner', false);
    }));
  },

  processDownloadAsWordFile: function (component) {
    var self = this;
    var scmDocGuid = component.get('v.scmFileGuid');
    self.timeEvent(component, self.EXPORT_DOCUMENT);
    self.addEventProperties(component, {
      'Product': 'Gen',
      'Template Type': 'Online Editor',
      'Format': 'docx',
      'Location': 'download'
    });
    self.hideToast(component);
    self.setLoading(component, true);
    component.set('v.isButtonEnabled', false);

    if (!$A.util.isUndefinedOrNull(scmDocGuid)) {
      self.convertDocument(component, scmDocGuid).then($A.getCallback(function () {
        return self.getLimitedAccessToken(component, scmDocGuid);
      })).then($A.getCallback(function (downloadToken) {
        return SpringCM.Widgets.Download.downloadDocument(
          downloadToken.apiDownloadBaseUrl,
          downloadToken.token,
          downloadToken.accountId.value,
          scmDocGuid,
          component.get('v.fileName') + '.docx',
          true,
          'Docx'
        );
      })).then(function () {
        self.trackSuccess(component, self.EXPORT_DOCUMENT);
      }).catch($A.getCallback(function (err) {
        self.parseError(err).then($A.getCallback(function (msg) {
          self.showToast(component, msg, 'error');
          self.trackError(component, self.EXPORT_DOCUMENT, {}, msg);
        }));
      })).finally($A.getCallback(function () {
        component.set('v.isButtonEnabled', true);
        self.setLoading(component, false);
      }));
    }
  },

  getTempEOSFolderId: function (component) {
    var self = this;
    return new Promise($A.getCallback(function (resolve, reject) {
      self.invokeChainAction(component, component.get('c.getTempEOSFolderId'),
        {
          sourceId: component.get('v.recordId')
        },
        function (folderId) {
          resolve(folderId);
        },
        function (err) {
          reject(err[0].message);
        }
      );
    }));
  },

  getLimitedAccessToken: function (component, entityGuid) {
    var self = this;
    return new Promise($A.getCallback(function (resolve, reject) {
      self.invokeChainAction(component, component.get('c.generateLimitedAccessToken'),
        {
          entityId: entityGuid
        },
        function (token) {
          resolve(token);
        },
        function (err) {
          reject(err[0].message);
        }
      );
    }));
  },

  convertDocument: function (component, scmDocumentId) {
    var self = this;
    return new Promise($A.getCallback(function (resolve, reject) {
      self.invokeChainAction(component, component.get('c.convertHtmlDocumentToWord'),
        {
          documentId: scmDocumentId
        },
        function (docGuid) {
          resolve(docGuid);
        },
        function (err) {
          reject(err[0].message);
        }
      );
    }));
  },

  deleteDocument: function (component) {
    var scmFileGuid = component.get('v.scmFileGuid');
    if (!$A.util.isUndefinedOrNull(scmFileGuid)) {
      this.invokeChainAction(component, component.get('c.deleteDocument'),
        {
          documentId: scmFileGuid
        }
      );
    }
  },

  getFileName: function (component) {
    var self = this;
    self.invokeChainAction(component, component.get('c.getFileName'),
      {
        templateId: component.get('v.templateId'),
        recordName: component.get('v.recordName')
      },
      function (fileName) {
        component.set('v.fileName', fileName.substring(0, 80));
      },
      function (err) {
        self.showToast(component, err[0].message, 'error');
      }
    );
  }
});
