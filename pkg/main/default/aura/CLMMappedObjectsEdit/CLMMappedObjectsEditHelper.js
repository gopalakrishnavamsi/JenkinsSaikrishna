({

  sortTree: function (treeData) {
    treeData.sort(function (a, b) {
      return a.level - b.level;
    });
    return treeData;
  },
  updatepath: function (component) {
    var clmFolderTree = component.get('v.clmFolderTree');
    clmFolderTree = this.sortTree(clmFolderTree);
    var path = '';
    clmFolderTree.forEach(function (treeData, index) {
      if (treeData.name && index < clmFolderTree.length - 1) {
        path += treeData.name + '/';
      }
    });
    component.set('v.pathInCLM', path);

  },
  UpdateUI: function (component, index) {
    var helper = this;
    var SelectedObjDetails = component.get('v.SelectedObjDetails');
    var SelectedObjFieldName = component.get('v.SelectedObjFieldName');
    if (index === '2' && SelectedObjDetails) {
      helper.fireApplicationEvent(component, {
        title: $A.get('$Label.c.NameObjectFolder'),
        summary: $A.get('$Label.c.SelectFieldInfo'),
        index: '2',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '2');
      component.set('v.title', SelectedObjDetails.name + ' Folder Name');
      component.set('v.titleHelpText', stringUtils.format($A.get('$Label.c.SelectFolderHelpBody'), SelectedObjDetails.name));
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '2' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
      if (SelectedObjDetails.name) {
        helper.callServer(component, 'c.getAllObjectFields', { apiName: SelectedObjDetails.name, isChild: false }, function (result) {
          var allFields = [];
          allFields.push({
            name: SelectedObjDetails.name,
            label: SelectedObjDetails.label,
            selected: true,
            fields: result,
          });

          result.forEach(function (data) {
            if (data.hasRelationship) {
              allFields.push({
                name: data.relatesTo,
                label: data.label,
                selected: false,
                fields: [],
              });
            }
          });

          component.set('v.allObjectFields', allFields);
          component.set('v.allObjectFieldsList', allFields);
        });
      }
    }
    else if (index === '3' && SelectedObjDetails && SelectedObjFieldName) {


      if (!SelectedObjFieldName || SelectedObjFieldName.length === 0 || $A.util.isEmpty(SelectedObjFieldName)) {
        helper.fireApplicationEvent(component, {
          navigateTo: { index: '2' },
          fromComponent: 'CLMMappedObjectsEdit',
          toComponent: 'CLMPath'
        }, 'CLMPathEvent');
        return;
      }
      helper.fireApplicationEvent(component, {
        title: $A.get('$Label.c.ChooseLocation'),
        summary: $A.get('$Label.c.ChooseLocationInfo'),
        index: '3',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '3');
      component.set('v.title', stringUtils.format('{0} {1}', SelectedObjDetails.name, 'Folder Location'));
      component.set('v.titleHelpText', stringUtils.format($A.get('$Label.c.ChooseLocationTitleHelpText'), SelectedObjDetails.name));
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '3' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
      helper.updatepath(component);
    }
    else {
      helper.fireApplicationEvent(component, {
        title: $A.get('$Label.c.SelectObject'),
        summary: $A.get('$Label.c.SelectObjectHelpBody').concat(' ', $A.get('$Label.c.SelectObjectHelpBody2')),
        index: '1',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '1');
      component.set('v.title', $A.get('$Label.c.YourSalesforceObjects'));
      component.set('v.titleHelpText', $A.get('$Label.c.AllObjectsListed'));
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '1' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
    }
  }
});