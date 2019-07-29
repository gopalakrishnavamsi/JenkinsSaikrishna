({
  insertComponent: function (component, componentName, parameter) {
    $A.createComponent(
      componentName,
      parameter,
      function (newComp, status) {
        if (status === 'SUCCESS') {
          component.set('v.editComponent', newComp);
        }
      }
    );
  },

  setBreadcrumbDefaultValues: function (component) {
    var defaultBreadcrumbValues = [
      { 'label': $A.get('$Label.c.MapYourSalesforceObjects'), navigateTo: 'CLMMappedObjectsHome', type: 'component', 'index': '1' },
      { 'label': $A.get('$Label.c.MapNew'), navigateTo: '', type: 'component', 'index': '2' }
    ];
    component.set('v.breadCrumbValues', defaultBreadcrumbValues);
  },
  
  setPathDefaultValues: function (component) {
    var defaultPathValues = [
      { 'label': $A.get('$Label.c.SelectObject'), 'index': '1' },
      { 'label': $A.get('$Label.c.NameObjectFolder'), 'index': '2' },
      { 'label': $A.get('$Label.c.ChooseLocation'), 'index': '3' },
    ];
    component.set('v.pathValues', defaultPathValues);
  }
})