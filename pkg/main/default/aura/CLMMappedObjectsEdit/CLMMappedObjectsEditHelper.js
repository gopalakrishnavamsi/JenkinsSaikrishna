({
  UpdateUI: function (component, index) {
    var helper = this;
    var SelectedObjDetais = component.get('v.SelectedObjDetais');
    if (index === '2' && SelectedObjDetais) {
      helper.fireApplicationEvent(component, {
        title: $A.get('$Label.c.NameObjectFolder'),
        summary: $A.get('$Label.c.SelectFieldInfo'),
        index: '2',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '2');
      component.set('v.title', SelectedObjDetais.objectName + ' Folder Name');
      component.set('v.titleHelpText', $A.get('$Label.c.SelectFolderHelpBody'));
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '2' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
      helper.callServer(component, 'c.getAllObjectFileds', { objApiName: SelectedObjDetais.objecApiName }, function (result) {
        component.set('v.SelectedObjFieldName', '{!' + SelectedObjDetais.objectName + '.Id}');
        component.set('v.allObjectFileds', result);
        component.set('v.allObjectFiledsList', result);
      });
    } else if (index === '3' && SelectedObjDetais) {
      if (component.get('v.SelectedFiledsDetails').length === 0) {
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
      component.set('v.title', stringUtils.format('{0} {1}', SelectedObjDetais.objectName, 'Folder Location'));
        component.set('v.titleHelpText', stringUtils.format($A.get('$Label.c.ChooseLocationTitleHelpText'), SelectedObjDetais.objectName));
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '3' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
    } else {
      helper.fireApplicationEvent(component, {
        title: $A.get('$Label.c.SelectObject'),
        summary: $A.get('$Label.c.SelectObjectHelpBody'),
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
})