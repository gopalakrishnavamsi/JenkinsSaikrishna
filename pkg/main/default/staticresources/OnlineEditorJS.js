/* global jQuery, RemoteActions, Configuration, Labels, DSEditor, Visualforce, $Lightning */
jQuery.noConflict();

// FIXME: Split JS file between edit and generate VF pages. Can share common functions in 3rd JS file.
// FIXME: Use consistent variable naming matching those in Apex layer.
jQuery(document).ready(function ($) {

  var _toolTip = false;
  var _currentProgressStep = null;
  var _toastComponent;
  var _userEvents;
  var _sessionType;
  var _layoutMap = {};
  var EventLabels = Object.freeze({
    CREATE_TEMPLATE: 'Create Gen Template',
    UPDATE_TEMPLATE: 'Update Gen Template',
    PUBLISH_BUTTON: 'Publish Gen Button',
    PREVIEW_DOCUMENT: 'Preview Gen Document',
    GENERATE_DOCUMENT: 'Generate Gen Document',
    templateUndefined: 'Template Undefined',
    navigationError: 'Handle Navigation error'
  });  

  var Elements = Object.freeze({
    spinner1: $('#ds-spinner'),
    spinner2: $('#ds-spinner2'),
    buttons: {
      cancelPublish: $('#onlineEditorPublishCancel'),
      cancelTemplate: $('#onlineEditorTemplateCancel'),
      publish: $('#onlineEditorPublish'),
      saveClose: $('#onlineEditorSaveClose')
    }
  });

  if (Configuration.template) {
    $('#fileNameInput').val(Configuration.template.fileName);
    if (Configuration.template.fileSuffix) $('#fileSuffix').val(Configuration.template.fileSuffix);
  }

  var _editor = new DSEditor({
    api: {
      getMergeFields: getMergeFields,
      getEntityRecords: getEntityRecords,
      getMergeData: getMergeData
    }
  });

  displayStartupElements();

  Elements.spinner1.hide();
  Elements.spinner2.hide();

  hideAll();
  hideAllButtons();

  createUserEventsComponent()
  .then(function(component) {
    _userEvents = component;

    if (Configuration.isGenerating) _sessionType = EventLabels.GENERATE_DOCUMENT;
    else Configuration.isEditing ? EventLabels.UPDATE_TEMPLATE : EventLabels.CREATE_TEMPLATE;

    _userEvents.time(_sessionType);
    _userEvents.addProperties(getBaseEventProps()) 

    if (navUtils.isIE()) $('#IEWarning').show();
    else if (Configuration.hasInitError) {
      createToastComponent(Configuration.initError, 'error');
      _userEvents.error(
        _sessionType, 
        {

        }, 
        Configuration.initError 
      )
    }
    else if (!Configuration.isGenerating) handleStepNavigation(1).onStart();
  })
  .catch(function(err) {
    createToastComponent(err, 'error');
  });


  function getBaseEventProps() {

    if (!Configuration || !Configuration.template) return { 
      'Product': 'Gen',
      'Template Type': 'Online Editor'
    };

    return {
      'Product': 'Gen',
      'Template Type': 'Online Editor',
      'Source Object': Configuration.template.sourceObject ? Configuration.template.sourceObject : undefined,      
      'Template Name': Configuration.template.name ?  Configuration.template.name : undefined,
      'Template Id': Configuration.template.id ?  Configuration.template.id : undefined
    };
  }

  function getSpringTemplateIdToString(template) {
    return template && template.springTemplateId ? template.springTemplateId.value : null;
  }


  function getMessage(message) {
    // TODO: Check other types. Get response body or other error details.
    if (message instanceof Response) {
      return message.statusText;
    }
    return message;
  }

  function createToastComponent(message, mode) {
    if (_toastComponent) _toastComponent.destroy();
    $Lightning.use(Configuration.namespace + ':LightningOutApp', function () {
      $Lightning.createComponent(Configuration.namespace + ':Toast',
        {
          showToast: true,
          visualforce: true,
          message: getMessage(message),
          mode: mode
        },
        'toastNotificationContainer',
        function (cmp) {
          _toastComponent = cmp;
          if (_toastComponent && mode === 'success') {
            window.setTimeout($A.getCallback(function () {
              if (_toastComponent) {
                _toastComponent.destroy();
                _toastComponent = null;
              }
            }), 3000);
          }
        }
      );
    });
  }

  function createUserEventsComponent() {
    return new Promise(function (resolve, reject) {
      try {
        $Lightning.use(Configuration.namespace + ':LightningOutApp', function () {
          $Lightning.createComponent(Configuration.namespace + ':UserEvents',
            null,
            'userEventsContainer',
            function (cmp) {
              resolve(cmp);
            }
          );
        });  
      } catch(err) {
        reject(err);
      }       
    })
  }

  function getMergeFields() {
    return new Promise(
      function (resolve, reject) {
        if (!Configuration.template.sourceObject) reject(Labels.templateInvalidSourceLabel);
        try {
          Visualforce.remoting.Manager.invokeAction(
            RemoteActions.getMergeFields,
            Configuration.template.sourceObject,
            function (result, event) {
              if (event.status) {
                resolve(result);
              } else {
                _userEvents.error(
                  EventLabels.PREVIEW_DOCUMENT, 
                  {

                  }, 
                  event.message
                );
                reject(event.message);
              }
            });
        } catch (err) {
          _userEvents.error(
            EventLabels.PREVIEW_DOCUMENT, 
            {

            }, 
            err
          );
          reject(err);
        }
      }
    );
  }

  function getMergeData(sourceId, queryTree) {
    return new Promise(
      function (resolve, reject) {
        if (!sourceId) reject(Labels.templateInvalidSourceLabel);
        try {
          Visualforce.remoting.Manager.invokeAction(
            RemoteActions.getMergeData,
            sourceId,
            JSON.stringify(queryTree),
            function (result, event) {
              if (event.status) {
                resolve(result);
              } else {
                _userEvents.error(
                  EventLabels.PREVIEW_DOCUMENT, 
                  {

                  }, 
                  event.message
                );                
                reject(event.message);
              }
            });
        } catch (err) {
          _userEvents.error(
            EventLabels.PREVIEW_DOCUMENT, 
            {

            }, 
            err
          );
          reject(err);
        }
      }
    );
  }

  function getEntityRecords(index, searchValue) {
    return new Promise(
      function (resolve, reject) {
        try {
          var pageIndex = index === undefined || index === null ? 0 : index;
          Visualforce.remoting.Manager.invokeAction(
            RemoteActions.getEntityRecords,
            Configuration.template.sourceObject,
            pageIndex,
            searchValue || '',
            function (result, event) {
              if (event.status) {
                resolve(result);
              } else {
                _userEvents.error(
                  EventLabels.PREVIEW_DOCUMENT, 
                  {

                  }, 
                  event.message
                );
                reject(event.message);
              }
            });             
        } catch (err) {
          _userEvents.error(
            EventLabels.PREVIEW_DOCUMENT, 
            {

            }, 
            err
          );
          reject(err);
        }
      }
    );
  }  

  function deleteTemplate(templateId, isEditing) {
    return new Promise(
      function (resolve, reject) {
        if (isEditing || !templateId) {
          resolve(false);
        } else {
          try {
            Visualforce.remoting.Manager.invokeAction(
              RemoteActions.deleteTemplate,
              templateId,
              function (result, event) {
                if (event.status) {
                  resolve(result);
                } else {
                  reject(event.message);
                }
              });
          } catch (err) {
            reject(err);
          }
        }
      });
  }

  function getObjectLayouts(sourceObject) {
    return new Promise(
      function (resolve, reject) {
        try {
          Visualforce.remoting.Manager.invokeAction(
            RemoteActions.getLayouts,
            sourceObject,
            function (result, event) {
              if (event.status) {
                resolve(result);
              } else {
                reject(event.message);
              }
            });
        } catch (err) {
          reject(err);
        }
      });
  }

  function getTemplateFolderId() {
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.getTemplateFolderId,
          function (result, event) {
            if (event.status) {
              resolve(result);
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }


  function generateUploadToken(entityId) {
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.generateUploadToken,
          entityId,
          function (result, event) {
            if (event.status) {
              resolve(result);
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function updateTemplateIdInSalesforce(springTemplateIdUUID) {
    var clonedTemplateConfiguration = Object.assign({}, Configuration.template);
    clonedTemplateConfiguration.springTemplateId = springTemplateIdUUID;
    var templateJson = JSON.stringify(clonedTemplateConfiguration);
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.updateTemplateIdInSalesforce,
          templateJson,
          function (result, event) {
            if (event.status) {
              resolve(Object.freeze(result));
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function getSpringTemplateIdInUUIDFormat(springTemplateId) {
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.getSpringTemplateIdInUUIDFormat,
          springTemplateId,
          function (result, event) {
            if (event.status) {
              resolve(result);
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function updateObjectLayouts(sourceObject, selectedLayouts, parameters) {
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.updateLayouts,
          sourceObject,
          JSON.stringify(selectedLayouts),
          JSON.stringify(parameters),
          function (result, event) {
            if (event.status) {
              resolve(result);
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function updateFileDetailsInSalesforce(fileName, fileSuffix) {
    var clonedTemplateConfiguration = Object.assign({}, Configuration.template);
    clonedTemplateConfiguration.fileName = fileName;
    clonedTemplateConfiguration.fileSuffix = fileSuffix;
    var templateJson = JSON.stringify(clonedTemplateConfiguration);
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.updateFileDetailsInSalesforce,
          templateJson,
          function (result, event) {
            if (event.status) {
              resolve(Object.freeze(result));
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function generateDownloadToken(springTemplateId) {
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.generateDownloadToken,
          springTemplateId,
          function (result, event) {
            if (event.status) {
              resolve(result);
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function saveAttachments(templateId, sourceId, htmlData) {
    return new Promise(function (resolve, reject) {
      try {
        Visualforce.remoting.Manager.invokeAction(
          RemoteActions.saveAttachments,
          sourceId,
          htmlData,
          templateId,
          function (result, event) {
            if (event.status) {
              resolve(result);
            } else {
              reject(event.message);
            }
          });
      } catch (err) {
        reject(err);
      }
    });
  }

  function launchOnlineEditor(element, template, isEditing) {
    return isEditing && template && template.springTemplateId
      ? generateDownloadToken(getSpringTemplateIdToString(template))
        .then(function (accessToken) {
          return renderEditor(accessToken, element, template.name, null, false);
        })
        .then(function () {
          return template;
        })
      : new Promise(function (resolve, reject) {
        try {
          _editor.render(element);
          resolve(template);
        } catch (err) {
          reject(err);
        }
      });
  }

  function exportDocument(type) {
    return _editor.exportDocument(type)
      .then(function (data) {
        if (data && data.success) {
          return data.data;
        }
        throw data ? data.errors : Labels.templateExportDataIsUndefinedLabel;
      });
  }

  function addOnlineEditorActions(layout, buttonApiName, buttonLabelName) {
    layout.actions = [];
    layout.actions.push({
      type: Configuration.layoutActionType,
      name: buttonApiName,
      label: buttonLabelName
    });
    return layout;
  }

  function removeOnlineEditorActions(layout) {
    layout.actions = [];
    return layout;
  }

  function hasOnlineEditorAction(layout, templateId) {
    if (layout.actions && layout.actions.length !== 0) {
      for (var j = 0; j < layout.actions.length; j++) {
        if (layout.actions[j].type === Configuration.layoutActionType && layout.actions[j].name.indexOf(templateId) >= 0) {
          return true;
        }
      }
    }
    return false;
  }

  //UI Handlers
  function handleStepNavigation(step) {
    if (step === null || step === undefined || step > 2 || step < 1) {
      createToastComponent(Labels.templateInvalidPathLabel, 'error');
      _userEvents.error(
        _sessionType, 
        {

        }, 
        EventLabels.navigationError 
      )
      return;
    }

    _currentProgressStep = step;

    var activeClassName = 'slds-is-active';
    var currentClassName = 'slds-is-current';
    var completedClassName = 'slds-is-complete';
    var incompleteClassName = 'slds-is-incomplete';

    var progressStepElements = [
      $('#onlineEditorStep1'),
      $('#onlineEditorStep2')
    ];

    progressStepElements.forEach(function (stepElement, index) {
      var stepNum = index + 1;
      if (stepNum === step) {
        stepElement.addClass(activeClassName);
        stepElement.addClass(currentClassName);
        stepElement.removeClass(completedClassName);
        stepElement.removeClass(incompleteClassName);
      } else if (stepNum < step) {
        stepElement.removeClass(activeClassName);
        stepElement.removeClass(currentClassName);
        stepElement.addClass(completedClassName);
        stepElement.removeClass(incompleteClassName);
      } else {
        stepElement.removeClass(activeClassName);
        stepElement.removeClass(currentClassName);
        stepElement.removeClass(completedClassName);
        stepElement.addClass(incompleteClassName);
      }
    });

    switch (step) {
      case 1:
        return {
          onStart: function () {
            hideAll();
            $('#onlineEditorToolBar').show();
            $('#topPanel').show();
            $('#onlineEditor').show();
            renderOnlineEditor();
            //Buttons
            //Step 1
            Elements.buttons.cancelTemplate.show();
            Elements.buttons.saveClose.show();
            //Step 2
            Elements.buttons.cancelPublish.hide();
            Elements.buttons.publish.hide();
          }
        };
      case 2:
        return {
          onStart: function () {
            $('#onlineEditorToolBar').hide();
            showSpinner();
          },

          onEnd: function () {
            $('#onlineEditorToolBar').show();
            Elements.spinner1.hide();
            $('#inputFilePanel').show();
            //Step 1
            Elements.buttons.cancelTemplate.hide();
            Elements.buttons.saveClose.hide();
            //Step 2
            Elements.buttons.cancelPublish.show();
            Elements.buttons.publish.show();
          }
        };
    }
  }

  function renderOnlineEditor() {
    launchOnlineEditor(document.getElementById('onlineEditor'), Configuration.template, Configuration.isEditing);
  }

  function hideAllButtons() {
    //Step 1
    Elements.buttons.cancelTemplate.hide();
    Elements.buttons.saveClose.hide();
    //Step 2
    Elements.buttons.cancelPublish.hide();
    Elements.buttons.publish.hide();
  }

  function setLayoutOptions(layouts, templateId) {
    return new Promise(
      function (resolve, reject) {
        try {
          var layoutsById = {};
          for (var i = 0; i < layouts.length; i++) {
            var layout = layouts[i];
            layoutsById[layout.id] = layout;
            var checked = !Configuration.isEditing || hasOnlineEditorAction(layout, templateId) ? 'checked' : '';
            $('#layoutCheckboxes').append('<div class="slds-form-element slds-p-bottom--small"><div class="slds-form-element__control"><div class="slds-checkbox"><input type="checkbox" class="layout-checkbox" name="layoutCheckboxI" id="' + layout.id + '" value="' + layout.id + '" ' + checked + '/><label class="slds-checkbox__label" for="' + layout.id + '"><span class="slds-checkbox_faux layout-default"></span><span class="slds-form-element__label onlineEditorContentText">' + layout.name + '</span></label></div></div></div>');
          }
          resolve(layoutsById);
        } catch (err) {
          reject(err);
        }
      });
  }

  function hideAll() {
    $('#onlineEditorGenerator').hide();
    $('#onlineEditor').hide();
    $('#topPanel').hide();
    $('#onlineEditorToolBar').hide();
    $('#inputFilePanel').hide();
    $('#namingHelp').hide();
  }

  function displayStartupElements() {
    $('.hide-on-start-up').removeClass('hide-on-start-up');
  }

  function showSpinner() {
    hideAll();
    Elements.spinner1.show();
  }

  //Navigate back to step 1
  function editOnlineEditorTemplateDetails() {
    var navStep = handleStepNavigation(1);
    navStep.onStart();
  }

  Elements.buttons.cancelTemplate.click(function () {
    deleteTemplate(Configuration.template.id, Configuration.isEditing)
      .then(function () {
        navUtils.navigateToUrlOnlineEditor(Configuration.templateListUrl, true);
      })
      .catch(function (error) {
        createToastComponent(error, 'error');
        _userEvents.error(
          _sessionType, 
          {

          }, 
          error
        );
      });
  });

  $('#fileNamingRules').hover(function () {
    if (_toolTip) {
      $('#namingHelp').hide();
      _toolTip = false;
    } else {
      $('#namingHelp').show();
      _toolTip = true;
    }
  });

  function getUploadEntityId(templateId) {
    return templateId ? new Promise(function (resolve) {
      resolve(templateId);
    }) : getTemplateFolderId();
  }

  function onlineEditorSaveClose(templateId, springTemplateId, isEditing, templateName) {
    var navStep = handleStepNavigation(2);
    navStep.onStart();
    var editorData;
    // FIXME: Consolidate some of these actions.
    exportDocument()
      .then(function (data) {
        editorData = data;
        return getUploadEntityId(springTemplateId);
      })
      .then(function (entityId) {
        return generateUploadToken(entityId);
      })
      .then(function (token) {
        return isEditing
          ? SpringCM.Methods.Upload.uploadNewDocumentVersionBytes(
            token.apiUploadBaseUrl,
            token.token,
            token.accountId.value,
            token.entityId.value,
            editorData,
            templateName + '.html')
          : SpringCM.Methods.Upload.uploadNewDocumentBytes(
            token.apiUploadBaseUrl,
            token.token,
            token.accountId.value,
            token.entityId.value,
            editorData,
            templateName + '.html');
      })
      .then(function (response) {
        if (!response || !response.Href) throw 'SCM href undefined';
        return response.Href.substring(response.Href.lastIndexOf('/') + 1);
      })
      .then(function (springTemplateGUID) {
        return getSpringTemplateIdInUUIDFormat(springTemplateGUID);
      })
      .then(function (springTemplateIdUUID) {
        return updateTemplateIdInSalesforce(springTemplateIdUUID);
      })
      .then(function (t) {
        Configuration.template = t;
        return getObjectLayouts(t.sourceObject);
      })
      .then(function (layouts) {
        if (!$('#layoutCheckboxes').is(':empty')) return null;
        return setLayoutOptions(layouts, Configuration.template.id);
      })
      .then(function (layoutsById) {
        _layoutMap = layoutsById;
        createToastComponent((isEditing ? Labels.templateUpdatedLabel : Labels.templateCreatedLabel).replace('{0}', Configuration.template.name), 'success');
        _userEvents.success(
          _sessionType, 
          { 
            springTemplateId: springTemplateId 
          } 
        );
        navStep.onEnd();
      })
      .catch(function (error) {
        Elements.spinner1.hide();
        _userEvents.error(
          _sessionType, 
          { 
            springTemplateId: springTemplateId 
          }, 
          error
        );
        createToastComponent(error, 'error');
      });
  }

  function onlineEditorPublish(template, buttonLabel) {
      var buttonApiName = template.id;
      var selectedLayouts = [];

      return new Promise(function(resolve, reject) {
        if (!template) reject(Labels.templateUndefinedLabel);

        showSpinner();
        
        updateFileDetailsInSalesforce($('#fileNameInput').val(), $('#fileSuffix').val())
        .then(function (t) {
          Configuration.template = t;
          buttonApiName = Configuration.layoutActionName + buttonApiName;
          
          $.each($('input[name="layoutCheckboxI"]:checked'), function () {
            var layout = _layoutMap[$(this).val()];
            delete _layoutMap[$(this).val()];
            selectedLayouts.push(addOnlineEditorActions(layout, buttonApiName, buttonLabel));
          });

          for (var layoutId in _layoutMap) {
            if (_layoutMap.hasOwnProperty(layoutId)) {
              selectedLayouts.push(removeOnlineEditorActions(_layoutMap[layoutId]));
            }
          }

          var parameters = {
            genButtonApiName: buttonApiName,
            genButtonLabel: buttonLabel,
            genTemplateId: t.id
          };

          return updateObjectLayouts(template.sourceObject, selectedLayouts, parameters);
        })
        .then(function() {
          _userEvents.success(
            EventLabels.PUBLISH_BUTTON,
            {
              buttonLabel: buttonLabel,
              buttonApiName: buttonApiName,
              layouts: selectedLayouts.map(function(layout) {
                return {
                  name: layout.name, 
                  id: layout.id
                }
              })
            }
          );

          resolve(true);
        })
      });
  }

  function onlineEditorPublishCancel(templateId, isEditing) {
    deleteTemplate(templateId, isEditing)
      .then(function () {
        navUtils.navigateToUrlOnlineEditor(Configuration.templateListUrl, true);
      })
      .catch(function (error) {
        _userEvents.error(
          _sessionType, 
          {

          }, 
          error
        );
        createToastComponent(error, 'error');
      });
  }

  Elements.buttons.cancelPublish.click(function () {
    onlineEditorPublishCancel(Configuration.template.id, Configuration.isEditing);
  });

  Elements.buttons.saveClose.click(function () {
    onlineEditorSaveClose(Configuration.template.id, getSpringTemplateIdToString(Configuration.template),
      Configuration.isEditing, Configuration.template.name);
  });

  Elements.buttons.publish.click(function () {
    onlineEditorPublish(Configuration.template, $('#onlineEditorButtonNameInput').val())
      .then(function () {
        createToastComponent(Labels.templatePublishedLabel.replace('{0}', Configuration.template.name), 'success');
        window.setTimeout(function () {
          if (_toastComponent) _toastComponent.destroy();
          navUtils.navigateToSObject(Configuration.template.id);
        }, 3000);
      })
      .catch(function (err) {
        _userEvents.error(
          _sessionType, 
          {

          }, 
          err
        );
        createToastComponent(err, 'error');
      });
  });


  //Step 1
  $('#onlineEditorStepLink1').click(function () {
    hideAll();
    editOnlineEditorTemplateDetails();
  });

  //Step 2
  $('#onlineEditorStepLink2').click(function () {
    if (_currentProgressStep === 2) return;
    var template = Configuration.template;
    if (!template || !template.id || !template.springTemplateId || !template.sourceObject) {
       _userEvents.error(
        _sessionType, 
        {

        }, 
        EventLabels.templateUndefined
      );
      createToastComponent(Labels.templateSaveValidationLabel, 'error');
      return;
    }
    hideAll();
    var navStep = handleStepNavigation(2);
    navStep.onStart();
    if (!$('#layoutCheckboxes').is(':empty')) {
      navStep.onEnd();
    } else {
      getObjectLayouts(template.sourceObject)
        .then(function (result) {
          return setLayoutOptions(result, template.id);
        })
        .then(function (layoutsById) {
          _layoutMap = layoutsById;
          navStep.onEnd();
        })
        .catch(function (error) {
          createToastComponent(error, 'error');
          _userEvents.error(
            _sessionType, 
            {
              layouts : Object.keys(_layoutMap)
            }, 
            error
          );
        });
    }
  });

  // OnlineEditor document generation
  $('#onlineEditorDocumentGenerator').ready(function () {
    if (!Configuration.isGenerating) return; // This is necessary for now. This ready event fires even on OnlineEditor page.

    if (Configuration.template) {
      $('#onlineEditorGenerator').show();
      Elements.spinner2.show();
      generateDownloadToken(getSpringTemplateIdToString(Configuration.template))
        .then(function (accessToken) {
          return renderEditor(accessToken, document.getElementById('onlineEditorGenerator'), Configuration.template.name, Configuration.sourceId, true);
        })
        .then(function () {
          Elements.spinner2.hide();
        })
        .catch(function (err) {
          createToastComponent(err, 'error');
          _userEvents.error(
            _sessionType, 
            {

            }, 
            err
          );
        });
    } else {
      createToastComponent(Labels.templateUndefinedLabel, 'error');
      _userEvents.error(
        _sessionType, 
        {

        }, 
        EventLabels.templateUndefined
      );
    }
  });

  function renderEditor(limitedAccessToken, element, templateName, sourceId, isGenerating) {
    return new Promise(function (resolve) {
      new SpringCM.Widgets.Download.downloadDocument(
        limitedAccessToken.apiDownloadBaseUrl,
        limitedAccessToken.token,
        limitedAccessToken.accountId.value,
        limitedAccessToken.entityId.value,
        templateName + '.html',
        false)
        .then(function (data) {
          var reader = new FileReader();
          reader.readAsArrayBuffer(data);
          reader.onloadend = function () {
            // FIXME: Typed arrays not available in ES5, but no good alternative here.
            var fileBytes = new Uint8Array(reader.result); // eslint-disable-line no-undef
            _editor.render(element, isGenerating);
            _editor.importDocument(fileBytes, sourceId);
            resolve(true);
          };
        });
    });
  }

  $('#onlineEditorCancelGeneration').click(function () {
    navUtils.navigateToSObject(Configuration.sourceId);
  });

  function getPlaceholderRecipients(templateName) {
    var rs = _editor.getRecipients();
    return {
      templateName: templateName,
      recipients: rs ? rs.filter(function (r) {
        return r && r.recipientId;
      }).map(function (r) {
        return {
          envelopeRecipientId: r.recipientId,
          role: r.placeholderName
        };
      }) : null
    };
  }

  $('#onlineEditorSendForSignature').click(function () {
    hideAll();
    Elements.spinner2.show();
    if (Configuration.template) {
      exportDocument('html')
        .then(function (htmlData) {
          return saveAttachments(Configuration.template.id, Configuration.sourceId, htmlData);
        })
        .then(function (attachmentId) {
          var pageUrl = Configuration.sendingUrl;
          if (pageUrl.indexOf('?') !== -1) {
            pageUrl += '&';
          } else {
            pageUrl += '?';
          }
          // noinspection SpellCheckingInspection
          pageUrl += 'sId=' + encodeURIComponent(Configuration.sourceId)
            + '&files=' + encodeURIComponent(attachmentId)
            + '&phrs=' + encodeURIComponent(JSON.stringify(getPlaceholderRecipients()))
            + '&lock=1'
            + '&sendNow=1';
          Elements.spinner2.hide();
          window.open(pageUrl, '_self');
          _userEvents.success(
            _sessionType, 
            {

            }
          );          
        })
        .catch(function (err) {
          createToastComponent(err, 'error');
          _userEvents.error(
            _sessionType, 
            {

            }, 
            err
          );
        });
    } else {
      createToastComponent(Labels.templateUndefinedLabel, 'error');
      _userEvents.error(
        _sessionType, 
        {

        },
        EventLabels.templateUndefined
      );
    }
  });

  var renderTemplateDetails = function () {
    window.location.reload();
  };

  $('#onlineEditorEdit').click(function () {
    $Lightning.use(Configuration.namespace + ':LightningOutApp', function () {
      $Lightning.createComponent(Configuration.namespace + ':OnlineEditorTemplateEdit',
        {
          recordId: Configuration.template.id,
          namespace: Configuration.namespace,
          renderTemplateDetails: renderTemplateDetails
        },
        'editModal',
        function () {

        }
      );
    });
  });
});