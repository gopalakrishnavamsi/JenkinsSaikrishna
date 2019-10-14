({
  getConfiguration: function (component, event, helper) {
    component.set('v.loading', true);
    var getConfigurationAction = component.get('c.getConfiguration');
    getConfigurationAction.setCallback(this, $A.getCallback(function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var configuration = response.getReturnValue();
        component.set('v.sendActionName', configuration.sendActionName);
        component.set('v.commonObjects', configuration.commonObjects);
        component.set('v.allObjects', configuration.allObjects);
      }
      else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
      component.set('v.loading', false);
    }));
    $A.enqueueAction(getConfigurationAction);
  },

  hasSendAction: function (layout) {
    if (!$A.util.isUndefinedOrNull(layout) && !$A.util.isEmpty(layout.actions)) {
      for (var i = 0; i < layout.actions.length; i++) {
        var action = layout.actions[i];
        if (action.type === 'SEND') {
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

  processLayouts: function (layouts) {
    var result = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        var layout = layouts[i];
        delete layout.original;
        layout.hasSendAction = layout.hasOwnProperty('hasSendAction') ? layout.hasSendAction : this.hasSendAction(layout);
        layout.original = this.copyLayout(layout);
        result.push(layout);
      }
    }
    return result;
  },

  getLayouts: function (component, event, helper) {
    if ($A.util.isEmpty(component.get('v.sObjectType'))) {
      component.set('v.layouts', []);
    }
    else {
      component.set('v.loading', true);
      var getLayoutsAction = component.get('c.getLayouts');
      getLayoutsAction.setParams({
        sObjectType: component.get('v.sObjectType')
      });
      getLayoutsAction.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var layouts = response.getReturnValue();
          component.set('v.layouts', helper.processLayouts(layouts));
          component.set('v.isDirty', false);
        }
        else {
          helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        }
        component.set('v.loading', false);
      }));
      $A.enqueueAction(getLayoutsAction);
    }
  },

  isDirty: function (layouts) {
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        if (this.isLayoutDirty(layouts[i])) {
          return true;
        }
      }
    }
    return false;
  },

  isLayoutDirty: function (layout) {
    return (!$A.util.isUndefinedOrNull(layout) && !$A.util.isUndefinedOrNull(layout.original) && layout.hasSendAction !== layout.original.hasSendAction);
  },

  getLayoutsToUpdate: function (layouts, sendActionName) {
    var ls = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        if (!this.isLayoutDirty(layouts[i])) continue;
        var layout = this.copyLayout(layouts[i]);
        layout.actions = [];
        if (layout.hasSendAction) {
          layout.actions.push({
            type: 'SEND', name: sendActionName
          });
        }
        // TODO: Add other action types
        delete layout.hasSendAction;
        delete layout.original;
        ls.push(layout);
      }
    }
    return ls;
  },

  onUpdateComplete: function (component, event, helper) {
    component.set('v.isDirty', false);
    component.set('v.layouts', this.processLayouts(component.get('v.layouts')));
    helper.showToast(component, $A.get('$Label.c.SuccessfullyModifiedLayouts'), 'success');
  },

  updateLayouts: function (component, event, helper) {
    var layouts = this.getLayoutsToUpdate(component.get('v.layouts'), component.get('v.sendActionName'));
    if ($A.util.isEmpty(layouts)) {
      this.onUpdateComplete(component);
    } else {
      component.set('v.loading', true);
      var updateLayoutsAction = component.get('c.updateLayouts');
      updateLayoutsAction.setParams({
        sObjectType: component.get('v.sObjectType'),
        layoutsJson: JSON.stringify(layouts),
        parameters: null
      });
      updateLayoutsAction.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          helper.onUpdateComplete(component, event, helper);
        }
        else {
          helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        }
        component.set('v.loading', false);
      }));
      $A.enqueueAction(updateLayoutsAction);
    }
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  }
});