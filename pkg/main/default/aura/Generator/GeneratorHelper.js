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
    var self = this;
    var action = component.get('c.checkMultiCurrency');
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var isMultiCurrency = response.getReturnValue();
        component.set('v.isMultiCurrency', isMultiCurrency);
        self._getUserEvents(component).addProperties({
          'Multi-Currency': isMultiCurrency
        });
      } else {
        var errMsg = stringUtils.getErrorMessage(response);
        component.set('v.errType', 'error');
        component.set('v.errMsg', errMsg);
        self.endGenerationError(component, errMsg);
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
      var lookupObj = {
        apiName: config.objectMappings.name,
        label: config.objectMappings.label
      };
      lookupObjs.push(lookupObj);
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

  getChildKey: function (name, depth, type) {
    return name + '_' + (depth + 1) + '_' + type;
  },

  parseFieldMappings: function (fieldMappings, isMultiCurrency) {
    var helper = this;
    var map = {};
    fieldMappings.forEach(function (fieldMapping) {
      var key = fieldMapping.key + '_' + fieldMapping.depth + '_' + fieldMapping.type;
      map[key] = fieldMapping;
    });
    var query = helper.traverseFieldMapping(fieldMappings[0], '', '', fieldMappings[0].key, map, isMultiCurrency);
    return query;
  },

  traverseFieldMapping: function (fm, relationship, parentIdField, type, map, isMultiCurrency) {
    var helper = this;
    var query = {};
    var fields = [];
    var children = [];

    query.type = type;
    query.relationship = relationship;
    query.parentIdField = parentIdField;
    fm.fields.forEach(function (field) {
      if (!$A.util.isUndefinedOrNull(field) && !$A.util.isUndefinedOrNull(field.name) && field.name !== '') {
        var childKey = '';
        var child;
        if (field.type === 'CHILD_RELATIONSHIP') {
          if (fm.depth === 1) {
            childKey = helper.getChildKey(field.relationship, fm.depth, field.type);
          } else {
            childKey = helper.getChildKey(relationship + '.' + field.relationship, fm.depth, field.type);
          }
          child = map[childKey];
          children.push(helper.traverseFieldMapping(child, field.relationship, field.parentIdField, field.name, map, isMultiCurrency));
        } else if (field.type === 'REFERENCE') {
          if (fm.depth === 1) {
            childKey = helper.getChildKey(field.relationship, fm.depth, field.type);
          } else {
            childKey = helper.getChildKey(fm.key + '.' + field.relationship, fm.depth, field.type);
          }
          child = map[childKey];
          helper.traverseLookUp(child, map, isMultiCurrency).forEach(function (f) {
            fields.push(f);
          });
        } else if (isMultiCurrency && field.type === 'CURRENCY' && (fields.indexOf('CurrencyIsoCode') === -1)) {
          fields.push('CurrencyIsoCode');
          fields.push(field.name);
        } else if (field.name !== 'CurrentDate') {
          fields.push(field.name);
        }
      }
    });

    if (fields.length === 0) {
      fields.push('Id');
    }
    query.fields = fields;
    query.children = children;
    return query;
  },

  traverseLookUp: function (fm, map, isMultiCurrency) {
    var helper = this;
    var fields = [];
    var path = fm.path.join('.');
    fm.fields.forEach(function (field) {
      if (field.type === 'REFERENCE') {
        var childKey = helper.getChildKey(fm.key + '.' + field.name, fm.depth, field.type);
        var child = map[childKey];
        helper.traverseLookUp(child, map, isMultiCurrency).forEach(function (f) {
          fields.push(f);
        });
      } else if (isMultiCurrency && field.type === 'CURRENCY' && (fields.indexOf(fm.key + '.CurrencyIsoCode') === -1)) {
        fields.push(path + '.CurrencyIsoCode');
        fields.push(path + '.' + field.name);
      } else if (field.name !== 'CurrentDate' && !$A.util.isEmpty(field.name)) {
        fields.push(path + '.' + field.name);
      }
    });
    return fields;
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

    if (!$A.util.isEmpty(config.objectMappings.fieldMappings)) {
      var promise = new Promise(
        $A.getCallback(function (resolve, reject) {
          var action = component.get('c.getMergeData');
          var fieldMappings = config.objectMappings.fieldMappings;
          var query = helper.parseFieldMappings(fieldMappings, isMultiCurrency);
          var fieldMap = helper.getTypeMap(fieldMappings);
          action.setParams({
            sourceId: objIds[0],
            queryJson: JSON.stringify(query)
          });

          action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
              var results = response.getReturnValue();
              fieldMappings.forEach(function (objMap) {
                objMap.fields.forEach(function (field) {
                  if (field.name === 'CurrentDate') {
                    query['fields'].push('CurrentDate');
                  }
                });
              });
              var objXML = helper.generateXML(
                query,
                results.result,
                results.children,
                1,
                xmlRoot,
                fieldMap,
                isMultiCurrency,
                ''
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
          helper.endGenerationError(component, error);
        })
      );
  },

  getTypeMap: function (fieldMappings) {
    var map = {};
    var key = '';
    fieldMappings.forEach(function (fieldMapping) {
      fieldMapping.fields.forEach(function (field) {
        var value = {};
        if (field.type !== 'REFERENCE' && field.type !== 'CHILD_RELATIONSHIP') {
          if (fieldMapping.type === 'ROOT') {
            key = field.name.toLowerCase();
          } else {
            key = (fieldMapping.key + '.' + field.name).toLowerCase();
          }
          value.type = field.type;
          value.format = field.format;
          value.scale = field.scale;
          map[key] = value;
        }
      });
    });
    return map;
  },

  generateXML: function (query, result, children, depth, xmlRoot, fieldMap, isMultiCurrency, previousRelationship) {
    var helper = this;
    var objRoot = (depth === 1) ? xmlRoot.createElement(query.type) : xmlRoot.createElement(query.relationship);
    var format = '';

    query.fields.forEach(function (field) {
      var fieldXml;
      var fieldMapKey = query.relationship === '' ? field : query.relationship + '.' + field;
      if (depth > 2) {
        fieldMapKey = previousRelationship + '.' + fieldMapKey;
      }
      format = fieldMap[fieldMapKey.toLowerCase()];
      if (field.startsWith(query.type)) {
        fieldXml = xmlRoot.createElement(field.replace(query.type + '.', ''));
      } else {
        fieldXml = xmlRoot.createElement(field);
      }

      var fieldValue;
      var newFields = field.split('.');
      if (field === 'CurrentDate') {
        fieldValue = $A.localizationService.formatDate(new Date(), format.format === 'default' ? '' : format.format);
      } else if (depth <= 2) {
        fieldValue = helper.getFieldValue(newFields, result, format, isMultiCurrency);
      } else {
        fieldValue = helper.getFieldValue(newFields, children, format, isMultiCurrency);
      }
      var nodeValue = xmlRoot.createTextNode(fieldValue);
      fieldXml.appendChild(nodeValue);
      objRoot.appendChild(fieldXml);
    });
    var queryChildren = query.children;
    for (var i = 0; i < queryChildren.length; i++) {
      var childQuery = queryChildren[i];
      var container = xmlRoot.createElement(childQuery.relationship + '_Container');
      var childData = [];
      var childXml;
      if (depth < 2) {
        childData = result[childQuery.relationship];
        if ($A.util.isUndefinedOrNull(childData)) {
          return objRoot;
        }
        for (var j = 0; j < childData.length; j++) {
          childXml = helper.generateXML(childQuery, childData[j], children, depth + 1, xmlRoot, fieldMap, isMultiCurrency, query.relationship);
          container.appendChild(childXml);
          objRoot.appendChild(container);
        }
      } else {
        childData = children[childQuery.relationship];
        if ($A.util.isUndefinedOrNull(childData)) {
          return objRoot;
        }
        for (var k = 0; k < childData.length; k++) {
          if (result['Id'] === childData[k][childQuery.parentIdField]) {
            childXml = helper.generateXML(childQuery, result, childData[k], depth + 1, xmlRoot, fieldMap, isMultiCurrency, query.relationship);
            container.appendChild(childXml);
            objRoot.appendChild(container);
          }
        }
      }
    }
    return objRoot;
  },

  getFieldValue: function (fields, result, format, isMultiCurrency) {
    var helper = this;
    var nodeValue = '';
    if (fields.length === 1) {
      nodeValue = ($A.util.isUndefinedOrNull(result) || $A.util.isUndefinedOrNull(result[fields[0]])) ? '' : result[fields[0]];
    } else if (fields.length === 2) {
      nodeValue = ($A.util.isUndefinedOrNull(result) || $A.util.isUndefinedOrNull(result[fields[0]]) || $A.util.isUndefinedOrNull(result[fields[0]][fields[1]])) ? '' : result[fields[0]][fields[1]];
    } else {
      var newResult = $A.util.isUndefinedOrNull(result[fields[0]]) ? result : result[fields[0]];
      fields.shift();
      nodeValue = helper.getFieldValue(fields, newResult, format, isMultiCurrency);
      return nodeValue;
    }
    if (!$A.util.isUndefinedOrNull(format)) {
      var recordLevelCurrencyCode = '';
      if (isMultiCurrency && format.type === 'CURRENCY' && fields.length > 1) {
        var getFieldIndex = result[fields.slice(0, fields.length - 1).join('.')];
        if (!$A.util.isUndefinedOrNull(getFieldIndex)) {
          recordLevelCurrencyCode = getFieldIndex.CurrencyIsoCode;
        }
      } else if (!$A.util.isUndefinedOrNull(result.CurrencyIsoCode)) {
        recordLevelCurrencyCode = result.CurrencyIsoCode;
      }
      nodeValue = helper.getFormattedData(nodeValue, format, isMultiCurrency, recordLevelCurrencyCode);
    }
    return nodeValue;
  },

  // FIXME: get recordLevelCurrencyCode
  getFormattedData: function (nodeValue, format, isMultiCurrency, recordLevelCurrencyCode) {
    var helper = this;
    var type = format.type;
    var fieldFormat = format.format;
    var locale = $A.get('$Locale');
    if ($A.util.isEmpty(nodeValue)) {
      nodeValue = '';
    } else if (type === 'PERCENT') {
      var percentSymbol = $A.util.getBooleanValue(fieldFormat) ? '%' : '';
      nodeValue = stringUtils.format('{0}{1}', helper.formatNumber(nodeValue, format.scale), percentSymbol);
    } else if (type === 'DOUBLE') {
      nodeValue = helper.formatNumber(nodeValue, format.scale);
    } else if (type === 'ADDRESS') {
      var address = nodeValue;
      nodeValue = '';

      if (!$A.util.isEmpty(address.street)) {
        nodeValue += address.street;
      }
      if (!$A.util.isEmpty(address.city)) {
        nodeValue += ', ' + address.city;
      }
      if (!$A.util.isEmpty(address.state)) {
        nodeValue += ', ' + address.state;
      }
      if (!$A.util.isEmpty(address.postal)) {
        nodeValue += ' ' + address.postal;
      }
      if (!$A.util.isEmpty(address.country)) {
        nodeValue += ' ' + address.country;
      }
    } else if (type === 'CURRENCY') {
      var currencyCode = locale.currencyCode;
      if (isMultiCurrency) {
        currencyCode = recordLevelCurrencyCode;
      }
      nodeValue = helper.setCurrencyFormat(nodeValue, format, currencyCode);
    } else if (type === 'DATE') {
      if (fieldFormat === 'default') {
        fieldFormat = locale.dateFormat;
      }
      nodeValue = $A.localizationService.formatDate(nodeValue, fieldFormat);
    } else if (type === 'TIME') {
      if (fieldFormat === 'default') {
        fieldFormat = locale.timeFormat;
      }
      var date = new Date(nodeValue);
      nodeValue = ($A.localizationService.formatDateTimeUTC(date, 'YYYY-MM-DD,' + fieldFormat)).split(',')[1];
    } else if (type === 'DATETIME') {
      var formats = fieldFormat.split('|');
      if (formats[0] === 'default') {
        formats[0] = locale.dateFormat;
      }
      if (formats[1] === 'default') {
        formats[1] = locale.timeFormat;
      }
      //ADDING TIMEZONE OFFSET
      $A.localizationService.UTCToWallTime(new Date(nodeValue), $A.get('$Locale.timezone'), function (offSetDateTime) {
        nodeValue = offSetDateTime;
      });
      // FIXME: No hardcoded time format.
      nodeValue = $A.localizationService.formatDateTimeUTC(
        nodeValue, stringUtils.format('{0}{1}{2}', formats[0], ' ', formats[1]));
    }
    return nodeValue;
  },

  setCurrencyFormat: function (nodeValue, fieldData, currencyCode) {
    var helper = this;
    var sampleCurrency = 0;
    var currencyFormat = fieldData.format;
    if (currencyFormat.indexOf('NoDecimals') !== -1) {
      nodeValue = $A.localizationService.formatNumber(Math.round(nodeValue));
    } else {
      nodeValue = helper.formatNumber(nodeValue, fieldData.scale);
    }
    if (currencyFormat.indexOf('noSymbolNoCode') !== -1) {
      return nodeValue;
    }
    // Using toLocalString() to get the currency symbol
    var getCurrencySymbol = sampleCurrency.toLocaleString($A.get('$Locale').userLocaleCountry, {
      style: 'currency', currency: currencyCode,
      currencyDisplay: currencyFormat.indexOf('symbol') !== -1 ? 'symbol' : 'code',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
    return getCurrencySymbol.replace('0', nodeValue);
  },

  formatNumber: function (getNumberVal, decimalScale) {
    var getIntegerVal = getNumberVal.toString();
    var getTrailingZeros = (decimalScale > 0) ? stringUtils.format('{0}{1}', $A.get('$Locale').decimal, parseFloat(getNumberVal).toFixed(decimalScale).split('.')[1]) : '';
    if (getIntegerVal.indexOf('.') !== -1)
      getIntegerVal = getIntegerVal.split('.')[0];
    return stringUtils.format('{0}{1}', $A.localizationService.formatNumber(getIntegerVal, $A.get('$Locale').numberFormat), getTrailingZeros);
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

        //iterate Gen.Job results object and set populate jobIds, cvTitleByJobId, failedJobs
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

        //completionPoll should only be called if remainingJobIds is defined
        if (!$A.util.isUndefinedOrNull(remainingJobIds)) {
          helper.completionPoll(component, jobIds, remainingJobIds, 0);
        }
        //remainingJobIds is not defined indicates document generation job was not successfully triggered
        else {
          helper.handleUndefinedJobIdResponse(component, failedJobs);
        }

      } else {
        helper.handleExceptionInQueueDocumentGeneration(component, response, helper);
      }
    });

    $A.enqueueAction(action);
  },

  handleExceptionInQueueDocumentGeneration: function (component, response, helper) {
    var errorMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.FailedInitiateDocGeneration'), stringUtils.getErrorMessage(response));
    component.set('v.errMsg', errorMessage);
    component.set('v.errType', 'error');
    component.set('v.isGenerating', false);
    helper.endGenerationError(component, errorMessage);
  },

  handleUndefinedJobIdResponse: function (component, failedJobs) {
    var errorMessage = $A.get('$Label.c.FailedInitiateDocGeneration');
    failedJobs.forEach(function (job) {
      errorMessage += job.message;
    });
    component.set('v.errMsg', errorMessage);
    component.set('v.errType', 'error');
    component.set('v.isGenerating', false);
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
        var errorMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.GeneratorCompletionErrorMsg'), stringUtils.getErrorMessage(response));
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
          fileIds: fileIds
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
