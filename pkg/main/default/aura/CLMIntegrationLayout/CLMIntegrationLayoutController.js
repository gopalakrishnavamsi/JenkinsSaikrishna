({
  onInit: function (component, event, helper) {
    helper.setBreadcrumbDefaultValues(component);
    helper.setPathDefaultValues(component);
  },

  updateFromBreadCrumbUI: function (component, event) {
    var navigateTo = event.getParam('navigateTo');
    var fromComponent = event.getParam('fromComponent');
    var toComponent = event.getParam('toComponent');
    if (
      (toComponent === 'CLMIntegrationLayout' || toComponent === 'ANY') &&
      fromComponent !== 'CLMIntegrationLayout'
    ) {
      if (
        $A.util.isUndefinedOrNull(navigateTo) &&
        navigateTo.navigateTo === 'CLMMappedObjectsHome'
      ) {
        component.set('v.showHelp', true);
        component.set('v.showTrouble', true);
        component.set('v.showPathAndNew', false);
        component.set('v.showObjFolderCard', false);
      }
    }
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
        helper.setBreadcrumbDefaultValues(component);
        component.set('v.showHelp', false);
        component.set('v.showTrouble', false);
        component.set('v.showPathAndNew', true);
        component.set('v.showObjFolderCard', true);
        helper.fireApplicationEvent(
          component,
          {
            title: $A.get('$Label.c.SelectObject'),
            summary: $A
              .get('$Label.c.SelectObjectHelpBody')
              .concat(' ', $A.get('$Label.c.SelectObjectHelpBody2')),
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
        helper.setBreadcrumbEditObjectValues(component);
        helper.fireApplicationEvent(
          component,
          {
            navigateTo: { index: '2' },
            fromComponent: 'CLMMappedObjectsHome',
            toComponent: 'CLMBreadcrumbs'
          },
          'CLMBreadcrumbsEvent'
        );
        component.set('v.showHelp', false);
        component.set('v.showTrouble', false);
        component.set('v.showPathAndNew', true);
        component.set('v.showObjFolderCard', true);
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
  },

  updateUIWithAdditionalHelpCard: function (component, event) {
    var navigateTo = event.getParam('navigateTo');
    if (navigateTo.index === '2' || navigateTo.index === '3') {
      component.set('v.showObjFolderCard', true);
    }
  }
});