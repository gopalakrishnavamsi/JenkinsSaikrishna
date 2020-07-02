({
  CREATE_TEMPLATE: 'Create Gen Template',
  UPDATE_TEMPLATE: 'Update Gen Template',

  _getUserEvents: function (component) {
    return component.find('ds-user-events');
  },

  _getEventName: function (component) {
    return component.get('v.isCreating') ? this.CREATE_TEMPLATE : this.UPDATE_TEMPLATE;
  },

  _getEventProperties: function (template) {
    return $A.util.isUndefinedOrNull(template) ? {} : {
      'Source Object': stringUtils.sanitizeObjectName(template.sourceObject),
      'Template Files': $A.util.isEmpty(template.generated) ? 0 : template.generated.length
    };
  },

  editName: function (component) {
    component.set('v.editName', true);

    window.setTimeout(
      $A.getCallback(function () {
        component.find('edit-record-name').focus();
      }),
      1
    );
  },

  saveData: function (component, isNavigate) {
    var helper = this;
    component.set('v.saving', true);
    helper.saveTemplate(component, isNavigate);
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
            var template = component.get('v.template');

            if (stepIndex > template.stepsCompleted) {
              template.stepsCompleted++;
              component.set('v.template', template);
            }
          }

          return helper.saveData(component, false);
        })
      )
      .then(
        $A.getCallback(function () {
          component.set('v.currentStep', stepIndex);
        })
      );
  },

  goToRecord: function (component, isCanceling) {
    if (isCanceling) {
      this._getUserEvents(component).cancel(
        this._getEventName(component),
        this._getEventProperties(component.get('v.template')));
    }
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
    var isAuthorized = component.get('v.isAuthorized');
    var isGenEnabled = component.get('v.isGenEnabled');
    if (isAuthorized && isGenEnabled) {
      component.set('v.saving', true);

      var userEvents = this._getUserEvents(component);
      userEvents.addProperties({
        'Product': 'Gen',
        'Template Type': 'Word'
      });
      userEvents.time(this._getEventName(component));

      var steps = component.get('v.steps');
      steps = [
        $A.get('$Label.c.AddObjectsStep'),
        $A.get('$Label.c.AddMergeFieldsStep'),
        $A.get('$Label.c.WordTemplatesStep'),
        $A.get('$Label.c.PreviewStep'),
        $A.get('$Label.c.PublishStep')
      ];
      component.set('v.steps', steps);

      var getConfigAction = this.getConfiguration(component);
      getConfigAction.then(
        $A.getCallback(function (results) {
          results.allObjects.sort(function (a, b) {
            if (a.label > b.label) {
              return 1;
            } else {
              return -1;
            }
          });
          component.set('v.template', results.template);
          component.set('v.files', results.template.generated);
          component.set('v.availableObjects', results.allObjects);
          component.set('v.commonObjects', results.commonObjects);
          var labelByApiName = {};
          results.allObjects.forEach(function (object) {
            labelByApiName[object.name] = object.label;
          });
          component.set('v.labelByApiName', labelByApiName);

          if ($A.util.isEmpty(component.get('v.templateId'))) {
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
    }
  },

  getConfiguration: function (component) {
    component.set('v.saving', true);
    var self = this;
    return new Promise(
      $A.getCallback(function (resolve) {
        var templateId = component.get('v.templateId');
        if ($A.util.isEmpty(templateId)) {
          templateId = null;
        }
        var getConfigAction = component.get('c.getConfiguration');
        getConfigAction.setParams({
          templateId: templateId,
          isGenerating: false,
        });
        getConfigAction.setCallback(this, function (response) {
          component.set('v.saving', false);
          var state = response.getState();
          if (state === 'SUCCESS') {
            var results = response.getReturnValue();
            component.set('v.useGenV1', results.useGenV1 === true);
            self._getUserEvents(component).addProperties({
              'Multi-Currency': results.isMultiCurrencyOrganization === true,
              'Gen V1': results.useGenV1 === true
            });
            resolve(results);
          } else {
            component.set('v.errMsg', stringUtils.getErrorMessage(response));
          }
        });
        $A.enqueueAction(getConfigAction);
      })
    );
  },

  saveTemplate: function (component, isNavigate) {
    var helper = this;
    component.set('v.saving', true);
    var template = component.get('v.template');
    template.generated = component.get('v.files');
    component.set('v.template', template);

    if (template.isSample) {
      return;
    }

    var action = component.get('c.saveTemplate');
    action.setParams({
      templateJson: JSON.stringify(template)
    });
    action.setCallback(this, function (response) {
      var userEvents = helper._getUserEvents(component);
      var eventName = helper._getEventName(component);
      var eventProperties = helper._getEventProperties(template);
      var state = response.getState();
      component.set('v.saving', false);
      if (state === 'SUCCESS') {
        if (isNavigate) {
          userEvents.success(eventName, eventProperties);
          helper.goToRecord(component, false);
        }
      } else {
        userEvents.error(eventName, eventProperties, 'Failed to save template');
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
      }
    });
    $A.enqueueAction(action);
  }
});
