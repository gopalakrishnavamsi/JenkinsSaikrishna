({
  EXPORT_DOCUMENT: 'Export Gen Document',

  initDocumentGenerator: function (component) {
    component.set('v.loading', true);
    var products = component.get('v.products');
    var isExpired = false;
    var isActive = false;
    var self = this;
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
      component.set('v.errMsg', $A.get('$Label.c.GenTrialExpired'));
    } else if (!isActive) {
      component.set('v.loading', false);
      component.set('v.errMsg', $A.get('$Label.c.GenNotConfigured'));
    } else {
      self.invokeAction(component, component.get('c.verifyDocuSignGenerator'), {},
        function (isGenerator) {
          if (isGenerator === true) {
            var renderOnlineEditorGenerator = component.get('v.renderOnlineEditorGenerator');
            renderOnlineEditorGenerator().then($A.getCallback(function (isGenerated) {
              component.set('v.loading', false);
              component.set('v.isButtonEnabled', isGenerated);
            })).catch($A.getCallback(function (err) {
              component.set('v.loading', false);
              component.set('v.errMsg', err);
            }));
          }
        }
      );
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

  processDownloadAsWordFile: function (component) {
    var self = this;
    var fileBytes;
    var scmDocGuid;
    var exportGeneratedDocument = component.get('v.exportGeneratedDocument');
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
    self.getFileName(component);
    exportGeneratedDocument().then(function (htmlData) {
      fileBytes = htmlData;
      return self.getEOSFolderId(component);
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
    })).then(function (response) {
      if (!response || !response.Href) throw $A.get('$Label.c.SCMHrefUndefined');
      scmDocGuid = response.Href.substring(response.Href.lastIndexOf('/') + 1);
      return self.convertDocument(component, scmDocGuid);
    }).then($A.getCallback(function () {
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
      if (scmDocGuid) {
        self.deleteDocument(component, scmDocGuid);
      }
      component.set('v.isButtonEnabled', true);
      self.setLoading(component, false);
    }));
  },

  getEOSFolderId: function (component) {
    var self = this;
    return new Promise($A.getCallback(function (resolve, reject) {
      self.invokeChainAction(component, component.get('c.getEOSFolderId'),
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

  deleteDocument: function (component, scmDocumentId) {
    this.invokeChainAction(component, component.get('c.deleteDocument'),
      {
        documentId: scmDocumentId
      }
    );
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
