({
  onInit: function (component, event, helper) {
    //TODO: for DFS-5755, convert hardcoded strings to custom labels
    component.set('v.clmFolderTree', [
      {
        level: 1,
        name: 'Other Sources',
        type: 'root',
        selected: false,
        id: 0,
      },
      {
        level: 2,
        name: 'Salesforce',
        type: 'parent',
        selected: false,
        id: 2
      }
    ]);
    helper.callServer(component, 'c.getAllObjects', false, function (result) {
      result.forEach(function (data) {
        data.selected = false;
      });
      component.set('v.allObjects', result);
      component.set('v.allObjectsList', result);
    });
    //TODO: for DFS-5755, convert hardcoded strings to custom labels
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      primaryButtonLabel: 'Confirm',
      secondaryButtonLabel: 'Cancel',
      primaryButtonVariant: 'brand',
      primaryButtonDisabled: 'true'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);

    });
    //TODO: for DFS-5755, convert hardcoded strings to custom labels
    helper.createComponent(component, 'c:CLMMappingObjectNaming', {
      title: 'Name',
      summary: 'Name',
    }, function (newCmp) {
      component.set('v.modelbody', newCmp);
    });

  },

  back: function (component, event, helper) {
    var currentStep = component.get('v.currentStep');
    if (currentStep === '3') {
      helper.UpdateUI(component, '2');
    } else if (currentStep === '2') {
      helper.UpdateUI(component, '1');
    } else if (currentStep === '1') {
      //fire event to update breadcrumb
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '1' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMBreadcrumbs'
      }, 'CLMBreadcrumbsEvent');
      //fire event to display CLMCardModel
      helper.fireApplicationEvent(component, {
        componentName: 'CLMMappedObjectsHome',
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMIntegrationLayout',
        type: 'show'
      }, 'CLMNavigationEvent');
    }
  },

  gotNextStep: function (component, event, helper) {
    var currentStep = component.get('v.currentStep');
    if (currentStep === '1') {
      helper.UpdateUI(component, '2');
    } else if (currentStep === '2') {
      helper.UpdateUI(component, '3');
    }
  },

  //TODO: for DFS-5755, convert hardcoded strings to custom labels
  openSeeExample: function (component, event, helper) {
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      showPrimaryButton: 'false',
      secondaryButtonVarient: 'brand',
      secondaryButtonLabel: 'Close'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);
    });
    helper.createComponent(component, 'c:CLMFolderExample', {}, function (newCmp) {
      component.set('v.modelbody', newCmp);
      component.set('v.modelTitleText', 'Folder Example');
      component.set('v.showModal', 'true');
      var modelComponent = component.find('popupModel');
      setTimeout($A.getCallback(function () {
        modelComponent.show();
      }), 5);
    });
  },

  //TODO: for DFS-5755, convert hardcoded strings to custom labels
  openWhyExample: function (component, event, helper) {
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      showPrimaryButton: 'false',
      secondaryButtonVarient: 'brand',
      secondaryButtonLabel: 'Close'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);
    });
    helper.createComponent(component, 'c:CLMSelectingFields', {}, function (newCmp) {
      component.set('v.modelbody', newCmp);
      component.set('v.modelTitleText', 'Why am I selecting fields?');
      component.set('v.showModal', 'true');
      var modelComponent = component.find('popupModel');
      setTimeout($A.getCallback(function () {
        modelComponent.show();
      }), 5);
    });
  },

  //TODO: for DFS-5755, convert hardcoded strings to custom labels
  insertPath: function (component, event, helper) {
    var selectedObjDetails = component.get('v.SelectedObjDetails');
    var SelectedObjFieldName = component.get('v.SelectedObjFieldName');
    var insertObj = {
      Name: selectedObjDetails.name,      
      FolderName__c: SelectedObjFieldName,
      Path__c: component.get('v.pathInCLM'),
    };
    helper.callServer(component, 'c.setMappedObject', { eosDetails: insertObj }, function (result) {
      if (result) {
        helper.fireToast(component, stringUtils.format('\'{0}\' object type was successfully mapped to DocuSign CLM.', selectedObjDetails.name), helper.SUCCESS);
        helper.fireApplicationEvent(component, {
          fromComponent: 'CLMSMappedObjectsEdit',
          toComponent: 'CLMSetupLayout',
          type: 'update',
          tabIndex: '3',
        }, 'CLMNavigationEvent');
      }
      else {
        helper.fireToast(component, stringUtils.format('\'{0}\' object type was not mapped to DocuSign CLM.', selectedObjDetails.name), 'error');
      }
    });
  },
  
  //Step 1
  handleSearchObject: function (component) {
    var queryTerm = component.find('search-object').get('v.value');
    var allObjs = component.get('v.allObjects');
    if (queryTerm.length > 1) {
      var fillterdObjs = [];
      allObjs.forEach(function (obj) {
        if (obj.name.toLowerCase().includes(queryTerm.toLowerCase())) {
          fillterdObjs.push(obj);
        }
      });
      component.set('v.allObjectsList', fillterdObjs);
    } else {
      component.set('v.allObjectsList', allObjs);
    }
  },

  onObjSelection: function (component, event) {
    var name = event.currentTarget.id;
    var allObjects = component.get('v.allObjects');
    var allObjectsList = component.get('v.allObjectsList');
    var objDetails = {};
    allObjects.forEach(function (data) {
      if (data.name === name) {
        data.selected = true;
        objDetails = data;
      } else {
        data.selected = false;
      }
    });
    allObjectsList.forEach(function (data) {
      if (data.name === name) {
        data.selected = true;
      } else {
        data.selected = false;
      }
    });
    var clmFolderTree = component.get('v.clmFolderTree');
    var objectIndex = 0;
    clmFolderTree.forEach(function (treeData, index) {
      if (treeData.type === 'sObject') {
        objectIndex = index;
      }
    });
    if (objectIndex) {
      clmFolderTree[objectIndex].name = objDetails.label;
    }
    else {
      clmFolderTree.push({
        level: 3,
        name: objDetails.label,
        type: 'sObject',
        selected: false,
        id: 3
      });
    }
    component.set('v.SelectedObjDetails', objDetails);
    component.set('v.allObjects', allObjects);
    component.set('v.allObjectsList', allObjectsList);
  },

  //Step 2
  onObjFolderSelection: function (component, event, helper) {
    var name = event.currentTarget.id;
    var allObjectFieldsList = component.get('v.allObjectFieldsList');
    allObjectFieldsList.forEach(function (folderData, index) {
      if (folderData.name === name) {
        folderData.selected = !folderData.selected;
        if (folderData.fields.length === 0 && folderData.selected === true) {
          helper.callServer(component, 'c.getAllObjectFields', { apiName: folderData.name, isChild: true }, function (result) {
            var allObjectFieldsListtemp = component.get('v.allObjectFieldsList');
            allObjectFieldsListtemp[index].fields = result;
            component.set('v.allObjectFields', allObjectFieldsListtemp);
            component.set('v.allObjectFieldsList', allObjectFieldsListtemp);
          });
        }
      }
    });
    component.set('v.allObjectFieldsList', allObjectFieldsList);
  },

  handleSearchField: function (component) {
    var queryTerm = component.find('search-field').get('v.value');
    var allObjectFields = JSON.parse(JSON.stringify(component.get('v.allObjectFields')));
    if (queryTerm.length > 1) {
      allObjectFields.forEach(function (objFieldData) {
        var filteredList = [];
        objFieldData.fields.forEach(function (filedData) {
          if (filedData.label.toLowerCase().includes(queryTerm.toLowerCase())) {
            filteredList.push(filedData);
          }
        });
        objFieldData.fields = filteredList;

      });
      component.set('v.allObjectFieldsList', allObjectFields);
    } else {
      component.set('v.allObjectFieldsList', allObjectFields);
    }
  },

  onObjFieldSelection: function (component, event) {
    var label = event.currentTarget.id;
    event.stopPropagation();
    var clmFolderTree = component.get('v.clmFolderTree');
    var SelectedObjDetails = component.get('v.SelectedObjDetails');
    var SelectedObjFieldName = component.get('v.SelectedObjFieldName');
    if (SelectedObjFieldName) {
      SelectedObjFieldName += '{!' + SelectedObjDetails.label + '.' + label + '}';
    }
    else {
      SelectedObjFieldName = '{!' + SelectedObjDetails.label + '.' + label + '}';
    }
    var fieldIndex = 0;
    clmFolderTree.forEach(function (treeData, index) {
      if (treeData.type === 'tail') {
        fieldIndex = index;
      }
    });
    if (fieldIndex) {
      clmFolderTree[fieldIndex].name = SelectedObjFieldName;
    }
    else {
      clmFolderTree.push({
        level: 4,
        name: SelectedObjFieldName,
        type: 'tail',
        selected: false,
        id: 4
      });
    }
    component.set('v.clmFolderTree', clmFolderTree);
    component.set('v.SelectedObjFieldName', SelectedObjFieldName);
  },

  validateFieldSelection: function (component, event) {
    var value = event.getSource().get('v.value');
    var clmFolderTree = component.get('v.clmFolderTree');
    if (!value) {
      component.set('v.SelectedObjFieldName', '');
    }
    else {

      component.set('v.SelectedObjFieldName', value);
    }
    var fieldIndex = 0;
    clmFolderTree.forEach(function (treeData, index) {
      if (treeData.type === 'tail') {
        fieldIndex = index;
      }
    });
    if (fieldIndex) {
      clmFolderTree[fieldIndex].name = value;
    }
    else {
      clmFolderTree.push({
        level: 4,
        name: value,
        type: 'tail',
        selected: false,
        id: 4
      });
    }
    component.set('v.clmFolderTree', clmFolderTree);
  },

  //Step 3
  onCLMfolderSelection: function (component, event) {
    var dataset = JSON.parse(JSON.stringify(event.currentTarget.dataset));
    var clmFolderTree = component.get('v.clmFolderTree');
    var index = parseInt(dataset.id);
    clmFolderTree.forEach(function (treeData, treeIndex) {
      if (treeData.id === index) {
        treeData.selected = true;
        if (treeData.type === 'root') {
          component.set('v.isDeletefolder', true);
          component.set('v.isAddSubfolder', false);
          component.set('v.isRenamefolder', true);
        }
        else if (treeData.type === 'tail') {
          component.set('v.isDeletefolder', true);
          component.set('v.isAddSubfolder', true);
          component.set('v.isRenamefolder', true);
        }
        else {
          component.set('v.isDeletefolder', false);
          component.set('v.isAddSubfolder', false);
          component.set('v.isRenamefolder', false);
        }

        if (treeIndex + 1 < clmFolderTree.length - 1) {
          component.set('v.SelectedFolderParentExample', clmFolderTree[treeIndex].name);
          component.set('v.SelectedFolderExample', clmFolderTree[treeIndex + 1].name);
        }
      }
      else {
        treeData.selected = false;
      }
    });
    component.set('v.clmFolderTree', clmFolderTree);
  },

  //TODO: for DFS-5755, convert hardcoded strings to custom labels
  addSubfolder: function (component, event, helper) {
    var clmFolderTree = component.get('v.clmFolderTree');
    var selectedFolder;
    var selectedFolderIndex;
    clmFolderTree.forEach(function (treeData, treeIndex) {
      if (treeData.selected) {
        selectedFolder = treeData;
        selectedFolderIndex = treeIndex;
      }
    });
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      primaryButtonLabel: 'Confirm',
      secondaryButtonLabel: 'Cancel',
      primaryButtonVariant: 'brand',
      primaryButtonDisabled: 'true'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);
    });
    helper.createComponent(component, 'c:CLMMappingObjectNaming', {
      title: 'Name your sub-folder',
      summary: 'Type in for a static or add fields to create a variable name for your sub-folder.then click confirm once done',
      selectedObjDetails: component.get('v.SelectedObjDetails'),
      buttondisabled: true
    }, function (newCmp) {
      component.set('v.modelbody', newCmp);
    });
    component.set('v.modelTitleText', 'Name Subfolder');
    component.set('v.showModal', 'true');
    component.set('v.modelValueHolder', {
      buttontype: 'subfolder',
      selectedFolder: selectedFolder,
      selectedFolderIndex: selectedFolderIndex,
      buttonDisabled: true
    });
    var modelComponent = component.find('popupModel');
    setTimeout($A.getCallback(function () {
      modelComponent.show();
    }), 5);
  },

  //TODO: for DFS-5755, convert hardcoded strings to custom labels
  renameSubfolder: function (component, event, helper) {
    var clmFolderTree = component.get('v.clmFolderTree');
    var selectedFolder;
    var selectedFolderIndex;
    clmFolderTree.forEach(function (treeData, treeIndex) {
      if (treeData.selected) {
        selectedFolder = treeData;
        selectedFolderIndex = treeIndex;
      }
    });
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      primaryButtonLabel: 'Confirm',
      secondaryButtonLabel: 'Cancel',
      primaryButtonVariant: 'brand',
      primaryButtonDisabled: 'false'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);
    });
    helper.createComponent(component, 'c:CLMMappingObjectNaming', {
      title: 'Name your folder',
      summary: 'Type in for a static or add fields to create a variable name for your sub-folder.then click confirm once done',
      folderName: selectedFolder.name,
      selectedObjDetails: component.get('v.SelectedObjDetails'),
      buttondisabled: false
    }, function (newCmp) {
      component.set('v.modelbody', newCmp);
    });
    component.set('v.modelTitleText', 'Rename Folder');
    component.set('v.showModal', 'true');
    component.set('v.modelValueHolder', {
      buttontype: 'rename',
      selectedFolder: selectedFolder,
      selectedFolderIndex: selectedFolderIndex,
      buttonDisabled: false
    });
    var modelComponent = component.find('popupModel');
    setTimeout($A.getCallback(function () {
      modelComponent.show();
    }), 5);
  },


  deleteSubfolder: function (component, event, helper) {
    var clmFolderTree = component.get('v.clmFolderTree');
    for (var i = 0; i < clmFolderTree.length; i++) {
      if (clmFolderTree[i].selected) {
        clmFolderTree.splice(i, 1);
      }
    }
    clmFolderTree.forEach(function (treeData, index) {
      treeData.level = index + 1;
      treeData.id = treeData.level;
    });
    component.set('v.clmFolderTree', clmFolderTree);
      component.set('v.isDeletefolder', false);
      component.set('v.isAddSubfolder', false);
      component.set('v.isRenamefolder', false);
    helper.updatepath(component);
  },

  //Handlers
  updateTextFromModel: function (component, event, helper) {
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');
    var data = event.getParam('data');
    if (toComponent === 'CLMMappedObjectEdit' && fromComponent !== 'CLMMappedObjectEdit') {
      if (type === helper.ACTIONUPDATE) {
        var modelValueHolder = component.get('v.modelValueHolder');
        modelValueHolder.folderName = data.value;
        component.set('v.modelValueHolder', modelValueHolder);
      }
    }
  },

  updateFromPathUI: function (component, event, helper) {
    var navigateTo = event.getParam('navigateTo');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    if ((toComponent === 'CLMCardModel' || toComponent === 'ANY') && fromComponent !== 'CLMCardModel') {
      if (navigateTo !== undefined) {
        helper.UpdateUI(component, navigateTo.index);
      }
    }
  },
  
  handleConfirm: function (component, event, helper) {
    var modelValueHolder = component.get('v.modelValueHolder');
    var clmFolderTree = component.get('v.clmFolderTree');
    if (modelValueHolder.buttontype === 'rename') {
      clmFolderTree[modelValueHolder.selectedFolderIndex].name = modelValueHolder.folderName;
      component.set('v.clmFolderTree', clmFolderTree);
      component.set('v.showModal', 'false');
      helper.updatepath(component);
    }
    else if (modelValueHolder.buttontype === 'subfolder') {
      clmFolderTree = helper.sortTree(clmFolderTree);
      clmFolderTree.forEach(function (treeData) {
        if (treeData.level > clmFolderTree[modelValueHolder.selectedFolderIndex].level) {
          treeData.level = treeData.level + 1;
          treeData.id = treeData.level + 1;
        }
        else {
          treeData.id = treeData.level;
        }
      });
      clmFolderTree.push({
        level: clmFolderTree[modelValueHolder.selectedFolderIndex].level + 1,
        name: modelValueHolder.folderName,
        type: 'folder',
        selected: false,
        id: clmFolderTree[modelValueHolder.selectedFolderIndex].level + 1
      });
      clmFolderTree = helper.sortTree(clmFolderTree);
      component.set('v.clmFolderTree', clmFolderTree);
      component.set('v.showModal', 'false');
      helper.updatepath(component);
    }
  },

  closeModal: function (component) {
    component.set('v.showModal', 'false');
    component.set('v.modelValueHolder', {});
  }
});