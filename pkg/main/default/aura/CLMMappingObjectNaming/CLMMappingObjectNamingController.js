({
	onInit: function (component, event, helper) {
		var SelectedObjDetails = component.get('v.selectedObjDetails');
		if (SelectedObjDetails && SelectedObjDetails.name) {
			helper.callServer(component, 'c.getAllObjectFields', { apiName: SelectedObjDetails.name, isChild: false }, function (result) {
				var allFields = [];
				allFields.push({
					name: SelectedObjDetails.name,
					label: SelectedObjDetails.label,
					relationship: SelectedObjDetails.name,
					selected: true,
					fields: result,
				});
				result.forEach(function (data) {
					if (data.hasRelationship) {
						if (data.label.includes(' ID')) {
							data.label = data.label.replace(/ ID/, '');
						}
						var isDuplicate = false;
						for (var i = 0, j = allFields.length; i < j; i++) {
							if (allFields[i].name === data.relatesTo) {
								isDuplicate = true;
								i = allFields.length;
							}
						}
						if (!isDuplicate) {
							allFields.push({
								name: data.relatesTo,
								label: data.label,
								selected: false,
								relationship: data.name,
								fields: []
							});
						}
					}
				});
				component.set('v.allObjectFields', allFields);
				component.set('v.allObjectFieldsList', allFields);
			});
		}
	},

	handleSearchField: function (component) {
		var queryTerm = component.find('search-field').get('v.value');
		var allObjectFields = JSON.parse(JSON.stringify(component.get('v.allObjectFields')));
		if (queryTerm.length > 1) {
			allObjectFields.forEach(function (objFieldData) {
				var filteredList = [];
				objFieldData.fields.forEach(function (FieldData) {
					if (FieldData.label.toLowerCase().includes(queryTerm.toLowerCase())) {
						filteredList.push(FieldData);
					}
				});
				objFieldData.fields = filteredList;
			});
			component.set('v.allObjectFieldsList', allObjectFields);
		} else {
			component.set('v.allObjectFieldsList', allObjectFields);
		}
	},

	onObjFolderSelection: function (component, event, helper) {
		var name = event.currentTarget.id;
		var allObjectFieldsList = component.get('v.allObjectFieldsList');
		allObjectFieldsList.forEach(function (folderData, index) {
			if (folderData.name === name) {
				folderData.selected = !folderData.selected;
				if (folderData.fields.length === 0 && folderData.selected === true) {
					helper.callServer(component, 'c.getAllObjectFields', { apiName: folderData.name, isChild: true }, function (result) {
						var allObjectFieldsListTemp = component.get('v.allObjectFieldsList');
						allObjectFieldsListTemp[index].fields = result;
						component.set('v.allObjectFields', allObjectFieldsListTemp);
						component.set('v.allObjectFieldsList', allObjectFieldsListTemp);
					});
				}
			}
		});
		component.set('v.allObjectFieldsList', allObjectFieldsList);
	},

	onObjFieldSelection: function (component, event, helper) {
		var selectedFolderName = component.get('v.selectedFolderName');
		var label = event.currentTarget.id;
		var object = event.currentTarget.dataset.obj;
		event.stopPropagation();
		var folderName = component.get('v.folderName');
		var folderNameOrignal = folderName;
		if (folderName) {
			folderName += '{!' + object + '.' + label + '}';
		} else {
			folderName = '{!' + object + '.' + label + '}';
		}
		if (selectedFolderName.includes(folderName)) {
			helper.fireToast(component, 'Field Already Selected ', helper.ERROR);
			component.set('v.folderName', folderNameOrignal);
			return;
		}
		helper.passModelText(component, folderName, helper);
		component.set('v.folderName', folderName);
	},

	onchangeName: function (component, event, helper) {
		var queryTerm = component.find('search-fileName').get('v.value');
		helper.passModelText(component, queryTerm, helper);
	},
});