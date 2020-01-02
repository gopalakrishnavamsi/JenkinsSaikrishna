({
  init: function (component) {
    var action = component.get('c.getMergeFields');
    var objMapping = component.get('v.objMapping');

    action.setParams({
      sObjectType: objMapping.apiName,
      isChild: false
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var returnValue = response.getReturnValue();

        var childRelations = [];
        var objectFields = [];
        var allFields = [];
        // adding Current Date to list
        allFields.push({
          fields: [{ label:$A.get('$Label.c.CurrentDate'), name:'CurrentDate' }],
          label: ''
         });
        allFields.push({
          fields: [],
          label: objMapping.label
        });
        var allFieldsByApiName = {};

        returnValue.forEach(function (object) {
          if (object.type === 'CHILD_RELATIONSHIP') {
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

        objectFields.forEach(function (object) {
          var relationShipName;
          if (object.name.substr(0, object.name.indexOf('.')) !== '') {
            relationShipName = object.name.substr(0, object.name.indexOf('.'));
          } else {
            relationShipName = objMapping.label;
          }
          var labelExists = false;
          allFields.forEach(function (field) {
            if (field.label === relationShipName) {
              field.fields.push(object);
              labelExists = true;
            }
          });
          if (!labelExists) {
            var fields = [];
            fields.push(object);
            var allFieldsInstance = {fields: fields, label: relationShipName};
            allFields.push(allFieldsInstance);
          }
        });

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

        if (objMapping.fieldMappings.length === 0) {
          component.set('v.isLoading', false);
        }
      } else {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          type: 'error',
          message: stringUtils.getErrorMessage(response)
        });
        toastEvent.fire();
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
      apiName: '',
      dataType: '',
      childFieldMappings: [],
      isConditional: false,
      isChildRelation: false,
      dateFormat: 'default',
      currencyFormat: 'symbol',
      percentFormat: false,
      getDecimalPlaces: 0
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
