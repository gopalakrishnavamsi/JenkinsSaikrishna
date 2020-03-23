({
  DOWNLOAD_AS_WORD: 'Agreement Cloud Editor Download as Word',

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
            renderOnlineEditorGenerator().then(function (isGenerated) {
              component.set('v.loading', false);
              component.set('v.isButtonEnabled', isGenerated);
            }).catch(function (err) {
              component.set('v.loading', false);
              component.set('v.errMsg', err);
            });
          }
        }
      );
    }
  },

  processDownloadAsWordFile: function (component) {
    var self = this;
    var fileBytes;
    var scmDocGuid;
    var exportGeneratedDocument = component.get('v.exportGeneratedDocument');
    var fileName = stringUtils.format('{0}{1}{2}', component.get('v.title'), '_', component.get('v.recordName'));
    fileName = fileName.substring(0, 80);
    var eventParams = {
      'Product': 'Gen',
      'Template Type': 'Online Editor'
    };
    self.timeEvent(component, self.DOWNLOAD_AS_WORD);
    self.addEventProperties(component, eventParams);

    self.hideToast(component);
    self.setLoading(component, true);
    component.set('v.isButtonEnabled', false);
    exportGeneratedDocument().then(function (htmlData) {
      fileBytes = htmlData;
      return self.getEOSFolderId(component);
    }).then(function (folderId) {
      return self.getLimitedAccessToken(component, folderId.value);
    }).then(function (uploadToken) {
      return SpringCM.Methods.Upload.uploadNewDocumentBytes(
        uploadToken.apiUploadBaseUrl,
        uploadToken.token,
        uploadToken.accountId.value,
        uploadToken.entityId.value,
        fileBytes,
        stringUtils.format('{0}{1}', fileName, '.html')
      );
    }).then(function (response) {
      if (!response || !response.Href) throw $A.get('$Label.c.SCMHrefUndefined');
      scmDocGuid = response.Href.substring(response.Href.lastIndexOf('/') + 1);
      return self.convertDocument(component, scmDocGuid);
    }).then(function () {
      return self.getLimitedAccessToken(component, scmDocGuid);
    }).then(function (downloadToken) {
      return SpringCM.Widgets.Download.downloadDocument(
        downloadToken.apiDownloadBaseUrl,
        downloadToken.token,
        downloadToken.accountId.value,
        scmDocGuid,
        stringUtils.format('{0}{1}', fileName, '.docx'),
        true,
        'Docx'
      );
    }).then(function () {
      self.trackSuccess(component, self.DOWNLOAD_AS_WORD, eventParams);
    }).catch(function (err) {
      self.showToast(component, err, 'error');
      self.trackError(component, self.DOWNLOAD_AS_WORD, eventParams, err);
    }).finally(function () {
      if (scmDocGuid) {
        self.deleteDocument(component, scmDocGuid);
      }
      component.set('v.isButtonEnabled', true);
      self.setLoading(component, false);
    });
  },

  getEOSFolderId: function (component) {
    var self = this;
    return new Promise($A.getCallback(function (resolve, reject) {
      self.invokeChainAction(component, component.get('c.getEOSFolderId'),
        {
          sourceId: component.get('v.recordId'),
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
});
