({
  init: function(component, event, helper) {
    var fieldMapping = component.get('v.fieldMapping');
    var isChild = component.get('v.isChild');
    component.set('v.previousFieldMappingName', fieldMapping.apiName);

    helper.setConditionalRadio(component);
    helper.setTokenValue(component);

    if (fieldMapping.isChildRelation) {
      helper.getChildFields(component);
    } else if (!isChild) {
      component.getEvent('childLoaded').fire();
    }
  },

  selectedButtonMenuItem: function(component, event, helper) {
    var action = event.getParam('value');
    var isChild = component.get('v.isChild');

    //handle children
    switch (action) {
      case 'options':
        var params = {
          isChild: isChild,
          fieldIndex: component.get('v.mappingIndex'),
          parentIndex: component.get('v.parentMappingIndex'),
          objIndex: component.get('v.objIndex'),
          objLabel: component.get('v.objLabel')
        };

        var evt = component.getEvent('showOptionsModal');

        evt.setParams({
          data: params
        });

        evt.fire();
        break;
      case 'remove':
        var index = component.get('v.mappingIndex');

        if (isChild) {
          helper.removeChildMapping(component, index);
        } else {
          helper.removeMapping(component, index);
        }

        break;
    }
  },

  processFieldSelection: function(component, event, helper) {
    var allFieldMappings = component.get('v.allFieldMappings');
    var allFieldsByApiName = component.get('v.allFieldsByApiName');
    var fieldMapping = component.get('v.fieldMapping');
    var fieldData = allFieldsByApiName[fieldMapping.apiName];
    var dupeFieldMappings = allFieldMappings.filter(function(objFieldMapping) {
      return fieldMapping.apiName === objFieldMapping.apiName;
    });

    //ignore yourself as a dupe
    if (dupeFieldMappings.length > 1) {
      //use field data instead of fieldMapping as it doesn't have the label yet.
      helper.showToast(
        component,
        'warning',
        stringUtils.format($A.get('$Label.c.FieldPickerFieldExists_1'), fieldData.label)
      );
      fieldMapping.apiName = component.get('v.previousFieldMappingName');
      component.set('v.fieldMapping', fieldMapping);
      return;
    }

    component.set('v.previousFieldMappingName', fieldMapping.apiName);

    var newFieldMapping;
    if (fieldData.hasRelationship) {
      newFieldMapping = {
        apiName: fieldData.relatesTo,
        isChildRelation: true,
        label: fieldData.name,
        getDecimalPlaces: fieldData.getScale
      };
    } else {
      newFieldMapping = {
        apiName: fieldData.name,
        dataType: fieldData.type,
        isChildRelation: false,
        label: fieldData.label,        
        getDecimalPlaces: fieldData.getScale
      };
    }

    Object.assign(fieldMapping, newFieldMapping);

    if (fieldMapping.isChildRelation) {
      fieldMapping.childFieldMappings = [helper.getChildFieldStub()];
      helper.getChildFields(component);
    }

    helper.setTokenValue(component);
    component.set('v.fieldMapping', fieldMapping);
  },

  addChildField: function(component, event, helper) {
    var fieldMapping = component.get('v.fieldMapping');
    fieldMapping.childFieldMappings.push(helper.getChildFieldStub());
    component.set('v.fieldMapping', fieldMapping);
  },

  copyToken: function(component, event, helper) {
    var tokenInput = component.find('token-input');
    tokenInput.getElement().select();
    document.execCommand('copy');
    helper.showToast(
      component,
      'success',
      $A.get('$Label.c.SuccessCopyClipboard')
    );
  },

  setToken: function(component, event, helper) {
    helper.setTokenValue(component);
  }
});
