({
  onInit: function (component, event, helper) {
    helper.checkCurrentObjectFields(component, event, helper);
  },

  checkCurrentObjectFields: function (component, event, helper) {
    if (!helper.isNotUndefinedAndEmpty(component.get('v.currentObjectFields'))) {
      var currentObjectName = component.get('v.currentObjectName');
      var depth = component.get('v.currentDepth');
      helper.fetchMergeFields(component, event, helper, currentObjectName, depth)
        .then($A.getCallback(function (response) {
          component.set('v.currentObjectFields', response);
          helper.setRelationshipAttributes(component, event, helper);
          helper.setMergeTreeAttributes(component, event, helper);
          helper.trackCurrentFieldType(component);
          helper.setToken(component);
        }))
        .catch(function (error) {
          helper.showToast(component, error, 'error');
          component.set('v.isLoading', false);
        });
    } else {
      helper.setRelationshipAttributes(component, event, helper);
      helper.setMergeTreeAttributes(component, event, helper);
      helper.trackCurrentFieldType(component);
      helper.setToken(component);
    }
  },

  fetchMergeFields: function (component, event, helper, objectName, depth) {
    var action = component.get('c.getMergeFields');
    action.setParams({
      sObjectType: objectName,
      depth: depth
    });
    return new Promise($A.getCallback(function (resolve, reject) {
      action.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      }));
      action.setBackground();
      $A.enqueueAction(action);
    }));
  },

  setRelationshipAttributes: function (component, event, helper) {
    if (helper.isNotUndefinedAndEmpty(component.get('v.currentObjectFields'))) {
      helper.setLookUpFieldExists(component, event, helper);
      helper.setChildFieldExists(component, event, helper);
    }
  },

  setLookUpFieldExists: function (component, event, helper) {
    if (helper.doesFilterExist(component.get('v.currentObjectFields'), 'REFERENCE')) {
      component.set('v.lookupFieldExists', true);
    }
  },

  setChildFieldExists: function (component, event, helper) {
    if (helper.doesFilterExist(component.get('v.currentObjectFields'), 'CHILD_RELATIONSHIP')) {
      component.set('v.childFieldExists', true);
    }
  },

  doesFilterExist: function (objectInstance, filterValue) {
    return objectInstance.filter(function (obj) {
      return obj.hasRelationship && obj.type === filterValue;
    }).length > 0;
  },

  isNotUndefinedAndEmpty: function (objectInstance) {
    var result = false;
    if (!$A.util.isUndefinedOrNull(objectInstance) && !$A.util.isEmpty(objectInstance)) {
      result = true;
    }
    return result;
  },

  showToast: function (component, mode, msg) {
    var evt = component.getEvent('showToast');
    evt.setParams({
      data: {
        msg: msg,
        variant: mode
      }
    });
    evt.fire();
  },

  fieldSelectionChange: function (component, event, helper) {
    var type = helper.getParentTypeOfField(component);
    var currentKey = component.get('v.currentMergeTreeKey');
    var currentDepth = component.get('v.currentDepth');
    var fieldIndex = component.get('v.fieldIndex');

    var parentNodeOfField = component.get('v.mergeFieldTree').find(function (node) {
      return helper.isParentOfField(
        node,
        {
          type: type,
          depth: currentDepth,
          key: currentKey
        });
    });

    if (helper.checkDuplicateField(component, event, helper, parentNodeOfField)) {
      helper.showToast(component, 'warning', stringUtils.format($A.get('$Label.c.FieldPickerFieldExists_1'), event.getSource().get('v.value')));
      component.set('v.selectedMergeField', parentNodeOfField.fields[fieldIndex]);
      component.set('v.selectedMergeFieldName', parentNodeOfField.fields[fieldIndex].name);
      return;
    } else {
      helper.fireChangeFieldSelection(component, event, helper);
      helper.setToken(component);
    }
  },

  isParentOfField: function (mergeFieldTreeNode, parentData) {
    var type = parentData.type;
    var key = parentData.key;

    switch (type) {
      case 'ROOT':
        return mergeFieldTreeNode.type === type;
      case 'REFERENCE':
      case 'CHILD_RELATIONSHIP':
        return mergeFieldTreeNode.type === type && mergeFieldTreeNode.key === key;
      default:
        return false;
    }
  },

  setMergeTreeAttributes: function (component, event, helper) {
    var selectedMergeField = component.get('v.selectedMergeField');
    if (selectedMergeField.name !== '' &&
      (selectedMergeField.type === 'CHILD_RELATIONSHIP' || selectedMergeField.type === 'REFERENCE')) {
      var nextMergeTreePath = helper.isNotUndefinedAndEmpty(component.get('v.currentMergeTreePath')) ? component.get('v.currentMergeTreePath').slice() : [];
      var nextMergeTreeKey = helper.isNotUndefinedAndEmpty(component.get('v.currentMergeTreeKey')) ? component.get('v.currentMergeTreeKey') : '';
      if (selectedMergeField.type === 'REFERENCE') {
        nextMergeTreePath.push(selectedMergeField.relationship);
      }
      nextMergeTreeKey = nextMergeTreeKey.length > 0 ? nextMergeTreeKey.concat('.', selectedMergeField.relationship) : selectedMergeField.relationship;
      component.set('v.nextMergeTreePath', nextMergeTreePath);
      component.set('v.nextMergeTreeKey', nextMergeTreeKey);
    }
  },

  mergeFieldTreeChangeHandler: function (component, event, helper) {
    helper.trackCurrentFieldType(component);
    helper.setToken(component);
  },

  checkDuplicateField: function (component, event, helper, parentNodeOfField) {
    var duplicateFieldFound = false;
    var selectedFieldValue = event.getSource().get('v.value');
    if (helper.isNotUndefinedAndEmpty(parentNodeOfField)) {
      parentNodeOfField.fields.forEach(function (field) {
        if (helper.isDuplicateField(field, selectedFieldValue)) {
          duplicateFieldFound = true;
        }
      });
    }
    return duplicateFieldFound;
  },

  isDuplicateField: function (field, selectedFieldValue) {
    if (field.type === 'CHILD_RELATIONSHIP') {
      return field.relationship === selectedFieldValue;
    } else {
      return field.name === selectedFieldValue;
    }
  },

  trackCurrentFieldType: function (component) {
    var selectedMergeField = component.get('v.selectedMergeField');

    if (!$A.util.isUndefinedOrNull(selectedMergeField)) {
      if (selectedMergeField.type === 'REFERENCE') {
        component.set('v.currentFieldLookup', true);
        component.set('v.currentFieldChild', false);
      } else if (selectedMergeField.type === 'CHILD_RELATIONSHIP') {
        component.set('v.currentFieldChild', true);
        component.set('v.currentFieldLookup', false);
      } else {
        component.set('v.currentFieldChild', false);
        component.set('v.currentFieldLookup', false);
      }
    }

  },

  fireChangeFieldSelection: function (component, event, helper) {
    var evt = component.getEvent('changeFieldSelection');
    var selectedFieldValue = event.getSource().get('v.value');
    var type = helper.getParentTypeOfField(component);
    var propertySearchNames = ['name', 'relationship'];
    var selectedFieldFromOptions;

    for (var index in propertySearchNames) {
      var propertySearchName = propertySearchNames[index];
      selectedFieldFromOptions = helper.getFieldByProperty(component, propertySearchName, selectedFieldValue);
      if (helper.isNotUndefinedAndEmpty(selectedFieldFromOptions)) {
        break;
      }
    }

    // explicit update to render non-lookup/non-child field selections
    component.set('v.selectedMergeField', selectedFieldFromOptions);

    evt.setParams({
      data: {
        field: selectedFieldFromOptions,
        depth: component.get('v.currentDepth'),
        fieldIndex: component.get('v.fieldIndex'),
        path: component.get('v.currentMergeTreePath'),
        key: component.get('v.currentMergeTreeKey'),
        type: type
      }
    });
    evt.fire();
  },

  getFieldByProperty: function (component, propertyName, selectedFieldValue) {
    return component.get('v.currentObjectFields').find(function (field) {
      return field[propertyName] === selectedFieldValue;
    });
  },

  getParentTypeOfField: function (component) {
    if (component.get('v.isParentObjectPicker')) {
      return 'ROOT';
    } else if (component.get('v.isLookupRelationShipPicker') || component.get('v.isChildLookup')) {
      return 'REFERENCE';
    } else {
      return 'CHILD_RELATIONSHIP';
    }
  },

  setToken: function (component) {
    var selectedMergeField = component.get('v.selectedMergeField');
    var token = '';
    var parentObjectName = component.get('v.parentObjectName');
    if (!$A.util.isUndefinedOrNull(selectedMergeField)
      && !$A.util.isEmpty(selectedMergeField.name)) {
      //top level picker mergefield
      if (component.get('v.isParentObjectPicker') === true) {
        //selected MergeField is top level field
        if (selectedMergeField.type !== 'CHILD_RELATIONSHIP'
          && selectedMergeField.type !== 'REFERENCE') {
          //handling conditional mapping
          if (selectedMergeField.isConditional) {
            token = '<# <Conditional Select="/' + parentObjectName + '/' + selectedMergeField.name + '" ' + selectedMergeField.matchType + '="' + selectedMergeField.conditionalValue +
              '" /> #> YOUR CONTENT HERE <# <EndConditional/> #>';
          }
          // if top level field is RICHTEXT type
          else if (selectedMergeField.type === 'RICHTEXT') {
            token = '<# <RichText Select="/' + parentObjectName + '/' + selectedMergeField.name + '"/> #>';
          }
          //if top level field is not RICHTEXT type and not Conditional
          else {
            token = '<# <Content Select="/' + parentObjectName + '/' + selectedMergeField.name + '"/> #>';
          }
        }
        //selected MergeField is top level field child field
        else if (selectedMergeField.type === 'CHILD_RELATIONSHIP') {
          token = '<# <TableRow Select="/' + parentObjectName + '//' + selectedMergeField.relationship + '" /> #>';
        } else if (selectedMergeField.type === 'REFERENCE') {
          token = '';
        }
      }
      // lookup mergeField picker
      else if (component.get('v.isLookupRelationShipPicker') === true) {
        //if selected field is not a lookup field
        if (selectedMergeField.type !== 'REFERENCE') {
          var lookupPath = component.get('v.currentMergeTreeKey');
          var resolvedLookupName = stringUtils.format('{0}{1}{2}', lookupPath, '.', selectedMergeField.name);
          if (selectedMergeField.isConditional) {
            token = '<# <Conditional Select="/' + parentObjectName + '/' + resolvedLookupName + '" ' + selectedMergeField.matchType + '="' + selectedMergeField.conditionalValue +
              '" /> #> YOUR CONTENT HERE <# <EndConditional/> #>';
          }
          //selected mergefield is RICHTEXT
          else if (selectedMergeField.type === 'RICHTEXT') {
            token = '<# <RichText Select="/' + parentObjectName + '/' + resolvedLookupName + '"/> #>';
          }
          //selected mergefield is not RICHTEXT
          else {
            token = '<# <Content Select="/' + parentObjectName + '/' + resolvedLookupName + '"/> #>';
          }
        }
        //selected merge field is another lookup field
        else {
          token = '';
        }
      }
      //child field picker
      else if (component.get('v.isChildRelationShipPicker') === true) {
        //if selected mergefield is not a child or lookup
        if (selectedMergeField.type !== 'CHILD_RELATIONSHIP' && selectedMergeField.type !== 'REFERENCE') {
          var selectedMergeFieldName;
          if (component.get('v.isChildLookup')) {
            var multiChildLookupPathName = component.get('v.currentMergeTreePath').join('.');
            selectedMergeFieldName = stringUtils.format('{0}{1}{2}', multiChildLookupPathName, '.', selectedMergeField.name);
          } else {
            selectedMergeFieldName = selectedMergeField.name;
          }
          if (selectedMergeField.isConditional) {
            token = '<# <Conditional Select="./' + selectedMergeFieldName + '" ' + selectedMergeField.matchType + '="' + selectedMergeField.conditionalValue +
              '" /> #> YOUR CONTENT HERE <# <EndConditional/> #>';
          } else if (selectedMergeField.type === 'RICHTEXT') {
            token = '<# <RichText Select="./' + selectedMergeFieldName + '"/> #>';
          } else {
            token = '<# <Content Select="./' + selectedMergeFieldName + '"/> #>';
          }
        } else if (selectedMergeField.type === 'REFERENCE') {
          token = '';
        } else if (selectedMergeField.type === 'CHILD_RELATIONSHIP'
          && component.get('v.currentDepth') === 2) {
          token = '<# <TableRow Select=".//' + selectedMergeField.relationship + '" /> #>';
        }
      }
    }
    component.set('v.token', token);
  },

  addLookupField: function (component) {
    var evt = component.getEvent('addLookupField');
    evt.setParams({
      data: {
        type: 'REFERENCE',
        depth: component.get('v.currentDepth') + 1,
        key: component.get('v.nextMergeTreeKey')
      }
    });
    evt.fire();
  },

  addChildField: function (component) {
    var evt = component.getEvent('addChildField');
    evt.setParams({
      data: {
        type: 'CHILD_RELATIONSHIP',
        depth: component.get('v.currentDepth') + 1,
        key: component.get('v.nextMergeTreeKey')
      }
    });
    evt.fire();
  },

  copyToken: function (component, event, helper) {
    var tokenInput = component.find('token-input');
    tokenInput.getElement().select();
    document.execCommand('copy');
    helper.showToast(
      component,
      'success',
      $A.get('$Label.c.SuccessCopyClipboard')
    );
  },

  removeField: function (component, helper) {
    var evt = component.getEvent('removeField');
    var type = helper.getParentTypeOfField(component);

    evt.setParams({
      data: {
        field: component.get('v.selectedMergeField'),
        depth: component.get('v.currentDepth'),
        fieldIndex: component.get('v.fieldIndex'),
        path: component.get('v.currentMergeTreePath'),
        key: component.get('v.currentMergeTreeKey'),
        type: type
      }
    });
    evt.fire();
  },

  showMergeOptionsModal: function (component, helper) {
    var type = helper.getParentTypeOfField(component);
    var evt = component.getEvent('showMergeOptionsModal');
    evt.setParams({
      data: {
        field: component.get('v.selectedMergeField'),
        depth: component.get('v.currentDepth'),
        fieldIndex: component.get('v.fieldIndex'),
        path: component.get('v.currentMergeTreePath'),
        key: component.get('v.currentMergeTreeKey'),
        type: type
      }
    });
    evt.fire();
  }

});