({
  loadCurrentLevelFieldOptions: function (component, event, helper) {
    var self = this;
    var fieldOptions = component.get('v.currentLevelFieldOptions');
    if ($A.util.isUndefinedOrNull(fieldOptions)) {
      var objectName = component.get('v.template').objectMappings.name;
      var maxDepth = 5;
      helper.fetchMergeFields(component, objectName, maxDepth,
        function (response) {
          var currentLevelFieldOptions = response.filter(function (f) {
            return f.type !== 'TEXTAREA'
          });
          component.set('v.currentLevelFieldOptions', currentLevelFieldOptions);
        }, function (error) {
          self.showToast(component, error, 'error');
        });
    }
  },

  fetchMergeFields: function (component, objectName, depth, onSuccess, onError) {
    var action = component.get('c.getMergeFields');
    var parameters = {
      sObjectType: objectName,
      depth: depth
    };
    this.invokeAction(component, action, parameters, onSuccess, onError);
  },

  saveDocumentRule: function (component, event) {
    var eventData = event.getParam('data');
    var templateIndex = eventData.fileIndex;
    var templateRule = eventData.rule;
    var updatedTemplates = component.get('v.files').slice();

    updatedTemplates[templateIndex].rule = templateRule;
    component.set('v.files', updatedTemplates);
  },

  clearDocumentRule: function (component, event) {
    var eventData = event.getParam('data');
    var templateIndex = eventData.fileIndex;
    var updatedTemplates = component.get('v.files').slice();

    updatedTemplates[templateIndex].rule = null;
    component.set('v.files', updatedTemplates);
  }
});
