({
  onInit: function (component) {
    component.set('v.isEmpty', false);
  },

  gotoNew: function (component, event, helper) {
    //fire event to display CLMCardModel
    helper.insertComponent(component, 'c:CLMMappedObjectsEdit', {});
    component.set('v.showHelp', false);
    component.set('v.showTrouble', false);
    component.set('v.showPathAndNew', true);
    component.set('v.showObjFolderCard', true);
    helper.fireApplicationEvent(
      component,
      {
        title: $A.get('$Label.c.SelectObject'),
        summary: $A.get('$Label.c.SelectObjectHelpBody').concat(' ', $A.get('$Label.c.SelectObjectHelpBody2')),
        index: '1',
        fromComponent: 'CLMIntegrationLayout',
        toComponent: 'CLMCardModel',
        type: 'update'
      },
      'CLMCardModelEvent'
    );
    //update layout DFS-0000
    helper.fireApplicationEvent(
      component,
      {
        fromComponent: 'CLMMappedObjectsHome',
        toComponent: 'CLMSetupLayout',
        type: 'update',
        tabIndex: '3.1'
      },
      'CLMNavigationEvent'
    );
  },

  updateUI: function (component, event, helper) {
    var componentName = event.getParam('componentName');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    var type = event.getParam('type');
    var data = event.getParam('data');
    if (
      toComponent === 'CLMIntegrationLayout' &&
      fromComponent !== 'CLMIntegrationLayout'
    ) {
      if (type === 'show' && componentName === 'CLMCardModel') {
        helper.insertComponent(component, 'c:CLMMappedObjectsEdit', {});
        component.set('v.showHelp', false);
        component.set('v.showTrouble', false);
        component.set('v.showPathAndNew', true);
        component.set('v.showObjFolderCard', true);
        helper.fireApplicationEvent(
          component,
          {
            title: $A.get('$Label.c.SelectObject'),
            summary: $A.get('$Label.c.SelectObjectHelpBody').concat(' ', $A.get('$Label.c.SelectObjectHelpBody2')),
            index: '1',
            fromComponent: 'CLMIntegrationLayout',
            toComponent: 'CLMCardModel',
            type: 'update'
          },
          'CLMCardModelEvent'
        );
      } else if (type === 'show' && componentName === 'CLMMappedObjectsHome') {
        component.set('v.showHelp', true);
        component.set('v.showTrouble', true);
        component.set('v.showPathAndNew', false);
        component.set('v.showObjFolderCard', false);
      } else if (type === 'edit' && componentName === 'CLMCardModel') {
        helper.insertComponent(component, 'c:CLMMappedObjectsEdit', {
          selectedObjDetails: data.objDetails,
          isEdit: true
        });
        component.set('v.showHelp', false);
        component.set('v.showTrouble', false);
        component.set('v.showPathAndNew', true);
        component.set('v.showObjFolderCard', true);
      } else if (type === 'hide' && componentName === 'CLMCardModel') {
        component.set('v.isEmpty', true);
      }
    }
  },

  onPrimaryButtonClick: function (component, event, helper) {
    var buttonLabel = event.getParam('buttonLabel');
    var action = component.get('c.getCurrentUserExperience');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var theme = response.getReturnValue();
        if (
          buttonLabel === $A.get('$Label.c.ConfigureLayouts') ||
          buttonLabel === $A.get('$Label.c.ConfigureButtons')
        ) {
          if (
            theme === 'Theme4d' ||
            theme === 'Theme4t' ||
            theme === 'Theme4u'
          ) {
            navUtils.navigateToUrl($A.get('$Label.c.LEXObjectManagerURL'));
          } else {
            navUtils.navigateToUrl($A.get('$Label.c.ClassicObjectManagerURL'));
          }
        }
      } else if (state === 'ERROR') {
        helper.fireToast(component, response.getError()[0].message, helper.ERROR);
      }
    });
    $A.enqueueAction(action);
  },

  onSecondaryButtonClick: function (component, event, helper) {
    helper.fireApplicationEvent(
      component,
      {
        fromComponent: 'CLMHomeBody',
        toComponent: 'CLMSetupLayout',
        type: 'update',
        tabIndex: '8'
      },
      'CLMNavigationEvent'
    );
  }  
});