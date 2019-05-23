({
  setTokenValue: function(component) {
    var fieldMapping = component.get('v.fieldMapping');
    var objLabel = component.get('v.objLabel').replace(/\s/g, '_');
    var isChild = component.get('v.isChild');
    var token = '';
    if (
      $A.util.isEmpty(fieldMapping) ||
      $A.util.isEmpty(fieldMapping.apiName)
    ) {
      return;
    }

    if (fieldMapping.isChildRelation) {
      token =
        '<# <TableRow Select="/' +
        objLabel +
        '//' +
        fieldMapping.apiName +
        '" /> #>';
    } else if (fieldMapping.isConditional) {
      if (isChild) {
        token =
          '<# <Conditional Select="./' +
          fieldMapping.apiName +
          '" ' +
          fieldMapping.matchType +
          '="' +
          fieldMapping.conditionalValue +
          '" /> #> YOUR CONTENT HERE <# <EndConditional/> #>';
      } else {
        token =
          '<# <Conditional Select="/' +
          objLabel +
          '/' +
          fieldMapping.apiName +
          '" ' +
          fieldMapping.matchType +
          '="' +
          fieldMapping.conditionalValue +
          '" /> #> YOUR CONTENT HERE <# <EndConditional/> #>';
      }
    } else if (isChild) {
      token = '<# <Content Select="./' + fieldMapping.apiName + '"/> #>';
    } else if (fieldMapping.dataType === 'RICHTEXT') {
      token =
        '<# <RichText Select="/' +
        objLabel +
        '/' +
        fieldMapping.apiName +
        '"/> #>';
    } else {
      token =
        '<# <Content Select="/' +
        objLabel +
        '/' +
        fieldMapping.apiName +
        '"/> #>';
    }

    component.set('v.token', token);
  },

  removeChildMapping: function(component, index) {
    var helper = this;
    var parentFieldMapping = component.get('v.parentFieldMapping');

    parentFieldMapping.childFieldMappings.splice(index, 1);

    if (parentFieldMapping.childFieldMappings.length === 0) {
      helper.removeMapping(component, component.get('v.parentMappingIndex'));
    } else {
      component.set('v.parentFieldMapping', parentFieldMapping);
    }
  },

  getChildFields: function(component) {
    var fieldMapping = component.get('v.fieldMapping');
    var action = component.get('c.getMergeFields');
    action.setParams({
      sObjectType: fieldMapping.apiName,
      isChild: true
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var objectFields = [];
        var allFields = [];
        var allFieldsByApiName = {};

        // Modify logic here to allow multiple level nesting in the future
        results.forEach(function(object) {
          if (!object.hasRelationship) {
            objectFields.push(object);
          }
        });

        allFields[0] = {
          fields: objectFields,
          label: fieldMapping ? fieldMapping.label : null
        };

        allFields.forEach(function(object) {
          object.fields.forEach(function(field) {
            allFieldsByApiName[field.name] = field;
          });
        });

        component.set('v.allChildObjFields', allFields);
        component.set('v.allChildFieldsByApiName', allFieldsByApiName);
      }
      if (state === 'ERROR') {
        // FIXME: This is a lot of work to get an error message that's never used. Can use uiHelper.getErrorMessage, but need to use it somehow.
        // var errorMessage = $A.get('$Label.c.ErrorMessage');
        // var errors = response.getError();
        // if (errors) {
        //   if (errors[0] && errors[0].message) {
        //     errorMessage += errors[0].message;
        //   }
        // } else {
        //   errorMessage += $A.get('$Label.c.UnknownError');
        // }
      }
      component.getEvent('childLoaded').fire();
    });

    action.setBackground();
    component.getEvent('loadingChild').fire();
    $A.enqueueAction(action);
  },

  removeMapping: function(component, index) {
    var evt = component.getEvent('removeMapping');

    evt.setParams({
      data: index
    });

    evt.fire();
  },

  setConditionalRadio: function(component) {
    var mergeFieldDisplayOptions = [
      {
        label: $A.get('$Label.c.MergeFieldDisplayCurrent'),
        value: 'false'
      },
      {
        label: $A.get('$Label.c.MergeFieldDisplayConditional'),
        value: 'true'
      }
    ];

    component.set('v.mergeFieldDisplayOptions', mergeFieldDisplayOptions);
  },

  getChildFieldStub: function() {
    return {
      apiName: '',
      dataType: '',
      isConditional: false,
      dateFormat: 'default',
      currencyFormat: 'symbol'
    };
  },

  showToast: function(component, variant, msg) {
    var evt = component.getEvent('showToast');

    evt.setParams({
      data: {
        msg: msg,
        variant: variant
      }
    });

    evt.fire();
  }
});
