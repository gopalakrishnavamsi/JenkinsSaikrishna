({
  onInit: function (component, event, helper) {
    helper.setTopLevelMappings(component, event, helper);
  },

  setTopLevelMappings: function (component, event, helper) {
    var topLevelObject = component.get('v.objMappings').name;
    var depth = 1;
    helper.fetchMergeFields(component, event, helper, topLevelObject, depth)
      .then($A.getCallback(function (response) {
        var topLevelMappings = [{
          objectName: topLevelObject,
          depth: 1,
          fields: response,
          type: 'ROOT'
        }];
        var currentDateField = helper.getCurrentDateFieldStub(topLevelObject);
        topLevelMappings[0].fields.unshift(currentDateField);
        component.set('v.topLevelMergeFields', topLevelMappings);
        component.set('v.isLoading', false);
      }))
      .catch(function (error) {
        helper.showToast(component, error, 'error');
        component.set('v.isLoading', false);
      });
  },

  getCurrentDateFieldStub: function(topLevelObject) {
    return {
      matchType: null,
      label: $A.get('$Label.c.CurrentDate'),
      isConditional: false,
      isChildRelation: false,
      type: 'DATE',
      conditionalValue: null,
      name: 'CurrentDate',
      relatesTo: topLevelObject,
      relationship: topLevelObject,
      parentIdField: '',
      format: null,
      scale: 0,
      filterBy: null,
      orderBy: null,
      maximumRecords: null
    };
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

  addRootField: function (component, event, helper) {
    var mergeFieldTree = component.get('v.mergeFieldTree');
    mergeFieldTree.forEach(function (instance) {
      if (instance.type === 'ROOT') {
        instance.fields.push(helper.fieldMappingStub());
      }
    });
    component.set('v.mergeFieldTree', mergeFieldTree);
  },

  showToast: function (component, message, mode) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      type: mode,
      message: message
    });
    toastEvent.fire();
  },

  fieldMappingStub: function () {
    return {
      matchType: null,
      label: null,
      isConditional: false,
      isChildRelation: false,
      type: null,
      conditionalValue: null,
      name: '',
      relatesTo: '',
      relationship: '',
      parentIdField: '',
      format: null,
      scale: 0,
      filterBy: null,
      orderBy: null,
      maximumRecords: null
    };
  },

  transFormFieldMapping: function (fieldMapping, helper) {
    return {
      matchType: null,
      label: fieldMapping.label,
      isConditional: false,
      isChildRelation: fieldMapping.type === 'CHILD_RELATIONSHIP' ? true : false,
      type: fieldMapping.type,
      conditionalValue: null,
      name: fieldMapping.type === 'CHILD_RELATIONSHIP' ? fieldMapping.relatesTo : fieldMapping.type === 'REFERENCE' ? fieldMapping.relationship : fieldMapping.name,
      relatesTo: (fieldMapping.type === 'CHILD_RELATIONSHIP' || fieldMapping.type === 'REFERENCE') ? fieldMapping.relatesTo : '',
      relationship: fieldMapping.relationship,
      parentIdField: fieldMapping.name,
      format: helper.resolveFormat(fieldMapping),
      scale: fieldMapping.scale,
      filterBy: fieldMapping.filterBy ? fieldMapping.filterBy : null,
      orderBy: fieldMapping.orderBy ? fieldMapping.orderBy : null,
      maximumRecords: fieldMapping.maximumRecords ? fieldMapping.maximumRecords : null
    };
  },

  resolveFormat: function(fieldMapping) {
    var format = null;
    if (fieldMapping.type === 'DATE' || fieldMapping.type === 'TIME') {
      format = 'default';
    } else if (fieldMapping.type === 'CURRENCY') {
      format = 'symbol';
    } else if (fieldMapping.type === 'DATETIME') {
      format = 'default|default';
    } else if (fieldMapping.type === 'PERCENT') {
      format = true;
    }
    return format;
  },

  changeMergeFieldSelection: function (component, event, helper) {
    var fieldChangeData = event.getParam('data');
    helper.updateMergeTreeParentFieldSelection(component, event, helper, fieldChangeData);
  },

  updateMergeTreeParentFieldSelection: function (component, event, helper, fieldChangeData) {
    var parentNodeOfField = component.get('v.mergeFieldTree').find(function (node) {
      return helper.isParentOfField(node, fieldChangeData);
    });
    //get previous field mapping from mergeTree
    var previousMergeFieldMapping = parentNodeOfField.fields[fieldChangeData.fieldIndex];
    //replace the field in mergeTree with new field
    parentNodeOfField.fields[fieldChangeData.fieldIndex] = helper.transFormFieldMapping(fieldChangeData.field, helper);
    //remove stale leaves from MergeTree
    helper.removeStaleNodesFromMergeTree(component, fieldChangeData, previousMergeFieldMapping);
    //add new leaf to mergeTree
    helper.addNewLeaf(component, parentNodeOfField.fields[fieldChangeData.fieldIndex], helper, fieldChangeData);
  },

  removeStaleNodesFromMergeTree: function (component, fieldChangeData, previousMergeFieldMapping) {
    var wasInternalNode = previousMergeFieldMapping.type === 'REFERENCE' || previousMergeFieldMapping.type === 'CHILD_RELATIONSHIP';
    var fullPathToMergeField = fieldChangeData.key.length > 0 ? fieldChangeData.key.concat('.', previousMergeFieldMapping.relationship) : previousMergeFieldMapping.relationship;
    if (wasInternalNode) {
      var updatedMergeFieldTree = component.get('v.mergeFieldTree').filter(function (node) {
        if (node.type === previousMergeFieldMapping.type && node.key.startsWith(fullPathToMergeField)) {
          return false;
        }
        return true;
      });
      component.set('v.mergeFieldTree', updatedMergeFieldTree);
    }
  },

  leafExists: function (component, depth, key, type) {
    return component.get('v.mergeFieldTree').filter(function (t) {
      return t.depth === depth && key === t.key && t.type === type;
    }).length > 1;
  },

  addNewLeaf: function (component, updatedMergeFieldMapping, helper, fieldChangeData) {
    var newLeaf;
    if (updatedMergeFieldMapping.type === 'CHILD_RELATIONSHIP' ||
      updatedMergeFieldMapping.type === 'REFERENCE') {
      var newLeafPath = $A.util.isUndefinedOrNull(fieldChangeData.path) ? [] : fieldChangeData.path;
      var newLeafKey = $A.util.isUndefinedOrNull(fieldChangeData.key) ? '' : fieldChangeData.key;
      if (updatedMergeFieldMapping.type === 'REFERENCE') {
        newLeafPath.push(updatedMergeFieldMapping.relationship);
      }
      newLeafKey = newLeafKey.length > 0 ? newLeafKey.concat('.', updatedMergeFieldMapping.relationship) : updatedMergeFieldMapping.relationship;
      if (!helper.leafExists(component, fieldChangeData.depth + 1 , newLeafKey, updatedMergeFieldMapping.type, helper)) {
        newLeaf = {
          type: updatedMergeFieldMapping.type,
          depth: fieldChangeData.depth + 1,
          path: newLeafPath,
          key: newLeafKey,
          fields: []
        };
        newLeaf.fields.push(helper.fieldMappingStub());
      }
    }
    if (!$A.util.isUndefinedOrNull(newLeaf)) {
      var currentMergeFieldTree = component.get('v.mergeFieldTree');
      currentMergeFieldTree.push(newLeaf);
      component.set('v.mergeFieldTree', currentMergeFieldTree);
    }
  },

  addLookupField: function (component, event, helper) {
    var mergeFieldTree = component.get('v.mergeFieldTree');
    var eventData = event.getParam('data');
    mergeFieldTree.forEach(function (instance) {
      if (instance.type === 'REFERENCE' && instance.depth === eventData.depth
        && instance.key === eventData.key) {
        instance.fields.push(helper.fieldMappingStub());
      }
    });
    component.set('v.mergeFieldTree', mergeFieldTree);
  },

  addChildField: function (component, event, helper) {
    var mergeFieldTree = component.get('v.mergeFieldTree');
    var eventData = event.getParam('data');
    mergeFieldTree.forEach(function (instance) {
      if (instance.type === 'CHILD_RELATIONSHIP' && instance.depth === eventData.depth
        && instance.key === eventData.key) {
        instance.fields.push(helper.fieldMappingStub());
      }
    });
    component.set('v.mergeFieldTree', mergeFieldTree);
  },

  checkPath: function (eventPath, mergeTreePath) {
    if (eventPath.length !== mergeTreePath.length) {
      return false;
    }
    for (var i = 0; i < eventPath.length; i++) {
      if (eventPath[i] !== mergeTreePath[i]) {
        return false;
      }
    }
    return true;
  },

  removeField: function (component, event, helper) {
    var fieldChangeData = event.getParam('data');
    var parentNodeOfField = component.get('v.mergeFieldTree').find(function (node) {
      return helper.isParentOfField(node, fieldChangeData);
    });
    var previousMergeFieldMapping = parentNodeOfField.fields[fieldChangeData.fieldIndex];
    helper.removeStaleNodesFromMergeTree(component, fieldChangeData, previousMergeFieldMapping);
    helper.removeFieldFromParent(component, fieldChangeData);
  },

  removeFieldFromParent: function (component, fieldChangeData) {
    var self = this;
    var fieldIndex = fieldChangeData.fieldIndex;
    var updatedMergeFieldTree = component.get('v.mergeFieldTree');
    var mergeTreeIndex;
    var parent = updatedMergeFieldTree.find(function (node, index) {
      if (self.isParentOfField(node, fieldChangeData)) {
        mergeTreeIndex = index;
        return true;
      }
      return false;
    });
    if (!$A.util.isUndefinedOrNull(mergeTreeIndex)) {
      parent.fields.splice(fieldIndex, 1);
      updatedMergeFieldTree[mergeTreeIndex] = parent;
      component.set('v.mergeFieldTree', updatedMergeFieldTree);
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
  }
});