({
  onInit: function (component, event, helper) {
    var loader = component.find('loader');
    loader.show();
    helper.callServer(component, 'c.getMappedObjectsList', false, function (result) {
      component.set('v.mappedObjData', JSON.parse(result));
      loader.hide();
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
  },

  remove: function (component, event) {
    var id = event.getSource().get('v.value');
    component.set('v.tempMappingModelDataHolder', {
      id: id,
      type: 'remove'
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

  editMappingModelHandler: function (component) {
    var data = component.get('v.tempMappingModelDataHolder');
    var modelComponent = component.find('popupModel');
    var toast = component.find('toast');
    var mappedObjData = component.get('v.mappedObjData');
    var objDetails = mappedObjData.filter(function (obj) {
      return (obj.Id === data.id)
    });
    if (data.type === 'remove') {
      component.set('v.toastTitleText', stringUtils.format($A.get('$Label.c.ObjectRemoved'), objDetails[0].objectName));
      component.set('v.toastVariant', 'success');
      toast.show();
      setTimeout($A.getCallback(function () {
        toast.close();
      }), 2000);
      component.set('v.mappedObjData', mappedObjData.filter(function (obj) {
        return (obj.Id !== data.id)
      }));
      modelComponent.hide();
    } else if (data.type === 'edit') {
      component.set('v.toastTitleText', stringUtils.format($A.get('$Label.c.ObjectEditSuccessful'), objDetails[0].objectName));
      component.set('v.toastVariant', 'success');
      toast.show();
      setTimeout($A.getCallback(function () {
        toast.close();
      }), 2000);
      modelComponent.hide();
    }
    component.set('v.showModal', 'false');
  },

  closeModal: function (component) {
    component.set('v.showModal', 'false');
  }
})