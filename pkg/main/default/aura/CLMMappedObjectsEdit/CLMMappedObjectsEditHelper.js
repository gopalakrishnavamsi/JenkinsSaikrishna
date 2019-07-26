({
  UpdateUI: function (component, index) {
    var helper = this;
    var SelectedObjDetais = component.get('v.SelectedObjDetais');
    if (index === '2' && SelectedObjDetais) {
      helper.fireApplicationEvent(component, {
        title: 'Name Object Folder',
        summary: 'Browse for and select a field to name the folder that you have just created',
        index: '2',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '2');
      component.set('v.title', SelectedObjDetais.objectName + ' Folder Name');
      component.set('v.titleHelpText', 'For example:if your object has a name field which contains \'Chicago\' we will create a new \'Chicago\' folder');
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
        title: 'Choose Location',
        summery: 'Allocate an easy-to-find location with DOcuSign CLM for your filder to live.Ther folder path you have create will be indepedent of other mappings',
        index: '3',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '3');
      component.set('v.title', SelectedObjDetais.objectName + ' Folder Location');
      component.set('v.titleHelpText', 'We have Created Folder with following location.');
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '3' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
    } else {
      helper.fireApplicationEvent(component, {
        title: 'Select Object',
        summery: 'Choose the Salesforce object you want to be the source for your documents.You\'ll choose one object at a time',
        index: '1',
        fromComponent: 'CLMMappedObjectEdit',
        toComponent: 'CLMCardModel',
        type: 'update'
      }, 'CLMCardModelEvent');
      component.set('v.currentStep', '1');
      component.set('v.title', 'Your Salesforce Objects');
      component.set('v.titleHelpText', 'We have listed all your standard and custom Salesforce objects below.');
      helper.fireApplicationEvent(component, {
        navigateTo: { index: '1' },
        fromComponent: 'CLMMappedObjectsEdit',
        toComponent: 'CLMPath'
      }, 'CLMPathEvent');
    }
  }
})