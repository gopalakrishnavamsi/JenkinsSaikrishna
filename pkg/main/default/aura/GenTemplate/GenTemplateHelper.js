({
  editName: function (component) {
    component.set('v.editName', true);

    window.setTimeout($A.getCallback(function () {
      component.find('edit-record-name').focus();
    }), 1);
  },

  saveData: function (component) {
    return new Promise($A.getCallback(function (resolve, reject) {
      var config = component.get('v.config');
      if (config.isSample) {
        resolve();
        return;
      }
      component.set('v.saving', true);

      var action = component.get('c.saveTemplate');
      var saveTemplateParameters = JSON.stringify(config);
      action.setParams({
        templateJson: saveTemplateParameters
      });

      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve();
          component.set('v.saving', false);
        } else {
          component.set('v.saving', false);
          reject();
        }
      });

      $A.enqueueAction(action);
    }));
  },

  goToStep: function (component, stepIndex) {
    var helper = this;
    var steps = component.find('step');
    var step = Array.isArray(steps) ? steps[0] : steps;

    step.validate().then($A.getCallback(function () {
      var isCompleted = component.get('v.isCompleted');

      if (!isCompleted) {
        var config = component.get('v.config');

        if (stepIndex > config.stepsCompleted) {
          config.stepsCompleted++;
          component.set('v.config', config);
        }
      }

      return helper.saveData(component);
    })).then($A.getCallback(function () {
      component.set('v.currentStep', stepIndex);
    }));
  },

  goToRecord: function (component) {
    var templateId = component.get('v.templateId');
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": templateId,
    });
    navEvt.fire();
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
  }
});