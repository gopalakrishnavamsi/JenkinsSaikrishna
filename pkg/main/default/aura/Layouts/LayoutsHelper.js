({
  getConfiguration: function (component) {
    this.invokeAction(component, component.get('c.getConfiguration'), null, function (configuration) {
      component.set('v.sendActionName', configuration.sendActionName);
      component.set('v.commonObjects', configuration.commonObjects);
      component.set('v.allObjects', configuration.allObjects);
    });
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

  getLayouts: function (component) {
    var self = this;
    this.invokeAction(component, component.get('c.getLayouts'), {sObjectType: component.get('v.sObjectType')}, function (layouts) {
      component.set('v.layouts', self.processLayouts(layouts));
      component.set('v.isDirty', false);
    });
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

  onUpdateComplete: function (component) {
    component.set('v.isDirty', false);
    component.set('v.layouts', this.processLayouts(component.get('v.layouts')));
    this.showToast(component, $A.get('$Label.c.SuccessfullyModifiedLayouts'), 'success');
  },

  updateLayouts: function (component) {
    var self = this;
    var layouts = this.getLayoutsToUpdate(component.get('v.layouts'), component.get('v.sendActionName'));
    if ($A.util.isEmpty(layouts)) {
      this.onUpdateComplete(component);
    } else {
      this.invokeAction(component, component.get('c.updateLayouts'), {
        sObjectType: component.get('v.sObjectType'), layoutsJson: JSON.stringify(layouts)
      }, function () {
        self.onUpdateComplete(component);
      });
    }
  }
});
