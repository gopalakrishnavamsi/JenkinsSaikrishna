({
  searchRecords: function (component, searchString) {
    var config = component.get('v.config');
    var commonObjectsfilteredArray = config.commonObjects.filter(function (itm) {
      return itm.label.toLowerCase().includes(searchString.toLowerCase());
    });
    var otherObjectsfilteredArray = config.allOtherObjects.filter(function (itm) {
      return itm.label.toLowerCase().includes(searchString.toLowerCase());
    });
    component.set('v.commonObjectsOption', commonObjectsfilteredArray);
    component.set('v.otherObjectsOption', otherObjectsfilteredArray);
    component.set('v.openDropDown', true);
  },
  loadAllDataSources: function (component) {
    var action = component.get('c.getDataSourceObjects');
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var config = response.getReturnValue();
        component.set('v.config', config);
        component.set('v.commonObjectsOption', config.commonObjects);
        component.set('v.otherObjectsOption', config.allOtherObjects);
        component.set('v.openDropDown', false);
      } else {
        component.set('v.errMsg', stringUtils.getErrorMessage(response));
      }
    });
    $A.enqueueAction(action);
  }
});