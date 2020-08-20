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

  getConfiguration: function (component, templateId) {
    var self = this;
    var action = component.get('c.getConfiguration');
    action.setParams({
      templateId: templateId,
      isGenerating: true
    });
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var config = response.getReturnValue();
        component.set('v.template', config.template);
        component.set('v.templateFiles', config.template.generated);
        component.set('v.isMultiCurrency', config.isMultiCurrencyOrganization === true);
        component.set('v.useGenV1', config.useGenV1 === true);
        self._getUserEvents(component).addProperties({
          'Multi-Currency': config.isMultiCurrencyOrganization === true,
          'Gen V1': config.useGenV1 === true
        });
        self.setupData(component);
      } else {
        component.set('v.errType', 'error');
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
        component.set('v.isLoading', false);
        self.endGenerationError(component, 'Error while reading configuration');
      }
    });
    $A.enqueueAction(action);
  },

  setupData: function (component) {
    this.startGeneration(component);
    var template = component.get('v.template');
    var isPreview = component.get('v.isPreview');
    var templateFiles = component.get('v.templateFiles');
    var lookupObjs = [];
    var helper = this;
    var numFiles = $A.util.isEmpty(templateFiles) ? 0 : templateFiles.length;
    this._getUserEvents(component).addProperties({
      'Template Type': 'Word',
      'Source Object': stringUtils.sanitizeObjectName(template ? template.sourceObject : null),
      'Template Files': numFiles
    });

    //there are no template files
    if (numFiles === 0) {
      var errMsg = $A.get('$Label.c.NoDocForTemplateMsg');
      component.set('v.errMsg', errMsg);
      component.set('v.errType', 'warning');
      this.endGenerationError(component, 'No template files to generate');
    } else {
      templateFiles.forEach(function (file) {
        helper.addDocumentProperties(file, true);
      });
      component.set('v.templateFiles', templateFiles);
      var lookupObj = {
        apiName: template.objectMappings.name,
        label: template.objectMappings.label
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
        template.useCurrentRecord &&
        template.useAllTemplates
      ) {
        var sourceId = this.getSourceId(component);
        if (component.get('v.useGenV1')) {
          helper.getRecordData(component, sourceId);
        } else {
          helper.generateDocuments(component, template.id, sourceId);
        }
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
    var query = helper.traverseFieldMapping(fieldMappings[0], '', '', fieldMappings[0].key, map, isMultiCurrency, null, null, null);
    return query;
  },

  traverseFieldMapping: function (fm, relationship, parentIdField, type, map, isMultiCurrency, filterBy, orderBy, maximumRecords) {
    var helper = this;
    var query = {};
    var fields = [];
    var children = [];
    var doesCurrencyFieldExist = false;

    query.type = type;
    query.relationship = relationship;
    query.parentIdField = parentIdField;
    query.filterBy = filterBy;
    query.orderBy = orderBy;
    query.maximumRecords = maximumRecords;
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
          children.push(helper.traverseFieldMapping(child, field.relationship, field.parentIdField, field.name, map, isMultiCurrency, field.filterBy, field.orderBy, field.maximumRecords));
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
        } else if (field.name !== 'CurrentDate') {
          fields.push(field.name);
          if (isMultiCurrency && field.type === 'CURRENCY') {
            doesCurrencyFieldExist = true;
          }
        }
      }
    });

    if (doesCurrencyFieldExist && (fields.indexOf('CurrencyIsoCode') === -1)) {
      fields.push('CurrencyIsoCode');
    }
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
    var doesCurrencyFieldExist = false;
    fm.fields.forEach(function (field) {
      if (field.type === 'REFERENCE') {
        var childKey = helper.getChildKey(fm.key + '.' + field.name, fm.depth, field.type);
        var child = map[childKey];
        helper.traverseLookUp(child, map, isMultiCurrency).forEach(function (f) {
          fields.push(f);
        });
      } else if (field.name !== 'CurrentDate' && !$A.util.isEmpty(field.name)) {
        fields.push(path + '.' + field.name);
        if (isMultiCurrency && field.type === 'CURRENCY') {
          doesCurrencyFieldExist = true;
        }
      }
    });
    if (doesCurrencyFieldExist && (fields.indexOf(path + '.CurrencyIsoCode') === -1)) {
      fields.push(path + '.CurrencyIsoCode');
    }
    return fields;
  },

  getSourceId: function (component) {
    var lookups = component.find('recordLookup');
    lookups = Array.isArray(lookups) ? lookups : [lookups];
    var objIds = [];

    lookups.forEach(function (lookup) {
      if ($A.util.isEmpty(lookup.get('v.value'))) {
        lookup.showError();
      } else {
        objIds.push(lookup.get('v.value'));
      }
    });

    return $A.util.isEmpty(objIds) ? null : objIds[0];
  },

  getRecordData: function (component, sourceId) {
    if ($A.util.isUndefinedOrNull(sourceId)) return;

    var helper = this;

    component.set('v.isGenerating', true);
    var isMultiCurrency = component.get('v.isMultiCurrency');
    var template = component.get('v.template');
    var xmlRoot = document.implementation.createDocument('', '', null);
    var templateConfig = xmlRoot.createElement('Template_Config');
    var selectedTemplateFiles = component.get('v.templateFiles').filter(function (t) {
      return t.isChecked;
    });
    var objPromises = [];

    xmlRoot.appendChild(templateConfig);

    if (!$A.util.isEmpty(template.objectMappings.fieldMappings)) {
      var promise = new Promise(
        $A.getCallback(function (resolve, reject) {
          var action = component.get('c.getMergeData');
          var fieldMappings = template.objectMappings.fieldMappings;
          var query = helper.parseFieldMappings(fieldMappings, isMultiCurrency);
          var fieldMap = helper.getTypeMap(fieldMappings);
          action.setParams({
            sourceId: sourceId,
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
            helper.checkDocumentRules(component, selectedTemplateFiles)
              .then($A.getCallback(function (ruleEvaluations) {
                var docsToGenerate = [];

                selectedTemplateFiles.forEach(function (templateFile) {
                  var ruleEvaluation = Array.isArray(ruleEvaluations) ? ruleEvaluations.find(function (re) {
                    return re.contentDocumentId === templateFile.contentDocumentId;
                  }) : null;
                  if ($A.util.isEmpty(ruleEvaluation) || ruleEvaluation.matches) {
                    docsToGenerate.push(templateFile.contentDocumentId);
                  }
                });

                if (docsToGenerate.length > 0) {
                  helper.generateDocumentsV1(component, sourceId, xmlRoot, docsToGenerate);
                } else {
                  helper.endGenerationWithErrorMessage(component, $A.get('$Label.c.NoDocumentsToGenerate'), 'No documents to generate');
                }
              }))
              .catch(function (error) {
                helper.endGenerationWithErrorMessage(component, error, 'Document rule error');
              });
          }
        })
      )
      .catch(
        $A.getCallback(function (error) {
          helper.endGenerationWithErrorMessage(component, error, 'Merge XML generation error');
        })
      );
  },

  checkDocumentRules: function (component, selectedTemplateFiles) {
    var action = component.get('c.checkDocumentRules');
    var templateFilesWithRules = selectedTemplateFiles.filter(function (t) {
      return !$A.util.isEmpty(t.rule);
    });
    var containsRule = !$A.util.isEmpty(templateFilesWithRules);
    action.setParams({
      sourceId: component.get('v.recordId'),
      sourceObject: component.get('v.template').objectMappings.name,
      filesJson: JSON.stringify(templateFilesWithRules),
      isPreview: component.get('v.isPreview')
    });
    return new Promise($A.getCallback(function (resolve, reject) {
      if (containsRule) {
        action.setCallback(this, function (response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            resolve(response.getReturnValue());
          } else {
            reject(stringUtils.getErrorMessage(response));
          }
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    }));
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

  addUnformattedXML: function (query, result, children, field, xmlRoot, depth) {
    var helper = this;
    var fieldXmlUnformatted;
    if (field.startsWith(query.type)) {
      fieldXmlUnformatted = xmlRoot.createElement(field.replace(query.type + '.', '') + 'Unformatted');
    } else {
      fieldXmlUnformatted = xmlRoot.createElement(field + 'Unformatted');
    }
    var fieldValue;
    var newFields = field.split('.');
    if (field === 'CurrentDate') {
      fieldValue = $A.localizationService.formatDate(new Date(), '');
    } else if (depth <= 2) {
      fieldValue = helper.getFieldValue(newFields, result, null, false);
    } else {
      fieldValue = helper.getFieldValue(newFields, children, null, false);
    }
    var nodeValue = xmlRoot.createTextNode(fieldValue);
    fieldXmlUnformatted.appendChild(nodeValue);
    return fieldXmlUnformatted;
  },

  generateXML: function (query, result, children, depth, xmlRoot, fieldMap, isMultiCurrency, previousRelationship) {
    var helper = this;
    var unformattedDataTypes = ['DATE', 'DATETIME', 'TIME', 'DOUBLE', 'PERCENT', 'CURRENCY'];
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

      if (!$A.util.isUndefinedOrNull(format) && unformattedDataTypes.includes(format.type)) {
        objRoot.appendChild(helper.addUnformattedXML(query, result, children, field, xmlRoot, depth));
      }
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
        if ($A.util.isUndefinedOrNull(childData)) continue;
        for (var j = 0; j < childData.length; j++) {
          childXml = helper.generateXML(childQuery, childData[j], children, depth + 1, xmlRoot, fieldMap, isMultiCurrency, query.relationship);
          container.appendChild(childXml);
          objRoot.appendChild(container);
        }
      } else {
        childData = children[childQuery.relationship];
        if ($A.util.isUndefinedOrNull(childData)) continue;
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

  // FIXME: Wire-up selected templateFiles
  generateDocuments: function (component, templateId, sourceId) {
    if ($A.util.isUndefinedOrNull(templateId) || $A.util.isUndefinedOrNull(sourceId)) return;

    component.set('v.isGenerating', true);

    var queueDocumentGeneration = component.get('c.queueDocumentGeneration');
    queueDocumentGeneration.setParams({
      templateId: templateId,
      sourceId: sourceId,
      locale: $A.get('$Locale').langLocale, // TODO: Allow locale selection?
      isPreview: component.get('v.isPreview')
    });
    var self = this;
    queueDocumentGeneration.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var job = response.getReturnValue();
        var taskIds = [];
        var cvTitleByTaskId = {};
        var failedFiles = [];

        job.tasks.forEach(function (task) {
          if (task.complete && !task.success) {
            failedFiles.push({message: task.message, title: task.file.title});
          } else {
            taskIds.push(task.id.value);
            cvTitleByTaskId[task.id.value] = task.file.title;
          }
        });

        var remainingTaskIds;
        if (!$A.util.isEmpty(taskIds)) {
          remainingTaskIds = taskIds.slice(0);
        }

        self.genFileCheckboxToggle(component);
        component.set('v.failedFiles', failedFiles);
        component.set('v.cvTitleByTaskId', cvTitleByTaskId);

        //completionPoll should only be called if remainingTaskIds is defined
        if (!$A.util.isEmpty(remainingTaskIds)) {
          self.completionPoll(component, taskIds, remainingTaskIds, 0);
        } else if (!$A.util.isEmpty(failedFiles)) {
          self.endGenerationError(component, 'Job enqueue failed');
          component.set('v.bannerState', 'error');
          component.set('v.bannerMsg', $A.get('$Label.c.FailedInitiateDocGeneration'));
          component.set('v.finishedGenerating', true);
          component.set('v.isGenerating', false);
        } else { //remainingTaskIds is not defined indicates document generation job was not successfully triggered
          self.handleUndefinedTaskIdResponse(component, failedFiles);
        }
      } else {
        self.handleExceptionInQueueDocumentGeneration(component, response);
      }
    });
    queueDocumentGeneration.setBackground();
    $A.enqueueAction(queueDocumentGeneration);
  },

  completionPoll: function (component, taskIds, remainingTaskIds, runCount) {
    //30s polling
    if (runCount === 16) {
      component.set('v.showTakingTooLongMessage', true);
      component.getEvent('generatedDocs').fire();
      this.endGenerationError(component, 'Document generation is taking too long');
      return;
    }

    var self = this;
    var generatedFiles = component.get('v.generatedFiles');
    var failedFiles = component.get('v.failedFiles');
    var cvTitleByTaskId = component.get('v.cvTitleByTaskId');

    var getTaskStatus = component.get('c.getTaskStatus');
    getTaskStatus.setParams({
      taskIds: remainingTaskIds
    });
    getTaskStatus.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        var tasks = response.getReturnValue();
        var finishedTasks = [];
        var failedTasks = [];

        tasks.forEach(function (task) {
          if (task.complete) {
            if (task.success) {
              finishedTasks.push({
                cv: task.file,
                taskId: task.id.value
              });
            } else {
              failedTasks.push({
                taskId: task.id.value,
                message: task.message
              });
            }
          }
        });

        finishedTasks.forEach(function (task) {
          var taskIndex = taskIds.indexOf(task.taskId);
          var remainingTaskIndex = remainingTaskIds.indexOf(task.taskId);
          generatedFiles[taskIndex] = task.cv;
          remainingTaskIds.splice(remainingTaskIndex, 1);
        });

        failedTasks.forEach(function (task) {
          var remainingTaskIndex = remainingTaskIds.indexOf(task.taskId);
          var templateTitle = cvTitleByTaskId[task.taskId];
          remainingTaskIds.splice(remainingTaskIndex, 1);
          task.title = templateTitle;
          failedFiles.push(task);
        });

        if (remainingTaskIds.length > 0) {
          setTimeout(
            $A.getCallback(function () {
              self.completionPoll(
                component,
                taskIds,
                remainingTaskIds,
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
              self.addDocumentProperties(d, true);
            });
          }

          component.set('v.generatedFiles', generatedFiles);
          component.set('v.failedFiles', failedFiles);
          self.genFileCheckboxToggle(component);

          if (failedFiles.length > 0) {
            component.set('v.bannerState', 'warning');
            component.set(
              'v.bannerMsg',
              $A.get('$Label.c.GeneratorBannerErrorMsg')
            );
            self.endGenerationError(component, 'Failed to generate ' + failedFiles.length + ' file(s)');
          } else {
            var bannerMsg = $A.get('$Label.c.GeneratorBannerSuccessMsg');
            component.set('v.bannerState', 'success');
            component.set('v.bannerMsg', bannerMsg);
            self.endGenerationSuccess(component);
          }
        }
      } else {
        var errorMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.GeneratorCompletionErrorMsg'), stringUtils.getErrorMessage(response));
        component.set('v.finishedGenerating', true);
        component.set('v.isGenerating', false);
        component.set('v.bannerState', 'error');
        component.set('v.bannerMsg', errorMessage);
        self.endGenerationError(component, 'Error while polling for job completion status');
      }
    });
    $A.enqueueAction(getTaskStatus);
  },

  generateDocumentsV1: function (component, startingRecordId, xmlRoot, templateFiles) {
    var template = component.get('v.template');
    var isPreview = component.get('v.isPreview');
    var serializer = new XMLSerializer();
    var xmlString = serializer.serializeToString(xmlRoot); //serializeToString escapes xml for us
    var helper = this;

    var action = component.get('c.queueDocumentGenerationV1');
    action.setParams({
      templateId: template.id,
      sourceId: startingRecordId,
      xmlPayload: xmlString,
      isPreview: isPreview,
      contentDocumentIds: templateFiles
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var taskIds = [];
        var cvTitleByTaskId = {};
        var failedFiles = [];

        //iterate GenV1.Task results object and set populate taskIds, cvTitleByTaskId, failedFiles
        results.forEach(function (object) {
          if (object.status === $A.get('$Label.c.Failure')) {
            failedFiles.push({message: object.message, title: object.file.title});
          } else {
            taskIds.push(object.id.value);
            cvTitleByTaskId[object.id.value] = object.file.title;
          }
        });

        var remainingTaskIds;
        if (!$A.util.isEmpty(taskIds)) {
          remainingTaskIds = taskIds.slice(0);
        }

        helper.genFileCheckboxToggle(component);
        component.set('v.failedFiles', failedFiles);
        component.set('v.cvTitleByTaskId', cvTitleByTaskId);

        //completionPoll should only be called if remainingTaskIds is defined
        if (!$A.util.isEmpty(remainingTaskIds)) {
          helper.completionPollV1(component, taskIds, remainingTaskIds, 0);
        } else if (!$A.util.isEmpty(failedFiles)) {
          helper.endGenerationError(component, 'Job enqueue failed');
          component.set('v.bannerState', 'error');
          component.set('v.bannerMsg', $A.get('$Label.c.FailedInitiateDocGeneration'));
          component.set('v.finishedGenerating', true);
          component.set('v.isGenerating', false);
        } else { //remainingTaskIds is not defined indicates document generation job was not successfully triggered
          helper.handleUndefinedTaskIdResponse(component, failedFiles);
        }
      } else {
        helper.handleExceptionInQueueDocumentGeneration(component, response);
      }
    });

    $A.enqueueAction(action);
  },

  handleExceptionInQueueDocumentGeneration: function (component, response) {
    var errorMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.FailedInitiateDocGeneration'), stringUtils.getErrorMessage(response));
    this.endGenerationWithErrorMessage(component, errorMessage, 'Failed to initiate generation');
  },

  endGenerationWithErrorMessage: function (component, errorMessage, eventMessage) {
    component.set('v.errMsg', errorMessage);
    component.set('v.errType', 'error');
    component.set('v.isGenerating', false);
    this.endGenerationError(component, eventMessage);
  },

  handleUndefinedTaskIdResponse: function (component, failedTasks) {
    var errorMessage = $A.get('$Label.c.FailedInitiateDocGeneration');
    failedTasks.forEach(function (job) {
      errorMessage += job.message;
    });
    component.set('v.errMsg', errorMessage);
    component.set('v.errType', 'error');
    component.set('v.isGenerating', false);
    component.set('v.finishedGenerating', true);
  },

  completionPollV1: function (component, taskIds, remainingTaskIds, runCount) {
    //30s polling
    if (runCount === 16) {
      component.set('v.showTakingTooLongMessage', true);
      component.getEvent('generatedDocs').fire();
      this.endGenerationError(component, 'Document generation is taking too long');
      return;
    }

    var helper = this;
    var generatedFiles = component.get('v.generatedFiles');
    var failedFiles = component.get('v.failedFiles');
    var cvTitleByTaskId = component.get('v.cvTitleByTaskId');
    var action = component.get('c.getTaskStatusV1');

    action.setParams({
      taskIds: remainingTaskIds
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var finishedTasks = [];
        var failedTasks = [];

        results.forEach(function (task) {
          if (task.status === $A.get('$Label.c.Success')) {
            finishedTasks.push({
              taskId: task.id.value,
              cv: task.file
            });
          } else if (task.status === $A.get('$Label.c.Failure')) {
            failedTasks.push({
              taskId: task.id.value,
              message: task.message
            });
          }
        });

        finishedTasks.forEach(function (task) {
          var taskIndex = taskIds.indexOf(task.taskId);
          var remainingTaskIndex = remainingTaskIds.indexOf(task.taskId);
          generatedFiles[taskIndex] = task.cv;
          remainingTaskIds.splice(remainingTaskIndex, 1);
        });

        failedTasks.forEach(function (task) {
          var remainingTaskIndex = remainingTaskIds.indexOf(task.taskId);
          var templateTitle = cvTitleByTaskId[task.taskId];
          remainingTaskIds.splice(remainingTaskIndex, 1);
          task.title = templateTitle;
          failedFiles.push(task);
        });

        if (remainingTaskIds.length > 0) {
          setTimeout(
            $A.getCallback(function () {
              helper.completionPollV1(
                component,
                taskIds,
                remainingTaskIds,
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
            helper.endGenerationError(component, 'Failed to generate ' + failedFiles.length + ' file(s)');
          } else {
            var bannerMsg = $A.get('$Label.c.GeneratorBannerSuccessMsg');
            component.set('v.bannerState', 'success');
            component.set('v.bannerMsg', bannerMsg);
            helper.endGenerationSuccess(component);
          }
        }
      } else {
        var errorMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.GeneratorCompletionErrorMsg'), stringUtils.getErrorMessage(response));
        component.set('v.finishedGenerating', true);
        component.set('v.isGenerating', false);
        component.set('v.bannerState', 'error');
        component.set('v.bannerMsg', errorMessage);
        helper.endGenerationError(component, 'Error while polling for job completion status');
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
          files: fileIds
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
