({
  onInit: function (component, event, helper) {
    helper.setBreadcrumbDefaultValues(component);
    helper.setPathDefaultValues(component);
    helper.insertComponent(component, 'c:CLMMappedObjectsEdit', {});
  },

  updateFromBreadCrumbUI: function (component, event) {
    var navigateTo = event.getParam('navigateTo');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    if ((toComponent === 'CLMIntegrationLayout' || toComponent === 'ANY') && fromComponent !== 'CLMIntegrationLayout') {
      if (navigateTo !== undefined && navigateTo.navigateTo === 'CLMMappedObjectsHome') {
        component.set('v.showHelp', true);
        component.set('v.showTrouble', true);
        component.set('v.showPathAndNew', false);
      }
    }
  },
  
  updateUI: function (component, event, helper) {
    var componentName = event.getParam('componentName');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');

    if (toComponent === 'CLMIntegrationLayout' && fromComponent !== 'CLMIntegrationLayout') {
      if (type === 'show' && componentName === 'CLMCardModel') {
        component.set('v.showHelp', false);
        component.set('v.showTrouble', false);
        component.set('v.showPathAndNew', true);
        helper.fireApplicationEvent(component, {
          title: $A.get('$Label.c.SelectObject'),
          summary: $A.get('$Label.c.SelectObjectHelpBody').concat(' ', $A.get('$Label.c.SelectObjectHelpBody2')),
          index: '1',
          body: '',
          fromComponent: 'CLMIntegrationLayout',
          toComponent: 'CLMCardModel',
          type: 'update'
        }, 'CLMCardModelEvent');

      } else if (type === 'show' && componentName === 'CLMMappedObjectsHome') {
        component.set('v.showHelp', true);
        component.set('v.showTrouble', true);
        component.set('v.showPathAndNew', false);
      }
    }
  },
  
  onPrimaryButtonClick: function (component, event) {
    var buttonLabel = event.getParam('buttonLabel');
    var action = component.get('c.getCurrentUserExperience');
    action.setCallback(this, function(response){
        var state = response.getState();
        if(state === 'SUCCESS'){
            var theme = response.getReturnValue();   
            if (buttonLabel === $A.get('$Label.c.ConfigureLayouts') || buttonLabel === $A.get('$Label.c.ConfigureButtons')) {
                if (theme === 'Theme4d' || theme === 'Theme4t' || theme === 'Theme4u') {
                    window.open($A.get('$Label.c.LEXObjectManagerURL'));
                } else {          
                    window.open($A.get('$Label.c.ClassicObjectManagerURL'));
                }
            }     
        }else{
            $A.log('Callback failed.');
        }
    });
    $A.enqueueAction(action);
  },
  
  onSecondaryButtonClick: function (component, event, helper) {
    helper.fireApplicationEvent(component, {
      fromComponent: 'CLMHomeBody',
      toComponent: 'CLMSetupLayout',
      type: 'update',
      tabIndex: '8',
    }, 'CLMNavigationEvent');
  },

  updateUIWithAdditionalHelpCard: function(component, event) {
    var navigateTo = event.getParam('navigateTo');
    if(navigateTo.index === '2' || navigateTo.index === '3') {
      component.set('v.showAdditionalHelpCard', true);
    }
  }

})
