({
  PUBLISH_BUTTON: 'Publish Gen Button',

  _getUserEvents: function (component) {
    return component.find('ds-user-events');
  },

  init: function (component, event, helper) {
    helper.getGenActionName(component)
      .then($A.getCallback(function (genActionName) {
        component.set('v.genActionName', genActionName);
        component.set('v.genActionAPIName', genActionName + component.get('v.config').id);
        helper.getLayouts(component, event, helper);
      }))
      .catch(function (error) {
        helper.showToast(component, error, 'error');
        helper._getUserEvents(component).error(helper.PUBLISH_BUTTON, {}, 'Initialization error');
      });
  },

  startPublish: function (component, userEvents) {
    userEvents.time(this.PUBLISH_BUTTON);
    var config = component.get('v.config');
    userEvents.addProperties({
      'Product': 'Gen',
      'Template Type': 'Word',
      'Source Object': stringUtils.sanitizeObjectName(config ? config.sourceObject : null)
    });
  },

  getGenActionName: function (component) {
    var action = component.get('c.getGenActionName');
    return new Promise($A.getCallback(function (resolve, reject) {
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(action);
    }));
  },

  getLayouts: function (component, event, helper) {
    var config = component.get('v.config');
    var getLayoutsAction = component.get('c.getLayouts');
    component.set('v.fetchingLayout', true);
    getLayoutsAction.setParams({
      sObjectType: config.objectMappings.name
    });

    getLayoutsAction.setCallback(this, $A.getCallback(function (response) {
      component.set('v.fetchingLayout', false);
      if (response.getState() === 'SUCCESS') {
        var layouts = response.getReturnValue();
        if (!$A.util.isEmpty(layouts)) {
          component.set('v.layouts', helper.processLayouts(layouts, component));
          component.set('v.isDirty', false);
        }
      } else {
        var errMsg = stringUtils.getErrorMessage(response);
        helper.showToast(component, errMsg, 'error');
        helper._getUserEvents(component).error(helper.PUBLISH_BUTTON, {}, 'Get layouts error');
      }
    }));
    $A.enqueueAction(getLayoutsAction);
  },

  hasGenAction: function (layout, component, update) {
    if (!$A.util.isUndefinedOrNull(layout) && !$A.util.isEmpty(layout.actions)) {
      for (var i = 0; i < layout.actions.length; i++) {
        var action = layout.actions[i];
        if (action.type === 'GEN' && action.name === component.get('v.genActionAPIName')) {
          if (update) {
            component.set('v.genButtonLabel', action.label);
          }
          return true;
        }
      }
    }
    return false;
  },

  copyLayout: function (layout) {
    var result = null;
    if (!$A.util.isUndefinedOrNull(layout)) {
      result = JSON.parse(JSON.stringify(layout));
      delete result.original;
    }
    return result;
  },

  processLayouts: function (layouts, component) {
    var result = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        var layout = layouts[i];
        delete layout.original;
        layout.hasGenAction = layout.hasOwnProperty('hasGenAction') ? layout.hasGenAction : this.hasGenAction(layout, component, true);
        layout.original = this.copyLayout(layout);
        result.push(layout);
      }
    }
    return result;
  },

  updateGenActionLabel: function (layouts, component) {
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        var layout = layouts[i];
        if (this.hasGenAction(layout, component, false)) {
          for (var j = 0; j < layout.actions.length; j++) {
            var action = layout.actions[j];
            if (action.type === 'GEN' && action.name === component.get('v.genActionAPIName')) {
              action.label = component.get('v.genButtonLabel');
              return;
            }
          }
        }
      }
    }
  },

  isDirty: function (layouts, component) {
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        if (this.isLayoutDirty(layouts[i], component)) {
          return true;
        }
      }
    }
    return false;
  },

  isLayoutDirty: function (layout, component) {
    return (!$A.util.isUndefinedOrNull(layout) && !$A.util.isUndefinedOrNull(layout.original) && (layout.hasGenAction !== layout.original.hasGenAction || this.isLabelUpdated(layout, component)));
  },

  isLabelUpdated: function (layout, component) {
    if (!$A.util.isUndefinedOrNull(layout.hasGenAction) && !$A.util.isUndefinedOrNull(layout.original.hasGenAction)) {
      var originalLabel, currentLabel;
      //fetch the original label for the action
      for (var i = 0; i < layout.original.actions.length; i++) {
        var originalAction = layout.original.actions[i];
        if (originalAction.type === 'GEN' && originalAction.name === component.get('v.genActionAPIName')) {
          originalLabel = originalAction.label;
          break;
        }
      }

      //fetch the updated label for the action
      for (var j = 0; j < layout.actions.length; j++) {
        var action = layout.actions[j];
        if (action.type === 'GEN' && action.name === component.get('v.genActionAPIName')) {
          currentLabel = action.label;
          break;
        }
      }

      return !!(originalLabel !== currentLabel && layout.hasGenAction);
    } else {
      return false;
    }
  },

  getLayoutsToUpdate: function (layouts, genActionName, component) {
    var ls = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        if (!this.isLayoutDirty(layouts[i], component)) continue;
        var layout = this.copyLayout(layouts[i]);
        layout.actions = [];
        if (layout.hasGenAction) {
          layout.actions.push({
            type: 'GEN', name: genActionName, label: component.get('v.genButtonLabel')
          });
        }

        delete layout.hasGenAction;
        delete layout.original;
        ls.push(layout);
      }
    }
    return ls;
  },

  publishGenButtons: function (component, event, helper) {
    var buttonIsValid = helper.getButtonLabelValidity(component);
    if (!buttonIsValid) {
      return;
    }
    component.set('v.creatingButtons', true);
    var config = component.get('v.config');
    var action = component.get('c.updateLayouts');
    var buttonApiName = String(component.get('v.genActionName') + component.get('v.config').id);
    var buttonLabel = component.get('v.genButtonLabel');
    var selectedLayouts = helper.getLayoutsToUpdate(component.get('v.layouts'), buttonApiName, component);
    var parameters = {
      genButtonApiName: buttonApiName,
      genButtonLabel: buttonLabel,
      genTemplateId: config.id
    };
    var evtProps = {
      'Layouts': selectedLayouts ? selectedLayouts.length : 0
    };

    action.setParams({
      sObjectType: config.objectMappings.name,
      layoutsJson: JSON.stringify(selectedLayouts),
      parameters: JSON.stringify(parameters)
    });

    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.getEvent('publishedButtons').fire();
        helper.getLayouts(component, event, helper);
        helper.showToast(component, $A.get('$Label.c.SuccessfullyModifiedLayouts'), 'success');
        helper._getUserEvents(component).success(helper.PUBLISH_BUTTON, evtProps);
      } else {
        var errMsg = stringUtils.getErrorMessage(response);
        helper.showToast(component, errMsg, 'error');
        helper._getUserEvents(component).error(helper.PUBLISH_BUTTON, evtProps, 'Button publish error');
      }
      component.set('v.creatingButtons', false);
    });
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
  },

  getButtonLabelValidity: function (component) {
    return component.find('buttonLabel').get('v.validity').valid;
  }
});
