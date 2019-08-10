({
  onInit: function (component, event, helper) {
    helper.callServer(component, 'c.getMappedObjectsList', false, function (result) {
      component.set('v.mappedObjData', Object.values(result));
    });
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      primaryButtonLabel: $A.get('$Label.c.Remove'),
      secondaryButtonLabel: $A.get('$Label.c.Cancel'),
      primaryButtonVariant: 'destructive'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);
    });
  },

  gotoNew: function (component, event, helper) {
    //fire event to update breadcrumb
    helper.fireApplicationEvent(component, {
      navigateTo: { index: '2' },
      fromComponent: 'CLMMappedObjectsHome',
      toComponent: 'CLMBreadcrumbs'
    }, 'CLMBreadcrumbsEvent');
    //fire event to display CLMCardModel
    helper.fireApplicationEvent(component, {
      componentName: 'CLMCardModel',
      fromComponent: 'CLMMappedObjectsHome',
      toComponent: 'CLMIntegrationLayout',
      type: 'show'
    }, 'CLMNavigationEvent');
  },

  edit: function (component, event) {
    var id = event.getSource().get('v.value');
    component.set('v.tempMappingModelDataHolder', {
      id: id,
      type: 'edit'
    });
    var modelTitleText = $A.get('$Label.c.ConfirmEdits');
    var modelbodyText = $A.get('$Label.c.EditModalBody');
    component.set('v.modelTitleText', modelTitleText);
    component.set('v.modelbodyText', modelbodyText);
    component.set('v.modelPrimaryButtonText', 'Confirm');
    component.set('v.modelSecondaryButtonText', 'Cancel');
    component.set('v.showModal', 'true');
    var modelComponent = component.find('popupModel');
    setTimeout($A.getCallback(function () {
      modelComponent.show();
    }), 5);
    var cmpEvent = component.getEvent('CLMScopedNotificationEvent');
    cmpEvent.fire();
  },

  remove: function (component, event, helper) {
    var id = event.getSource().get('v.value');
    component.set('v.tempMappingModelDataHolder', {
      id: id,
      type: 'remove'
    });
    helper.createComponent(component, 'c:CLMModelFooterButton', {
      primaryButtonLabel: $A.get('$Label.c.Remove'),
      secondaryButtonLabel: $A.get('$Label.c.Cancel'),
      primaryButtonVariant: 'destructive'
    }, function (newCmp) {
      component.set('v.strikeModelFooterButtons', newCmp);
      component.set('v.isRemove', 'true');
    });
    var modelTitle = $A.get('$Label.c.RemoveMapping');
    var modelbody = $A.get('$Label.c.RemoveModalBody');
    component.set('v.modelTitleText', modelTitle);
    component.set('v.modelbodyText', modelbody);
    component.set('v.modelPrimaryButtonText', 'Remove');
    component.set('v.modelSecondaryButtonText', 'Cancel');
    component.set('v.showModal', 'true');
    var modelComponent = component.find('popupModel');
    setTimeout($A.getCallback(function () {
      modelComponent.show();
    }), 5);
  },

  editMappingModelHandler: function (component, event, helper) {
    var data = component.get('v.tempMappingModelDataHolder');
    var modelComponent = component.find('popupModel');
    var mappedObjData = component.get('v.mappedObjData');
    var objDetails;
    mappedObjData.forEach(function (obj) {
      if (obj.Id === data.id) {
        objDetails = obj;
      }
    });
    if (data.type === 'remove') {
      helper.callServer(component, 'c.removeMappedObject', {
        name: objDetails.Name
      }, function () {
        helper.fireToast(component, stringUtils.format($A.get('$Label.c.ObjectRemoved'), objDetails.Name), helper.SUCCESS);
        component.getEvent('CLMScopedNotificationEvent').fire();
        component.set('v.isRemove', 'false');
        var newObjectList = [];
        mappedObjData.forEach(function (obj) {
          if (obj.Id !== data.id) {
            newObjectList.push(obj);
          }
        });
        component.set('v.mappedObjData', newObjectList);
        modelComponent.hide();
      });
    } else if (data.type === 'edit') {
      helper.fireToast(component, stringUtils.format($A.get('$Label.c.ObjectEditSuccessful'), objDetails.Name), helper.SUCCESS);
      modelComponent.hide();
    }
    component.set('v.showModal', 'false');
  },

  closeModal: function (component) {
    component.set('v.showModal', 'false');
    component.set('v.isRemove', 'false');
  }
});