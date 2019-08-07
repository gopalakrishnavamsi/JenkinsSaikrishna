({
  onInit: function (component, event, helper) {
    var SelectedObjDetais = component.get('v.selectedObjDetails');
    if (SelectedObjDetais && SelectedObjDetais.name) {

      helper.callServer(component, 'c.getAllObjectFields', { apiName: SelectedObjDetais.name, isChild: false }, function (result) {
        var allFields = [];
        allFields.push({
          name: SelectedObjDetais.name,
          label: SelectedObjDetais.label,
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
        component.set('v.allObjectFileds', allFields);
        component.set('v.allObjectFiledsList', allFields);
      });

    }
  },
  handleSearchField: function (component) {
    var queryTerm = component.find('search-field').get('v.value');
    var allObjectFileds = JSON.parse(JSON.stringify(component.get('v.allObjectFileds')));
    if (queryTerm.length > 1) {
      allObjectFileds.forEach(function (objFieldData) {
        var filteredList = [];
        objFieldData.fields.forEach(function (filedData) {
          if (filedData.label.toLowerCase().includes(queryTerm.toLowerCase())) {
            filteredList.push(filedData);
          }
        });
        objFieldData.fields = filteredList;

      });
      component.set('v.allObjectFiledsList', allObjectFileds);
    } else {
      component.set('v.allObjectFiledsList', allObjectFileds);
    }
  },
  onObjFolderSelection: function (component, event, helper) {
    var name = event.currentTarget.id;
    var allObjectFiledsList = component.get('v.allObjectFiledsList');

    allObjectFiledsList.forEach(function (folderData, index) {
      if (folderData.name === name) {

        folderData.selected = !folderData.selected;
        if (folderData.fields.length === 0 && folderData.selected === true) {
          helper.callServer(component, 'c.getAllObjectFields', { apiName: folderData.name, isChild: true }, function (result) {
            var allObjectFiledsListtemp = component.get('v.allObjectFiledsList');
            allObjectFiledsListtemp[index].fields = result;
            component.set('v.allObjectFileds', allObjectFiledsListtemp);
            component.set('v.allObjectFiledsList', allObjectFiledsListtemp);
          });
        }
      }

    });
    component.set('v.allObjectFiledsList', allObjectFiledsList);
  },
  onObjFieldSelection: function (component, event, helper) {
    var label = event.currentTarget.id;
    event.stopPropagation();


    var SelectedObjDetais = component.get('v.selectedObjDetails');


    var folderName = component.get('v.folderName');

    if (folderName) {
      folderName += '{!' + SelectedObjDetais.label + '.' + label + '}';
    }
    else {
      folderName = '{!' + SelectedObjDetais.label + '.' + label + '}';
    }

    helper.passModelText(component, folderName, helper);
    component.set('v.folderName', folderName);

  },
  onchangeName: function (component, event, helper) {
    var queryTerm = component.find('search-fileName').get('v.value');
    helper.passModelText(component, queryTerm, helper);



  }
});