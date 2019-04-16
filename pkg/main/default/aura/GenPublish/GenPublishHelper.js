({
  getLayouts: function (component, event, helper) {
    var config = component.get('v.config');
    var action = component.get('c.getLayouts');

    action.setParams({
      sObjectType: config.objectMappings[0].apiName
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var layouts = response.getReturnValue();
        if (!$A.util.isEmpty(layouts)) {
          component.set('v.layouts', layouts);
        }
      } else if (state === "ERROR") {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        }
        helper.showToast(component, errorMessage, 'error');
      }
    });

    $A.enqueueAction(action);
  },

  getGenActionName: function (component, event, helper) {
    var action = component.get('c.getGenActionName');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var genActionName = response.getReturnValue();
        if (!$A.util.isEmpty(genActionName)) {
          component.set('v.genActionName', genActionName);
        }
      } else if (state === "ERROR") {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        }
        helper.showToast(component, errorMessage, 'error');
      }
    });

    $A.enqueueAction(action);
  },

  copyLayout: function (layout) {
    var result = null;
    if (!$A.util.isUndefinedOrNull(layout)) {
      result = JSON.parse(JSON.stringify(layout));
      delete result.original;
    }
    return result;
  },

  getLayoutsToUpdate: function (layouts, sendActionName) {
    var ls = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        if (layouts[i].checked) {
          var layout = this.copyLayout(layouts[i]);
          layout.actions = [];
          layout.actions.push({
            type: 'GEN', name: sendActionName
          });
          delete layout.checked;
          delete layout.original;
          ls.push(layout);
        }
      }
    }
    return ls;
  },

  publishGenButtons: function (component, event, helper) {
    var config = component.get('v.config');
    var action = component.get('c.updateLayouts');
    var buttonApiName = String(component.get('v.genActionName') + component.get('v.config').name);
    var buttonLabel = $A.get('$Label.c.Generate') + ' ' + component.get('v.config').name;
    var selectedLayouts = helper.getLayoutsToUpdate(component.get('v.layouts'), buttonApiName);

    action.setParams({
      sObjectType: config.objectMappings[0].apiName,
      layoutsJson: JSON.stringify(selectedLayouts),
      genButtonApiName: buttonApiName,
      genButtonLabel: buttonLabel,
      genTemplateId: config.id
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.getEvent('publishedButtons').fire();
        helper.showToast(component, $A.get('$Label.c.SuccessfullyPublished'), 'success');
      } else if (state === "ERROR") {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        }
        helper.showToast(component, errorMessage, 'error');
      }
      component.set('v.creatingButtons', false);
    });

    component.set('v.creatingButtons', true);
    $A.enqueueAction(action);
  },

  showToast: function (component, msg, variant) {
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