({
  onLoad: function (component, event, helper) {
    var progress = component.get('v.progress');
    var action = component.get('c.getProgressStatus');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var status = response.getReturnValue();
        var count = 0;
        status.forEach(function (step) {
          switch (step.Name) {
            case 'InstallChecklistStep1':
              component.set('v.step1', true);
              progress += 17;
              component.set('v.isStep2Disabled', false);
              count++;
              break;
            case 'InstallChecklistStep2':
              component.set('v.step2', true);
              component.set('v.isStep2Disabled', false);
              progress += 17;
              component.set('v.isStep3Disabled', false);
              count++;
              break;
            case 'InstallChecklistStep3':
              component.set('v.step3', true);
              component.set('v.isStep3Disabled', false);
              progress += 17;
              component.set('v.isStep4Disabled', false);
              count++;
              break;
            case 'InstallChecklistStep4':
              component.set('v.step4', true);
              component.set('v.isStep4Disabled', false);
              progress += 17;
              component.set('v.isStep5Disabled', false);
              count++;
              break;
            case 'InstallChecklistStep5':
              component.set('v.step5', true);
              component.set('v.isStep5Disabled', false);
              progress += 17;
              component.set('v.isStep6Disabled', false);
              count++;
              break;
            case 'InstallChecklistStep6':
              component.set('v.step6', true);
              component.set('v.isStep6Disabled', false);
              progress += 17;
              count++;
              break;
          }
        });
        if (progress > 100) {
          progress = 100;
        }
        component.set('v.progress', progress);
        if (count === 6) {
          component.set('v.isComplete', false);
          component.set('v.isFinished', true);
        }
      } else if (state === 'ERROR') {
        var errors = response.getError();
        if (errors && errors[0] && errors[0].message) {
          helper.fireToast(component, errors[0].message, this.ERROR);
        }
      }
    });
    $A.enqueueAction(action);
  },

  toggleSection: function (component, event, helper) {
    helper.toggleView(component);
  },

  handleFinish: function (component, event, helper) {
    helper.toggleView(component);
    component.set('v.isComplete', false);
    component.set('v.isFinished', true);
  },

  onHelp: function (component, event) {
    var name = event.currentTarget.id;
    switch (name) {
      case 'step1':
        navUtils.navigateToUrl($A.get('$Label.c.MappingGuideURL'));
        break;
      case 'step2':
        navUtils.navigateToUrl($A.get('$Label.c.AddCompToLayoutsURL'));
        break;
      case 'step3':
        navUtils.navigateToUrl($A.get('$Label.c.LearnDocGenBasicsURL'));
        break;
      case 'step4':
        navUtils.navigateToUrl($A.get('$Label.c.LearnDocGenBasicsURL'));
        break;
      case 'step5':
        navUtils.navigateToUrl($A.get('$Label.c.AddButtonToLayoutURL'));
        break;
      case 'step6':
        navUtils.navigateToUrl($A.get('$Label.c.AddButtonToLayoutURL'));
        break;
    }
  },

  onSelection: function (component, event, helper) {
    var name = event.getSource().get('v.name');
    var progress = component.get('v.progress');
    switch (name) {
      case 'input1':
        if (component.get('v.step1') === true) {
          progress += 17;
          component.set('v.isStep2Disabled', false);
        }
        else {
          progress -= 17;
          component.set('v.isComplete', false);
        }
        helper.updateState(component, 'InstallChecklistStep1', component.get('v.step1'));
        break;
      case 'input2':
        if (component.get('v.step2') === true) {
          progress += 17;
          component.set('v.isStep3Disabled', false);
        }
        else {
          progress -= 17;
          component.set('v.isComplete', false);
        }
        helper.updateState(component, 'InstallChecklistStep2', component.get('v.step2'));
        break;
      case 'input3':
        if (component.get('v.step3') === true) {
          progress += 17;
          component.set('v.isStep4Disabled', false);
        }
        else {
          progress -= 17;
          component.set('v.isComplete', false);
        }
        helper.updateState(component, 'InstallChecklistStep3', component.get('v.step3'));
        break;
      case 'input4':
        if (component.get('v.step4') === true) {
          progress += 17;
          component.set('v.isStep5Disabled', false);
        }
        else {
          progress -= 17;
          component.set('v.isComplete', false);
        }
        helper.updateState(component, 'InstallChecklistStep4', component.get('v.step4'));
        break;
      case 'input5':
        if (component.get('v.step5') === true) {
          progress += 17;
          component.set('v.isStep6Disabled', false);
        }
        else {
          progress -= 17;
          component.set('v.isComplete', false);
        }
        helper.updateState(component, 'InstallChecklistStep5', component.get('v.step5'));
        break;
      case 'input6':
        if (component.get('v.step6') === true) {
          progress += 17;
        }
        else {
          progress -= 17;
          component.set('v.isComplete', false);
        }
        helper.updateState(component, 'InstallChecklistStep6', component.get('v.step6'));
        break;
      default:
    }
    if (progress > 100) {
      component.set('v.isComplete', true);
    }
    component.set('v.progress', progress);
  },

  onNavigate: function (component, event, helper) {
    var name = event.currentTarget.id;
    switch (name) {
      case 'step1':
        helper.fireApplicationEvent(component, {
          fromComponent: 'CLMChecklist',
          toComponent: 'CLMSetupLayout',
          type: 'update',
          tabIndex: '3',
        }, 'CLMNavigationEvent');
        break;
      case 'step2':
        helper.openSetup(component);
        break;
      case 'step3':
      case 'step4':
      case 'step5':
        helper.callServer(component, 'c.getDocGenButtonLink', false, function (result) {
          navUtils.navigateToUrl(result);
        });
        break;
      case 'step6':
        helper.openSetup(component);
        break;
    }
  }
})
