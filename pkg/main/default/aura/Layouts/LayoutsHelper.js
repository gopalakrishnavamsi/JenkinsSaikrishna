({
  uiHelper: function (component) {
    return component.get('v.uiHelper');
  },

  getConfiguration: function (component) {
    this.uiHelper(component).invokeAction(component.get('c.getConfiguration'), null, function (configuration) {
      component.set('v.sendActionName', configuration.sendActionName);
      component.set('v.commonObjects', configuration.commonObjects);
      component.set('v.allObjects', configuration.allObjects);
    });
  },

  getActions: function (layout) {
    var result = {
      classic: false, lightning: false
    };
    if (!$A.util.isUndefinedOrNull(layout) && !$A.util.isEmpty(layout.actions)) {
      for (var i = 0; i < layout.actions.length; i++) {
        var action = layout.actions[i];
        if (action.type === 'SEND') {
          if (action.isLightning) {
            result.lightning = true;
          } else {
            result.classic = true;
          }
        }
      }
    }
    return result;
  },

  processLayouts: function (layouts) {
    var result = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        var layout = layouts[i];
        var actions = this.getActions(layout);
        layout.hasSendClassic = actions.classic;
        layout.hasSendLightning = actions.lightning;
        result.push(layout);
      }
    }
    return result;
  },

  getLayouts: function (component) {
    var self = this;
    self.uiHelper(component).invokeAction(component.get('c.getLayouts'), {sObjectType: component.get('v.sObjectType')}, function (layouts) {
      component.set('v.layouts', self.processLayouts(layouts));
      component.set('v.isDirty', false);
    });
  },

  getLayoutsJson: function (layouts, sendActionName) {
    var ls = [];
    if (!$A.util.isEmpty(layouts)) {
      for (var i = 0; i < layouts.length; i++) {
        var layout = layouts[i];
        layout.actions = [];
        if (layout.hasSendClassic) {
          layout.actions.push({
            type: 'SEND', name: sendActionName, isLightning: false
          });
        }
        if (layout.hasSendLightning) {
          layout.actions.push({
            type: 'SEND', name: sendActionName, isLightning: true
          });
        }
        // TODO: Add other action types
        delete layout.hasSendClassic;
        delete layout.hasSendLightning;
        ls.push(layout);
      }
    }
    return JSON.stringify(ls);
  },

  updateLayouts: function (component) {
    var self = this;
    var uiHelper = self.uiHelper(component);
    uiHelper.invokeAction(component.get('c.updateLayouts'), {
      sObjectType: component.get('v.sObjectType'),
      layoutsJson: self.getLayoutsJson(component.get('v.layouts'), component.get('v.sendActionName'))
    }, function (layouts) {
      component.set('v.layouts', self.processLayouts(layouts));
      component.set('v.isDirty', false);
      uiHelper.showToast($A.get('$Label.c.SuccessfullyModifiedLayouts'), 'success');
    });
  }
});
