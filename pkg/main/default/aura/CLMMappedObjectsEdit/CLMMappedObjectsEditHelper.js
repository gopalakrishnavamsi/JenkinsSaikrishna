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
		var path = '/';
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
				level: 2,
				name: label,
				type: 'sObject',
				selected: false,
				id: 2
			});
			clmFolderTree = this.sortTree(clmFolderTree);
		}
		return clmFolderTree;
	},

	addLeafFolderToTree: function (component, field) {
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
				level: 3,
				name: field,
				type: 'tail',
				selected: false,
				id: 3
			});
		}
		return clmFolderTree;
	},

	//ui helper
	UpdateUI: function (component, index) {
		var helper = this;
		var selectedObjDetails = component.get('v.selectedObjDetails');
		var selectedObjFieldName = component.get('v.selectedObjFieldName');
		if (index === '2' && selectedObjDetails) {
			component.set('v.cardtitle', $A.get('$Label.c.NameObjectFolder'));
			component.set('v.cardSummary', $A.get('$Label.c.SelectFieldInfo'));
			component.set('v.currentStep', '2');
			component.set(
				'v.title',
				stringUtils.format(
					'{0} {1}',
					selectedObjDetails.label,
					$A.get('$Label.c.FolderName')
				)
			);
			component.set(
				'v.titleHelpText',
				stringUtils.format(
					$A.get('$Label.c.SelectFolderHelpBody'),
					selectedObjDetails.label
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
			if (selectedObjDetails.name) {
				helper.showLoader(component);
				helper.callServer(
					component,
					'c.getAllObjectFields',
					{ apiName: selectedObjDetails.name, isChild: false },
					function (result) {
						var allFields = [];
						allFields.push({
							name: selectedObjDetails.name,
							label: selectedObjDetails.label,
							selected: true,
							fields: result
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
										relationship: data.name,
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
		} else if (index === '3' && selectedObjDetails && selectedObjFieldName) {
			if ($A.util.isEmpty(selectedObjFieldName)) {
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
			component.set('v.cardtitle', $A.get('$Label.c.ChooseLocation'));
			component.set('v.cardSummary', $A.get('$Label.c.ChooseLocationInfo'));
			component.set('v.currentStep', '3');
			component.set(
				'v.title',
				stringUtils.format(
					'{0} {1}',
					selectedObjDetails.label,
					$A.get('$Label.c.FolderLocation')
				)
			);
			component.set(
				'v.titleHelpText',
				stringUtils.format(
					$A.get('$Label.c.ChooseLocationTitleHelpText'),
					selectedObjDetails.label
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
			component.set('v.cardtitle', $A.get('$Label.c.SelectObject'));
			component.set('v.cardSummary', $A.get('$Label.c.SelectObjectHelpBody'));
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
