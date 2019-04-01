({
  init: function (component) {
    var action = component.get('c.getMergeFields');
    var objMapping = component.get('v.objMapping');

    action.setParams({
      sObjectType: objMapping.apiName
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var returnValue = response.getReturnValue();

        var childRelations = [];
        var objectFields = [];
        var allFields = [];
        var allFieldsByApiName = {};

        returnValue.forEach(function (object) {
          if (object.type === "CHILD_RELATIONSHIP") {
            childRelations.push(object);
          } else {
            objectFields.push(object);
          }
        });

        childRelations.sort(function (a, b) {
          if (a.label > b.label) {
            return 1;
          } else {
            return -1;
          }
        });

        allFields[0] = {
          'fields': objectFields,
          'label': objMapping ? objMapping.label : null
        };

        allFields.forEach(function (obj) {
          obj.fields.forEach(function (field) {
            allFieldsByApiName[field.name] = field;
          });
        });

        childRelations.forEach(function (obj) {
          allFieldsByApiName[obj.relatesTo] = obj;
        });
        component.set('v.childRelations', childRelations);
        component.set('v.allFields', allFields);
        component.set('v.allFieldsByApiName', allFieldsByApiName);

        if (objMapping.fieldMappings.length == 0) {
          component.set('v.isLoading', false);
        }
      }

      if (state === "ERROR") {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        component.set('v.saving', false);
      }

    });
    action.setBackground();
    $A.enqueueAction(action);
  },

  enableLoading: function (component) {
    component.set('v.isLoading', true);
  },

  childrenLoaded: function (component) {
    var objMapping = component.get('v.objMapping');
    var loadedChildren = component.get('v.loadedChildren');
    loadedChildren++;

    if (loadedChildren >= objMapping.fieldMappings.length) {
      component.set('v.isLoading', false);
    } else {
      component.set('v.loadedChildren', loadedChildren);
    }
  },

  addField: function (component) {
    var objMapping = component.get('v.objMapping');

    if ($A.util.isEmpty(objMapping.fieldMappings)) {
      objMapping.fieldMappings = [];
    }

    objMapping.fieldMappings.push({
      'apiName': '',
      'dataType': '',
      'childFieldMappings': [],
      'isConditional': false,
      'isChildRelation': false,
      'dateFormat': 'default',
      'currencyFormat': 'symbol'
    });

    component.set('v.objMapping', objMapping);
  },

  removeField: function (component, event) {
    var objMapping = component.get('v.objMapping');
    var index = parseInt(event.getParam('data'), 10);

    objMapping.fieldMappings.splice(index, 1);

    component.set('v.objMapping', objMapping);
  }
});