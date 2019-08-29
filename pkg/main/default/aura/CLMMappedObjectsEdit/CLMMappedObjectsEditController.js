({
	onInit: function (component, event, helper) {
		helper.showLoader(component);
		component.set('v.clmFolderTree', [
			{
				level: 1,
				name: 'Other Sources',
				type: 'root',
				selected: false,
				id: 1,
			},
			{
				level: 2,
				name: 'Salesforce',
				type: 'parent',
				selected: false,
				id: 2
			}
		]);
		var selectedObjDetails = component.get('v.SelectedObjDetails');
		helper.callServer(component, 'c.getAllObjects', false, function (result) {
			result.forEach(function (data) {
				if (selectedObjDetails && selectedObjDetails.Name === data.name) {
					selectedObjDetails.label = data.label;
					selectedObjDetails.name = data.name;
					selectedObjDetails.selected = true;
					data.selected = true;
				}
				else {
					data.selected = false;
				}
			});
			component.set('v.allObjects', result);
			component.set('v.allObjectsList', result);
			if (selectedObjDetails && selectedObjDetails.Id) {
				component.set('v.SelectedObjDetails', selectedObjDetails);
				var path = '', folderName = '';
				if (component.get('v.namespace') === 'c') {
					folderName = selectedObjDetails.FolderName__c;
					component.set('v.SelectedObjFieldName', folderName);
					path = selectedObjDetails.Path__c.split('/');
				}
				else {
					folderName = selectedObjDetails[component.get('v.namespace') + '__FolderName__c'];
					path = selectedObjDetails[component.get('v.namespace') + '__Path__c'].split('/');
					component.set('v.SelectedObjFieldName', folderName);
				}
				var clmTree = [];
				path.forEach(function (pathValue, pathIndex) {
					if (pathValue) {
						if (pathIndex === 0) {
							clmTree.push({
								level: 1,
								name: 'Other Sources',
								type: 'root',
								selected: false,
								id: 1,
							});
						}
						else if (pathIndex === 1) {
							clmTree.push({
								level: 2,
								name: pathValue,
								type: 'parent',
								selected: false,
								id: 2
							});
						}
						else if (pathValue === selectedObjDetails.name) {
							clmTree.push({
								level: pathIndex + 1,
								name: pathValue,
								type: 'sObject',
								selected: false,
								id: pathIndex + 1
							});
						}
						else {
							clmTree.push({
								level: pathIndex + 1,
								name: pathValue,
								type: 'folder',
								selected: false,
								id: pathIndex + 1
							});
						}
					}
				});
				clmTree.push({
					level: clmTree.length + 1,
					name: folderName,
					type: 'tail',
					selected: false,
					id: clmTree.length + 1
				});
				component.set('v.clmFolderTree', clmTree);
				helper.updatePath(component);
				helper.UpdateUI(component, '2');
			}
			helper.hideLoader(component);
		});
		helper.createComponent(component, 'c:CLMModelFooterButton', {
			primaryButtonLabel: $A.get('$Label.c.Confirm'),
			secondaryButtonLabel: $A.get('$Label.c.Cancel'),
			primaryButtonVariant: 'brand',
			primaryButtonDisabled: 'true'
		}, function (newCmp) {
			component.set('v.strikeModelFooterButtons', newCmp);
		});
		helper.createComponent(component, 'c:CLMMappingObjectNaming', {
			title: $A.get('$Label.c.NameLabel'),
			summary: $A.get('$Label.c.NameLabel'),
		}, function (newCmp) {
			component.set('v.modalBody', newCmp);
		});
	},

	back: function (component, event, helper) {
		var currentStep = component.get('v.currentStep');
		if (currentStep === '3') {
			helper.UpdateUI(component, '2');
		} else if (currentStep === '2') {
			helper.UpdateUI(component, '1');
		} else if (currentStep === '1') {
			helper.fireApplicationEvent(component, {
				navigateTo: { index: '1' },
				fromComponent: 'CLMMappedObjectsEdit',
				toComponent: 'CLMBreadcrumbs'
			}, 'CLMBreadcrumbsEvent');
			helper.fireApplicationEvent(component, {
				componentName: 'CLMMappedObjectsHome',
				fromComponent: 'CLMMappedObjectsEdit',
				toComponent: 'CLMIntegrationLayout',
				type: 'show'
			}, 'CLMNavigationEvent');
		}
	},

	gotNextStep: function (component, event, helper) {
		var currentStep = component.get('v.currentStep');
		if (currentStep === '1') {
			helper.UpdateUI(component, '2');
		} else if (currentStep === '2') {
			helper.UpdateUI(component, '3');
		}
	},

	openSeeExample: function (component, event, helper) {
		helper.createComponent(component, 'c:CLMModelFooterButton', {
			showPrimaryButton: 'false',
			secondaryButtonVariant: 'brand',
			secondaryButtonLabel: 'Close'
		}, function (newCmp) {
			component.set('v.strikeModelFooterButtons', newCmp);
		});
		helper.createComponent(component, 'c:CLMFolderExample', {}, function (newCmp) {
			component.set('v.modalBody', newCmp);
			component.set('v.modelTitleText', $A.get('$Label.c.FolderExample'));
			component.set('v.showModal', 'true');
			var modelComponent = component.find('popupModel');
			setTimeout($A.getCallback(function () {
				modelComponent.show();
			}), 5);
		});
	},

	openWhyExample: function (component, event, helper) {
		helper.createComponent(component, 'c:CLMModelFooterButton', {
			showPrimaryButton: 'false',
			secondaryButtonVariant: 'brand',
			secondaryButtonLabel: $A.get('$Label.c.Close')
		}, function (newCmp) {
			component.set('v.strikeModelFooterButtons', newCmp);
		});
		helper.createComponent(component, 'c:CLMSelectingFields', {}, function (newCmp) {
			component.set('v.modalBody', newCmp);
			component.set('v.modelTitleText', $A.get('$Label.c.WhyAmISelectingFields'));
			component.set('v.showModal', 'true');
			var modelComponent = component.find('popupModel');
			setTimeout($A.getCallback(function () {
				modelComponent.show();
			}), 5);
		});
	},

	insertPath: function (component, event, helper) {
		var selectedObjDetails = component.get('v.SelectedObjDetails');
		var SelectedObjFieldName = component.get('v.SelectedObjFieldName');
		selectedObjDetails.Name = selectedObjDetails.name;
		if (component.get('v.namespace') === 'c') {
			selectedObjDetails.FolderName__c = SelectedObjFieldName;
			selectedObjDetails.Path__c = component.get('v.pathInCLM');
		}
		else {
			selectedObjDetails[component.get('v.namespace') + '__FolderName__c'] = SelectedObjFieldName;
			selectedObjDetails[component.get('v.namespace') + '__Path__c'] = component.get('v.pathInCLM');
		}
		delete selectedObjDetails.name;
		delete selectedObjDetails.label;
		delete selectedObjDetails.selected;
		helper.callServer(component, 'c.setMappedObject', { eosDetails: selectedObjDetails }, function (result) {
			if (result) {
				var toastTitle = $A.get('$Label.c.MappingSuccess');
				if (selectedObjDetails.Id) {
					toastTitle = $A.get('$Label.c.ObjectEditSuccessful');
				}
				helper.fireToast(component, stringUtils.format(toastTitle, selectedObjDetails.label), helper.SUCCESS);
				helper.fireApplicationEvent(component, {
					fromComponent: 'CLMMappedObjectsEdit',
					toComponent: 'CLMSetupLayout',
					type: 'update',
					tabIndex: '3',
				}, 'CLMNavigationEvent');
			}
			else {
				helper.fireToast(component, stringUtils.format($A.get('$Label.c.MapError'), selectedObjDetails.label), 'error');
			}
		});
	},

	//Step 1
	handleSearchObject: function (component) {
		var queryTerm = component.find('search-object').get('v.value');
		var allObjs = component.get('v.allObjects');
		if (queryTerm.length > 1) {
			var filteredObjs = [];
			allObjs.forEach(function (obj) {
				if (obj.name.toLowerCase().includes(queryTerm.toLowerCase())) {
					filteredObjs.push(obj);
				}
			});
			component.set('v.allObjectsList', filteredObjs);
		} else {
			component.set('v.allObjectsList', allObjs);
		}
	},

	onObjSelection: function (component, event, helper) {
		var name = event.currentTarget.id;
		var allObjects = component.get('v.allObjects');
		var allObjectsList = component.get('v.allObjectsList');
		var selectedObjDetails = component.get('v.SelectedObjDetails');
		if (!selectedObjDetails) {
			selectedObjDetails = {};
		}
		allObjects.forEach(function (data) {
			if (data.name === name) {
				data.selected = true;
				selectedObjDetails.label = data.label;
				selectedObjDetails.name = data.name;
				selectedObjDetails.selected = true;
			} else {
				data.selected = false;
			}
		});
		allObjectsList.forEach(function (data) {
			if (data.name === name) {
				data.selected = true;
			} else {
				data.selected = false;
			}
		});
		component.set('v.clmFolderTree', helper.addSObjectToTree(component, selectedObjDetails.label));
		component.set('v.SelectedObjDetails', selectedObjDetails);
		component.set('v.allObjects', allObjects);
		component.set('v.allObjectsList', allObjectsList);
	},

	//Step 2
	onObjFolderSelection: function (component, event, helper) {
		var name = event.currentTarget.id;
		var allObjectFieldsList = component.get('v.allObjectFieldsList');
		allObjectFieldsList.forEach(function (folderData, index) {
			if (folderData.name === name) {
				folderData.selected = !folderData.selected;
				if (folderData.fields.length === 0 && folderData.selected === true) {
					helper.showLoader(component);
					helper.callServer(component, 'c.getAllObjectFields', { apiName: folderData.name, isChild: true }, function (result) {
						var allObjectFieldsListTemp = component.get('v.allObjectFieldsList');
						allObjectFieldsListTemp[index].fields = result;
						component.set('v.allObjectFields', allObjectFieldsListTemp);
						component.set('v.allObjectFieldsList', allObjectFieldsListTemp);
						helper.hideLoader(component);
					});
				}
			}
		});
		component.set('v.allObjectFieldsList', allObjectFieldsList);
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

	onObjFieldSelection: function (component, event, helper) {
		var label = event.currentTarget.id;
		event.stopPropagation();
		var SelectedObjDetails = component.get('v.SelectedObjDetails');
		var SelectedObjFieldName = component.get('v.SelectedObjFieldName');
		if (SelectedObjFieldName) {
			SelectedObjFieldName += '{!' + SelectedObjDetails.label + '.' + label + '}';
		}
		else {
			SelectedObjFieldName = '{!' + SelectedObjDetails.label + '.' + label + '}';
		}
		component.set('v.clmFolderTree', helper.addTailFolderToTree(component, SelectedObjFieldName));
		component.set('v.SelectedObjFieldName', SelectedObjFieldName);
	},

	validateFieldSelection: function (component, event, helper) {
		var value = event.getSource().get('v.value');
		if (!value) {
			component.set('v.SelectedObjFieldName', '');
		}
		else {
			component.set('v.SelectedObjFieldName', value);
		}
		component.set('v.clmFolderTree', helper.addTailFolderToTree(component, value));
	},

	//Step 3
	onCLMFolderSelection: function (component, event) {
		var dataset = JSON.parse(JSON.stringify(event.currentTarget.dataset));
		var clmFolderTree = component.get('v.clmFolderTree');
		var index = parseInt(dataset.id);
		clmFolderTree.forEach(function (treeData, treeIndex) {
			if (treeData.id === index) {
				treeData.selected = true;
				if (treeData.type === 'root') {
					component.set('v.isDeleteFolder', true);
					component.set('v.isAddSubFolder', false);
					component.set('v.isRenameFolder', true);
				}
				else if (treeData.type === 'tail') {
					component.set('v.isDeleteFolder', true);
					component.set('v.isAddSubFolder', true);
					component.set('v.isRenameFolder', true);
				}
				else {
					component.set('v.isDeleteFolder', false);
					component.set('v.isAddSubFolder', false);
					component.set('v.isRenameFolder', false);
				}

				if (treeIndex + 1 <= clmFolderTree.length - 1) {
					component.set('v.SelectedFolderParentExample', clmFolderTree[treeIndex].name);
					component.set('v.SelectedFolderExample', clmFolderTree[treeIndex + 1].name);
				}
			}
			else {
				treeData.selected = false;
			}
		});
		component.set('v.clmFolderTree', clmFolderTree);
	},

	addSubFolder: function (component, event, helper) {
		var clmFolderTree = component.get('v.clmFolderTree');
		var selectedFolder;
		var selectedFolderIndex;
		clmFolderTree.forEach(function (treeData, treeIndex) {
			if (treeData.selected) {
				selectedFolder = treeData;
				selectedFolderIndex = treeIndex;
			}
		});
		helper.createComponent(component, 'c:CLMModelFooterButton', {
			primaryButtonLabel: $A.get('$Label.c.Confirm'),
			secondaryButtonLabel: $A.get('$Label.c.Cancel'),
			primaryButtonVariant: 'brand',
			primaryButtonDisabled: 'true'
		}, function (newCmp) {
			component.set('v.strikeModelFooterButtons', newCmp);
		});
		helper.createComponent(component, 'c:CLMMappingObjectNaming', {
			title: $A.get('$Label.c.NameYourSubFolder'),
			summary: $A.get('$Label.c.NameSubFolderSummary'),
			selectedObjDetails: component.get('v.SelectedObjDetails'),
			buttonDisabled: true
		}, function (newCmp) {
			component.set('v.modalBody', newCmp);
		});
		component.set('v.modelTitleText', $A.get('$Label.c.NameSubFolder'));
		component.set('v.showModal', 'true');
		component.set('v.modelValueHolder', {
			buttonType: 'subFolder',
			selectedFolder: selectedFolder,
			selectedFolderIndex: selectedFolderIndex,
			buttonDisabled: true
		});
		var modelComponent = component.find('popupModel');
		setTimeout($A.getCallback(function () {
			modelComponent.show();
		}), 5);
	},

	renameSubFolder: function (component, event, helper) {
		var clmFolderTree = component.get('v.clmFolderTree');
		var selectedFolder;
		var selectedFolderIndex;
		clmFolderTree.forEach(function (treeData, treeIndex) {
			if (treeData.selected) {
				selectedFolder = treeData;
				selectedFolderIndex = treeIndex;
			}
		});
		helper.createComponent(component, 'c:CLMModelFooterButton', {
			primaryButtonLabel: $A.get('$Label.c.Confirm'),
			secondaryButtonLabel: $A.get('$Label.c.Cancel'),
			primaryButtonVariant: 'brand',
			primaryButtonDisabled: 'false'
		}, function (newCmp) {
			component.set('v.strikeModelFooterButtons', newCmp);
		});
		var selectedObjDetails = component.get('v.SelectedObjDetails');
		helper.createComponent(component, 'c:CLMMappingObjectNaming', {
			title: $A.get('$Label.c.NameYourFolder'),
			summary: $A.get('$Label.c.NameSubFolderSummary'),
			folderName: selectedFolder.name,
			selectedObjDetails: selectedObjDetails,
			buttonDisabled: false
		}, function (newCmp) {
			component.set('v.modalBody', newCmp);
		});
		component.set('v.modelTitleText', $A.get('$Label.c.RenameFolder'));
		component.set('v.showModal', 'true');
		component.set('v.modelValueHolder', {
			buttonType: 'rename',
			selectedFolder: selectedFolder,
			selectedFolderIndex: selectedFolderIndex,
			buttonDisabled: false
		});
		var modelComponent = component.find('popupModel');
		setTimeout($A.getCallback(function () {
			modelComponent.show();
		}), 5);
	},

	deleteSubFolder: function (component, event, helper) {
		var clmFolderTree = component.get('v.clmFolderTree');
		for (var i = 0; i < clmFolderTree.length; i++) {
			if (clmFolderTree[i].selected) {
				clmFolderTree.splice(i, 1);
			}
		}
		clmFolderTree.forEach(function (treeData, index) {
			treeData.level = index + 1;
			treeData.id = treeData.level;
		});
		component.set('v.clmFolderTree', clmFolderTree);
		component.set('v.isDeleteFolder', false);
		component.set('v.isAddSubFolder', false);
		component.set('v.isRenameFolder', false);
		helper.updatePath(component);
	},

	//Handlers
	updateTextFromModel: function (component, event) {
		var fromComponent = event.getParam('fromComponent');
		var toComponent = event.getParam('toComponent');
		var type = event.getParam('type');
		var data = event.getParam('data');
		if (toComponent === 'CLMMappedObjectEdit' && fromComponent !== 'CLMMappedObjectEdit') {
			if (type === 'update') {
				var modelValueHolder = component.get('v.modelValueHolder');
				modelValueHolder.folderName = data.value;
				component.set('v.modelValueHolder', modelValueHolder);
			}
		}
	},

	updateFromPathUI: function (component, event, helper) {
		var navigateTo = event.getParam('navigateTo');
		var fromComponent = event.getParam('fromComponent');
		var toComponent = event.getParam('toComponent');
		if ((toComponent === 'CLMCardModel' || toComponent === 'ANY') && fromComponent !== 'CLMCardModel') {
			if (navigateTo !== undefined) {
				helper.UpdateUI(component, navigateTo.index);
			}
		}
	},

	handleConfirm: function (component, event, helper) {
		var modelValueHolder = component.get('v.modelValueHolder');
		var clmFolderTree = component.get('v.clmFolderTree');
		if (modelValueHolder.buttonType === 'rename') {
			clmFolderTree[modelValueHolder.selectedFolderIndex].name = modelValueHolder.folderName;
			component.set('v.clmFolderTree', clmFolderTree);
			component.set('v.showModal', 'false');
			helper.updatePath(component);
		}
		else if (modelValueHolder.buttonType === 'subFolder') {
			clmFolderTree = helper.sortTree(clmFolderTree);

			clmFolderTree.forEach(function (treeData) {
				if (treeData.level > clmFolderTree[modelValueHolder.selectedFolderIndex].level) {
					treeData.level = treeData.level + 1;
					treeData.id = treeData.level + 1;
				}
				else {
					treeData.id = treeData.level;
				}
			});
			clmFolderTree.push({
				level: clmFolderTree[modelValueHolder.selectedFolderIndex].level + 1,
				name: modelValueHolder.folderName,
				type: 'folder',
				selected: false,
				id: clmFolderTree[modelValueHolder.selectedFolderIndex].level + 1
			});
			clmFolderTree = helper.sortTree(clmFolderTree);
			component.set('v.clmFolderTree', clmFolderTree);
			component.set('v.showModal', 'false');
			helper.updatePath(component);
		}
	},

	closeModal: function (component) {
		component.set('v.showModal', 'false');
		component.set('v.modelValueHolder', {});
	}
});