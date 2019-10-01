({
  editName: function (component) {
    component.set('v.editName', true);

    window.setTimeout(
      $A.getCallback(function () {
        component.find('edit-record-name').focus();
      }),
      1
    );
  },

  saveData: function (component,isNavigate) {
    var helper = this;
    component.set('v.saving', true);
    var isImportStep = component.get('v.currentStep') === 2;
    if (isImportStep) {
      var getConfigAction = helper.getConfiguration(component);
      getConfigAction.then(
        $A.getCallback(function (results) {
          component.set('v.saving', false);
          component.set('v.config', results.template);
          helper.saveTemplate(component,isNavigate);
        })
      );
    } else {
      component.set('v.saving', false);
      helper.saveTemplate(component,isNavigate);
    }
  },

  goToStep: function (component, stepIndex) {
    var helper = this;
    var steps = component.find('step');
    var step = Array.isArray(steps) ? steps[0] : steps;

    step
      .validate()
      .then(
        $A.getCallback(function () {
          var isCompleted = component.get('v.isCompleted');

          if (!isCompleted) {
            var config = component.get('v.config');

            if (stepIndex > config.stepsCompleted) {
              config.stepsCompleted++;
              component.set('v.config', config);
            }
          }

          return helper.saveData(component,false);
        })
      )
      .then(
        $A.getCallback(function () {
          component.set('v.currentStep', stepIndex);
        })
      );
  },

  goToRecord: function (component) {
    var templateId = component.get('v.templateId');
    navUtils.navigateToSObject(templateId);
  },

  updateShowWhatYouWillNeedModalSettings: function (component) {
    var action = component.get('c.updateModalSettings');
    action.setCallback(this, function (res) {
      var parsedRes = JSON.parse(res.getReturnValue());
      if (!parsedRes.isSuccess) {
        component.set('v.errMsg', parsedRes.errMsg);
      }
    });
    $A.enqueueAction(action);
  },

  initSetup: function (component) {
    component.set('v.saving', true);
    var helper = this;
    var steps = component.get('v.steps');
    steps = [
      $A.get('$Label.c.AddObjectsStep'),
      $A.get('$Label.c.AddMergeFieldsStep'),
      $A.get('$Label.c.WordTemplatesStep'),
      $A.get('$Label.c.PreviewStep'),
      $A.get('$Label.c.PublishStep')
    ];
    component.set('v.steps', steps);
    var templateId = component.get('v.templateId');
    var getConfigAction = helper.getConfiguration(component);
    getConfigAction.then(
      $A.getCallback(function (results) {
        results.allObjects.sort(function (a, b) {
          if (a.label > b.label) {
            return 1;
          } else {
            return -1;
          }
        });
        component.set('v.config', results.template);
        component.set('v.files', results.template.generated);
        component.set('v.availableObjects', results.allObjects);
        component.set('v.commonObjects', results.commonObjects);
        var labelByApiName = {};
        results.allObjects.forEach(function (object) {
          var objectKey = object.name;
          var objectName = object.label;
          labelByApiName[objectKey] = objectName;
        });
        component.set('v.labelByApiName', labelByApiName);

        if ($A.util.isEmpty(templateId)) {
          component.set('v.templateId', results.template.id);
        }
        if (results.template.stepsCompleted >= steps.length) {
          component.set('v.currentStep', 0);
          component.set('v.isCompleted', true);
        } else {
          component.set('v.currentStep', results.template.stepsCompleted);
          component.set('v.isCompleted', false);
        }
        component.set('v.saving', false);
      })
    );
  },

  getConfiguration: function (component) {
    component.set('v.saving', true);
    return new Promise(
      $A.getCallback(function (resolve) {
        var templateId = component.get('v.templateId');
        if ($A.util.isEmpty(templateId)) {
          templateId = null;
        }
        var getConfigAction = component.get('c.getConfiguration');
        getConfigAction.setParams({
          templateId: templateId
        });
        getConfigAction.setCallback(this, function (response) {
          component.set('v.saving', false);
          var state = response.getState();
          if (state === 'SUCCESS') {
            var results = response.getReturnValue();
            resolve(results);
          } else {
            component.set('v.errMsg', stringUtils.getErrorMessage(response));
          }
        });
        $A.enqueueAction(getConfigAction);
      })
    );
  },

  saveTemplate: function (component,isNavigate) {
    var helper = this;
    component.set('v.saving', true);
    var config = component.get('v.config');
    if (config.isSample) {
      return;
    }
    var action = component.get('c.saveTemplate');
    var saveTemplateParameters = JSON.stringify(config);
    action.setParams({
      templateJson: saveTemplateParameters
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      component.set('v.saving', false);
      if (state === 'SUCCESS') {
        if(isNavigate){
          helper.goToRecord(component);
        }
      }else{
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
      }
    });
    $A.enqueueAction(action);
  }
});
