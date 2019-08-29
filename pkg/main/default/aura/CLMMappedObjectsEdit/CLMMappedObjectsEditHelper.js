({
	//tree helper
	sortTree: function (treeData) {
		treeData.sort(function (a, b) {
			return a.level - b.level;
		});
		return treeData;
	},

	updatePath: function (component) {
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

	addSObjectToTree: function (component, label) {
		var clmFolderTree = component.get('v.clmFolderTree');
		var objectIndex = 0;
		clmFolderTree.forEach(function (treeData, index) {
			if (treeData.type === 'sObject') {
				objectIndex = index;
			}
		});
		if (objectIndex) {
			clmFolderTree[objectIndex].name = label;
		} else {
			clmFolderTree = this.sortTree(clmFolderTree);
			clmFolderTree.forEach(function (treeData, index) {
				if (index >= 2 && treeData.level >= 3) {
					treeData.level = treeData.level + 1;
					treeData.id = treeData.id + 1;
				}
			});
			clmFolderTree.push({
				level: 3,
				name: label,
				type: 'sObject',
				selected: false,
				id: 3
			});
			clmFolderTree = this.sortTree(clmFolderTree);
		}
		return clmFolderTree;
	},

	addTailFolderToTree: function (component, field) {
		var clmFolderTree = component.get('v.clmFolderTree');
		var fieldIndex = 0;
		clmFolderTree.forEach(function (treeData, index) {
			if (treeData.type === 'tail') {
				fieldIndex = index;
			}
		});
		if (fieldIndex) {
			clmFolderTree[fieldIndex].name = field;
		} else {
			clmFolderTree.push({
				level: 4,
				name: field,
				type: 'tail',
				selected: false,
				id: 4
			});
		}
		return clmFolderTree;
	},

	//ui helper
	UpdateUI: function (component, index) {
		var helper = this;
		var SelectedObjDetails = component.get('v.SelectedObjDetails');
		var SelectedObjFieldName = component.get('v.SelectedObjFieldName');
		if (index === '2' && SelectedObjDetails) {
			helper.fireApplicationEvent(
				component,
				{
					title: $A.get('$Label.c.NameObjectFolder'),
					summary: $A.get('$Label.c.SelectFieldInfo'),
					index: '2',
					fromComponent: 'CLMMappedObjectEdit',
					toComponent: 'CLMCardModel',
					type: 'update'
				},
				'CLMCardModelEvent'
			);
			component.set('v.currentStep', '2');
			component.set(
				'v.title',
				stringUtils.format('{0} {1}',
					SelectedObjDetails.label,
					$A.get('$Label.c.FolderName')
				)
			);
			component.set(
				'v.titleHelpText',
				stringUtils.format(
					$A.get('$Label.c.SelectFolderHelpBody'),
					SelectedObjDetails.label
				)
			);
			helper.fireApplicationEvent(
				component,
				{
					navigateTo: { index: '2' },
					fromComponent: 'CLMMappedObjectsEdit',
					toComponent: 'CLMPath'
				},
				'CLMPathEvent'
			);
			if (SelectedObjDetails.name) {
				helper.showLoader(component);
				helper.callServer(
					component,
					'c.getAllObjectFields',
					{ apiName: SelectedObjDetails.name, isChild: false },
					function (result) {
						var allFields = [];
						allFields.push({
							name: SelectedObjDetails.name,
							label: SelectedObjDetails.label,
							selected: true,
							fields: result
						});
						result.forEach(function (data) {
							if (data.hasRelationship) {
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
										fields: []
									});
								}
							}
						});

						component.set('v.allObjectFields', allFields);
						component.set('v.allObjectFieldsList', allFields);
						helper.hideLoader(component);
					}
				);
			}
		} else if (index === '3' && SelectedObjDetails && SelectedObjFieldName) {
			if (
				!SelectedObjFieldName ||
				SelectedObjFieldName.length === 0 ||
				$A.util.isEmpty(SelectedObjFieldName)
			) {
				helper.fireApplicationEvent(
					component,
					{
						navigateTo: { index: '2' },
						fromComponent: 'CLMMappedObjectsEdit',
						toComponent: 'CLMPath'
					},
					'CLMPathEvent'
				);
				return;
			}
			helper.fireApplicationEvent(
				component,
				{
					title: $A.get('$Label.c.ChooseLocation'),
					summary: $A.get('$Label.c.ChooseLocationInfo'),
					index: '3',
					fromComponent: 'CLMMappedObjectEdit',
					toComponent: 'CLMCardModel',
					type: 'update'
				},
				'CLMCardModelEvent'
			);
			component.set('v.currentStep', '3');
			component.set(
				'v.title',
				stringUtils.format(
					'{0} {1}',
					SelectedObjDetails.label,
					$A.get('$Label.c.FolderLocation')
				)
			);
			component.set(
				'v.titleHelpText',
				stringUtils.format(
					$A.get('$Label.c.ChooseLocationTitleHelpText'),
					SelectedObjDetails.label
				)
			);
			helper.fireApplicationEvent(
				component,
				{
					navigateTo: { index: '3' },
					fromComponent: 'CLMMappedObjectsEdit',
					toComponent: 'CLMPath'
				},
				'CLMPathEvent'
			);
			helper.updatePath(component);
		} else {
			helper.fireApplicationEvent(
				component,
				{
					title: $A.get('$Label.c.SelectObject'),
					summary: $A
						.get('$Label.c.SelectObjectHelpBody')
						.concat(' ', $A.get('$Label.c.SelectObjectHelpBody2')),
					index: '1',
					fromComponent: 'CLMMappedObjectEdit',
					toComponent: 'CLMCardModel',
					type: 'update'
				},
				'CLMCardModelEvent'
			);
			component.set('v.currentStep', '1');
			component.set('v.title', $A.get('$Label.c.YourSalesforceObjects'));
			component.set('v.titleHelpText', $A.get('$Label.c.AllObjectsListed'));
			helper.fireApplicationEvent(
				component,
				{
					navigateTo: { index: '1' },
					fromComponent: 'CLMMappedObjectsEdit',
					toComponent: 'CLMPath'
				},
				'CLMPathEvent'
			);
		}
	},

	showLoader: function (component) {
		component.set('v.loader', true);
	},

	hideLoader: function (component) {
		component.set('v.loader', false);
	}
});
