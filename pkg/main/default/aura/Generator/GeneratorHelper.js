({
  PREVIEW_DOCUMENT: 'Preview Gen Document',
  GENERATE_DOCUMENT: 'Generate Gen Document',

  _getUserEvents: function (component) {
    return component.find('ds-user-events');
  },

  _getEvent: function (component) {
    return component.get('v.isPreview') ? this.PREVIEW_DOCUMENT : this.GENERATE_DOCUMENT;
  },

  startGeneration: function (component) {
    var ue = this._getUserEvents(component);
    ue.time(this._getEvent(component));
    ue.addProperties({
      'Product': 'Gen'
    });
  },

  endGenerationSuccess: function (component) {
    this._getUserEvents(component).success(this._getEvent(component), {});
  },

  endGenerationError: function (component, error) {
    this._getUserEvents(component).error(this._getEvent(component), {}, error);
  },

  checkMultiCurrency: function (component) {
    var action = component.get('c.checkMultiCurrency');
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var isMultiCurrency = response.getReturnValue();
        component.set('v.isMultiCurrency', isMultiCurrency);
        this._getUserEvents(component).addProperties({
          'Multi-Currency': isMultiCurrency
        });
      } else {
        var errMsg = stringUtils.getErrorMessage(response);
        component.set('v.errType', 'error');
        component.set('v.errMsg', errMsg);
        this.endGenerationError(component, errMsg);
      }
    });
    $A.enqueueAction(action);
  },

  setupData: function (component) {
    this.startGeneration(component);
    var config = component.get('v.config');
    var isPreview = component.get('v.isPreview');
    var templateFiles = component.get('v.templateFiles');
    var lookupObjs = [];
    var helper = this;
    var numFiles = $A.util.isEmpty(templateFiles) ? 0 : templateFiles.length;
    this._getUserEvents(component).addProperties({
      'Template Type': 'Word',
      'Source Object': config ? config.sourceObject : null,
      'Template Files': numFiles
    });

    //there are no template files
    if (numFiles === 0) {
      var errMsg = $A.get('$Label.c.NoDocForTemplateMsg');
      component.set('v.errMsg', errMsg);
      component.set('v.errType', 'warning');
      this.endGenerationError(component, errMsg);
    } else {
      templateFiles.forEach(function (file) {
        helper.addDocumentProperties(file, true);
      });
      component.set('v.templateFiles', templateFiles);
      config.objectMappings.forEach(function (objMapping) {
        var lookupObj = {
          apiName: objMapping.apiName,
          label: objMapping.label
        };
        lookupObjs.push(lookupObj);
      });
      component.set('v.lookupObjs', lookupObjs);
    }

    //Preview Mode
    if (isPreview) {
      helper.getRecentRecords(component).then(
        function () {
          component.set('v.isLoading', false);
          component.set('v.lookupObjs', lookupObjs);
        },
        function () {
          component.set('v.isLoading', false);
        }
      );
    } else {
      if (
        lookupObjs.length === 1 &&
        config.useCurrentRecord &&
        config.useAllTemplates
      ) {
        helper.getRecordData(component);
      }
      component.set('v.isLoading', false);
    }
  },

  getRecentRecords: function (component) {
    return new Promise(
      $A.getCallback(function (parentResolve, parentReject) {
        var lookupObjs = component.get('v.lookupObjs');
        var promises = [];

        lookupObjs.forEach(function (lookup, index) {
          var promise = new Promise(
            $A.getCallback(function (resolve, reject) {
              var action = component.get('c.getLatestRecordId');

              action.setParams({
                sObjectType: lookup.apiName
              });

              action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                  lookup.value = response.getReturnValue();
                  if (index === 0) {
                    component.set('v.recordId', response.getReturnValue());
                  }
                  resolve();
                } else {
                  reject();
                }
              });

              action.setBackground();
              $A.enqueueAction(action);
            })
          );

          promises.push(promise);
        });

        Promise.all(promises)
          .then(
            $A.getCallback(function () {
              parentResolve();
            })
          )
          .catch(
            $A.getCallback(function () {
              parentReject();
            })
          );
      })
    );
  },

  getRecordData: function (component) {
    var helper = this;
    var lookups = component.find('recordLookup');
    lookups = Array.isArray(lookups) ? lookups : [lookups];
    var missingLookup = false;
    var objIds = [];

    lookups.forEach(function (lookup) {
      if ($A.util.isEmpty(lookup.get('v.value'))) {
        lookup.showError();
        missingLookup = true;
      } else {
        objIds.push(lookup.get('v.value'));
      }
    });

    if (missingLookup) {
      return;
    }

    component.set('v.isGenerating', true);
    var isMultiCurrency = component.get('v.isMultiCurrency');
    var config = component.get('v.config');
    var xmlRoot = document.implementation.createDocument('', '', null);
    var templateConfig = xmlRoot.createElement('Template_Config');
    var objPromises = [];

    xmlRoot.appendChild(templateConfig);

    config.objectMappings.forEach(function (objMap, index) {
      if (!$A.util.isEmpty(objMap.fieldMappings)) {
        var promise = new Promise(
          $A.getCallback(function (resolve, reject) {
            var action = component.get('c.getMergeData');
            var currentFieldMappings = objMap.fieldMappings;
            var fields = [];
            var addCurrencyFields = [];
            var children = [];

            currentFieldMappings.forEach(function (object) {
              if (!object.isChildRelation) {
                if (object.apiName !== 'CurrentDate') {
                  fields.push(object.apiName);
                }
                if (isMultiCurrency && object.dataType === 'CURRENCY') {
                  addCurrencyFields.push(object.apiName);
                }
              } else {
                var childrenFields = [];
                var isCurrencyFieldExists = false;
                object.childFieldMappings.forEach(function (obj) {
                  childrenFields.push(obj.apiName);
                  isCurrencyFieldExists = isMultiCurrency && obj.dataType === 'CURRENCY';
                });
                var childrenObject = {
                  type: object.apiName,
                  relationship: object.label,
                  fields: childrenFields,
                  children: []
                };
                if (isCurrencyFieldExists && !childrenFields.includes('CurrencyIsoCode')) {
                  childrenFields.push('CurrencyIsoCode');
                }
                children.push(childrenObject);
              }
            });
            if ($A.util.isEmpty(fields)) {
              fields.push('Id');
            }
            helper.setCurrencyIsoCode(addCurrencyFields, fields);
            var inputParamter = {
              type: objMap.apiName,
              relationship: '',
              fields: fields,
              children: children
            };
            var jsonString = JSON.stringify(inputParamter);

            action.setParams({
              sourceId: objIds[index],
              queryJson: jsonString
            });

            action.setCallback(this, function (response) {
              var state = response.getState();
              if (state === 'SUCCESS') {
                var results = response.getReturnValue();
                var objXML = helper.generateXML(
                  xmlRoot,
                  results,
                  objMap,
                  false,
                  component
                );
                templateConfig.appendChild(objXML);
                resolve();
              } else {
                reject(stringUtils.getErrorMessage(response));
              }
            });
            action.setBackground();
            $A.enqueueAction(action);
          })
        );

        objPromises.push(promise);
      }
    });

    Promise.all(objPromises)
      .then(
        $A.getCallback(function () {
          //preview might hit the back button before we're done so
          //if its not valid just do nothing so an error message doesn't show up.
          if (component.isValid()) {
            helper.generateDocuments(component, objIds[0], xmlRoot);
          }
        })
      )
      .catch(
        $A.getCallback(function (error) {
          component.set('v.errMsg', error);
          component.set('v.errType', 'error');
          component.set('v.isGenerating', false);
          this.endGenerationError(component, error);
        })
      );
  },

  setCurrencyIsoCode: function (addCurrencyFields, fields) {
    if (!$A.util.isEmpty(addCurrencyFields) && !$A.util.isEmpty(fields)) {
      addCurrencyFields.forEach(function (obj) {
        var parentObj = obj.substring(0, obj.indexOf('.'));
        if (obj.includes('.') && !fields.includes(stringUtils.format('{0}{1}',parentObj,'.CurrencyIsoCode'))) {
          fields.push(stringUtils.format('{0}{1}',parentObj,'.CurrencyIsoCode'));
        } else if (!fields.includes('CurrencyIsoCode')) {
          fields.push('CurrencyIsoCode');
        }
      });
    }
  },

  generateXML: function (xmlRoot, recordData, objMap, isChild, component) {
    var helper = this;
    var objRoot = xmlRoot.createElement(isChild ? objMap.label.replace(/\s/g, '_') : objMap.apiName.replace(/\s/g, '_'));
    var unformattedDataTypes = ['DATE', 'DATETIME', 'TIME', 'DOUBLE', 'PERCENT', 'CURRENCY'];
    var fieldMappings = isChild
      ? objMap.childFieldMappings
      : objMap.fieldMappings;
    var seenFields = []; //prevent duplicate node names;

    fieldMappings.forEach(function (fieldMap) {
      var apiName = fieldMap.apiName;
      var fieldNode = null;
      var dateFormat = null;
      var timeFormat = null;


      if (fieldMap.isChildRelation) {
        fieldNode = xmlRoot.createElement(fieldMap.label + '_Container');
        //label is childRelationName
        if (recordData[fieldMap.label]) {
          var childRecords = recordData[fieldMap.label];
          childRecords.forEach(function (childRecord) {
            var childXML = helper.generateXML(
              xmlRoot,
              childRecord,
              fieldMap,
              true,
              component
            );
            fieldNode.appendChild(childXML);
          });
        }

        objRoot.appendChild(fieldNode);
      } else if (seenFields.indexOf(apiName) === -1) {
        seenFields.push(apiName);

        var dataType = fieldMap.dataType;
        fieldNode = xmlRoot.createElement(apiName);
        var locale = $A.get('$Locale');
        var fieldVal;

        if (apiName.indexOf('.') !== -1) {
          var lookupParts = apiName.split('.');
          var parent = recordData[lookupParts[0]];

          if ($A.util.isEmpty(parent)) {
            fieldVal = '';
          } else {
            fieldVal = parent[lookupParts[1]];
          }
        } else {
          fieldVal = recordData[apiName];
        }

        //Spring requested any date or datetime be put in in an unformatted state
        //for further processing on their side.
        // for dataTypes: date, datetime, time, currency, percent, number
        if (unformattedDataTypes.includes(dataType)) {
          var dateNode = xmlRoot.createElement(apiName + 'Unformatted');
          var dateContent = xmlRoot.createTextNode(fieldVal);
          dateNode.appendChild(dateContent);
          objRoot.appendChild(dateNode);
        }
        
        if (apiName === 'CurrentDate') {
          fieldVal = new Date();
        }
        if ($A.util.isEmpty(fieldVal)) {
          fieldVal = '';
        } else if (dataType === 'DATE') {
          dateFormat = fieldMap.format;

          if (dateFormat === 'default') {
            dateFormat = locale.dateFormat;
          }

          fieldVal = $A.localizationService.formatDate(fieldVal, dateFormat);
        } else if (dataType === 'TIME') {
          timeFormat = fieldMap.format;
          if (timeFormat === 'default') {
            timeFormat = locale.timeFormat;
          }

          var date = new Date(fieldVal);
          fieldVal = ($A.localizationService.formatDateTimeUTC(date, 'YYYY-MM-DD,' + timeFormat)).split(',')[1];
        } else if (dataType === 'DATETIME') {
          var formats = fieldMap.format.split('|');
          if (formats[0] === 'default') {
            formats[0] = locale.dateFormat;
          } 
          if (formats[1] === 'default') {
            formats[1] = locale.timeFormat;
          }
          //ADDING TIMEZONE OFFSET
          $A.localizationService.UTCToWallTime(new Date(fieldVal), $A.get('$Locale.timezone'), function (offSetDateTime) {
            fieldVal = offSetDateTime;
          });
          // FIXME: No hardcoded time format.         
          fieldVal = $A.localizationService.formatDateTimeUTC(
            fieldVal, stringUtils.format('{0}{1}{2}', formats[0], ' ', formats[1]));
        } else if (dataType === 'CURRENCY') {
          var isMultiCurrency = component.get('v.isMultiCurrency');
          var currencyCode = locale.currencyCode;
          if (isMultiCurrency) {
            if (apiName.indexOf('.') !== -1) {
              var parentObject = recordData[apiName.split('.')[0]];
              if (!$A.util.isEmpty(parentObject) && parentObject['CurrencyIsoCode']) {
                currencyCode = parentObject['CurrencyIsoCode'];
              }
            } else {
              currencyCode = recordData['CurrencyIsoCode'];
            }
          }
          fieldVal = helper.setCurrencyFormat(fieldVal, fieldMap, currencyCode);
        } else if (dataType === 'ADDRESS') {
          var address = fieldVal;
          fieldVal = '';

          if (!$A.util.isEmpty(address.street)) {
            fieldVal += address.street;
          }

          if (!$A.util.isEmpty(address.city)) {
            fieldVal += ', ' + address.city;
          }

          if (!$A.util.isEmpty(address.state)) {
            fieldVal += ', ' + address.state;
          }

          if (!$A.util.isEmpty(address.postal)) {
            fieldVal += ' ' + address.postal;
          }

          if (!$A.util.isEmpty(address.country)) {
            fieldVal += ' ' + address.country;
          }
        } else if (dataType === 'PERCENT') {
          var percentSymbol =  $A.util.getBooleanValue(fieldMap.format) ? '%' : '';
          fieldVal = stringUtils.format('{0}{1}',helper.formatNumber(fieldVal, fieldMap.decimalPlaces), percentSymbol);
        } else if (dataType === 'DOUBLE') {
          fieldVal = helper.formatNumber(fieldVal, fieldMap.decimalPlaces);
        }
        //ignore object fields that aren't type Address
        if (typeof fieldVal !== 'object') {
          var content = xmlRoot.createTextNode(fieldVal);
          fieldNode.appendChild(content);
          objRoot.appendChild(fieldNode);
        }
      }
    });

    return objRoot;
  },

  setCurrencyFormat: function (getValue, getFieldData, getCurrencyCode) {
    var helper = this;
    var sampleCurrency = 0;
    var currencyFormat = getFieldData.format;
    if (currencyFormat.indexOf('NoDecimals') !== -1) {
      getValue = $A.localizationService.formatNumber(Math.round(getValue));
    } else {
      getValue = helper.formatNumber(getValue, getFieldData.decimalPlaces);
    }
    if (currencyFormat.indexOf('noSymbolNoCode') !== -1) {
      return getValue;
    }
    // Using toLocalString() to get the currency symbol
    var getCurrencySymbol = sampleCurrency.toLocaleString($A.get('$Locale').userLocaleCountry, {
      style: 'currency', currency: getCurrencyCode,
      currencyDisplay: currencyFormat.indexOf('symbol') !== -1 ? 'symbol' : 'code',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
    return getCurrencySymbol.replace('0', getValue);
  },

  formatNumber: function (getNumberVal, decimalScale) {
    var getIntegerVal = getNumberVal.toString();
    var getTrailingZeros = (decimalScale > 0) ? stringUtils.format('{0}{1}',$A.get('$Locale').decimal ,parseFloat(getNumberVal).toFixed(decimalScale).split('.')[1]) : '';
    if (getIntegerVal.indexOf('.') !== -1)
      getIntegerVal = getIntegerVal.split('.')[0];
    return stringUtils.format('{0}{1}',$A.localizationService.formatNumber(getIntegerVal, $A.get('$Locale').numberFormat) , getTrailingZeros);
  },

  generateDocuments: function (component, startingRecordId, xmlRoot) {
    var config = component.get('v.config');
    var isPreview = component.get('v.isPreview');
    var serializer = new XMLSerializer();
    var xmlString = serializer.serializeToString(xmlRoot); //serializeToString escapes xml for us
    var helper = this;
    var templateFiles = component.get('v.templateFiles');
    var selectedTemplateFiles = [];

    templateFiles.forEach(function (templateFile) {
      if (templateFile.isChecked) {
        selectedTemplateFiles.push(templateFile.contentDocumentId);
      }
    });

    var action = component.get('c.queueDocumentGeneration');
    action.setParams({
      templateId: config.id,
      sourceId: startingRecordId,
      xmlPayload: xmlString,
      isPreview: isPreview,
      contentDocumentIds: selectedTemplateFiles
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var jobIds = [];
        var cvTitleByJobId = {};
        var failedJobs = [];

        results.forEach(function (object) {
          if (object.status === $A.get('$Label.c.Failure')) {
            var failedJobDetail = {message: object.message, cv: object.file};
            failedJobs.push(failedJobDetail);
            helper.endGenerationError(component, object.message);
          } else {
            jobIds.push(object.id.value);
            cvTitleByJobId[object.id.value] = object.file.title;
          }
        });

        if (!$A.util.isEmpty(jobIds)) {
          var remainingJobIds = jobIds.slice(0);
        }

        helper.genFileCheckboxToggle(component);
        component.set('v.failedFiles', failedJobs);
        component.set('v.cvTitleByJobId', cvTitleByJobId);
        helper.completionPoll(component, jobIds, remainingJobIds, 0);
      } else {
        var errorMessage = $A.get('$Label.c.FailedInitiateDocGeneration');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        }
        component.set('v.errMsg', errorMessage);
        component.set('v.errType', 'error');
        component.set('v.isGenerating', false);
        helper.endGenerationError(component, errorMessage);
      }
    });

    $A.enqueueAction(action);
  },

  completionPoll: function (component, jobIds, remainingJobIds, runCount) {
    //30s polling
    if (runCount === 16) {
      component.set('v.showTakingTooLongMessage', true);
      component.getEvent('generatedDocs').fire();
      return;
    }

    var helper = this;
    var generatedFiles = component.get('v.generatedFiles');
    var failedFiles = component.get('v.failedFiles');
    var cvTitleByJobId = component.get('v.cvTitleByJobId');
    var action = component.get('c.getJobStatus');

    action.setParams({
      jobIds: remainingJobIds
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var finishedJobs = [];
        var failedJobs = [];

        results.forEach(function (object) {
          if (object.status === 'Success') {
            finishedJobs.push({cv: object.file, jobId: object.id.value});
            helper.endGenerationSuccess(component);
          } else if (object.status === 'Failure') {
            failedJobs.push({
              jobId: object.id.value,
              message: object.message
            });
            helper.endGenerationError(component, object.message);
          }
        });

        finishedJobs.forEach(function (finishedJob) {
          var jobIndex = jobIds.indexOf(finishedJob.jobId);
          var remainingJobIndex = remainingJobIds.indexOf(finishedJob.jobId);
          generatedFiles[jobIndex] = finishedJob.cv;
          remainingJobIds.splice(remainingJobIndex, 1);
        });

        failedJobs.forEach(function (failedJob) {
          var remainingJobIndex = remainingJobIds.indexOf(failedJob.jobId);
          var templateTitle = cvTitleByJobId[failedJob.jobId];
          remainingJobIds.splice(remainingJobIndex, 1);
          failedJob.title = templateTitle;
          failedFiles.push(failedJob);
        });

        if (remainingJobIds.length > 0) {
          setTimeout(
            $A.getCallback(function () {
              helper.completionPoll(
                component,
                jobIds,
                remainingJobIds,
                ++runCount
              );
            }),
            2000
          );
        } else {
          component.set('v.finishedGenerating', true);
          component.set('v.isGenerating', false);
          component.getEvent('generatedDocs').fire();

          if (!$A.util.isEmpty(generatedFiles)) {
            generatedFiles.forEach(function (d) {
              helper.addDocumentProperties(d, true);
            });
          }

          component.set('v.generatedFiles', generatedFiles);
          component.set('v.failedFiles', failedFiles);
          helper.genFileCheckboxToggle(component);

          if (failedFiles.length > 0) {
            component.set('v.bannerState', 'warning');
            component.set(
              'v.bannerMsg',
              $A.get('$Label.c.GeneratorBannerErrorMsg')
            );
          } else {
            var bannerMsg = $A.get('$Label.c.GeneratorBannerSuccessMsg');
            component.set('v.bannerState', 'success');
            component.set('v.bannerMsg', bannerMsg);
          }
        }
      } else {
        var errorMessage = $A.get('$Label.c.GeneratorCompletionErrorMsg') + ' ';
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        }
        component.set('v.finishedGenerating', true);
        component.set('v.isGenerating', false);
        component.set('v.bannerState', 'error');
        component.set('v.bannerMsg', errorMessage);
        helper.endGenerationError(component, errorMessage);
      }
    });

    $A.enqueueAction(action);
  },

  sendForSignature: function (component) {
    var helper = this;
    return new Promise($A.getCallback(function (resolve) {
      var generatedFiles = component.get('v.generatedFiles');
      var generatedFileIds = [];
      generatedFiles.forEach(function (generatedFile) {
        if (generatedFile.isChecked) {
          generatedFileIds.push(generatedFile.id);
        }
      });
      resolve(generatedFileIds);
    })).then(
      $A.getCallback(function (fileIds) {
        var sendingAction = component.get('c.getSendingDeepLink');
        var sourceId = component.get('v.recordId');
        sendingAction.setParams({
          sourceId: sourceId,
          fileIdsInCommaSeparated: !$A.util.isEmpty(fileIds) ? fileIds.join(',') : ''
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
      })
    );
  },

  addDocumentProperties: function (doc, selected) {
    if (doc) {
      doc.isChecked = selected;
      doc.formattedSize = doc.size ? stringUtils.formatSize(doc.size) : '';
    }
    return doc;
  },

  createAgreement: function (component, event, helper) {
    var recordId = component.get('v.recordId');
    return new Promise(
      $A.getCallback(function (resolve) {
        var agreementDetail = component.get('v.agreementDetails');
        if ($A.util.isUndefinedOrNull(agreementDetail)) {
          var generatedFiles = component.get('v.generatedFiles');
          var selectedFile;
          generatedFiles.forEach(function (generatedFile) {
            if (generatedFile.isChecked) {
              selectedFile = generatedFile;
            }
          });
          if (selectedFile) {
            var createAgreementAction = component.get('c.createAgreementInEOSFolder');
            createAgreementAction.setParams({
              sfContentVersionId: selectedFile.id,
              sourceObjectId: recordId,
              documentName: selectedFile.title + '.' + selectedFile.extension
            });
            createAgreementAction.setCallback(this, function (response) {
              if (response.getState() === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.status === 'Success') {
                  resolve(helper.getAgreementDetails(result.agreementId.value, component));
                }
              } else {
                component.set('v.isLoading', false);
                helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
              }
            });
            $A.enqueueAction(createAgreementAction);
          }
        } else {
          component.set('v.isLoading', false);
          resolve();
        }
      }));
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

  getAgreementDetails: function (agreementId, component) {
    var helper = this;
    return new Promise($A.getCallback(function (resolve) {
      var action = component.get('c.getAgreement');
      action.setParams({
        agreementId: agreementId
      });
      action.setCallback(this, function (response) {
        component.set('v.isLoading', false);
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.agreementDetails', response.getReturnValue());
          resolve();
        } else {
          helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        }
      });
      $A.enqueueAction(action);
    }));
  },

  genFileCheckboxToggle: function (component) {
    component.set('v.disableSendForSignature', true);
    component.set('v.disableGenFileReview', true);
    var generatedFiles = component.get('v.generatedFiles');
    var checkedFiles = [];
    generatedFiles.forEach(function (generatedFile) {
      if (generatedFile.isChecked) {
        checkedFiles.push(generatedFile);
      }
    });
    if (checkedFiles.length > 0) {
      component.set('v.disableSendForSignature', false);
    }
    if (checkedFiles.length === 1) {
      component.set('v.disableGenFileReview', false);
    }
  },

  showToast: function (component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.set('v.showToast', true);
    if (mode === 'success') {
      window.setTimeout($A.getCallback(function () {
        component.set('v.showToast', false);
      }), 3000);
    }
  },

  hideToast: function (component) {
    component.find('toast').close();
  },

  navigateToSource: function (component) {
    navUtils.navigateToSObject(component.get('v.recordId'));
  }
});
