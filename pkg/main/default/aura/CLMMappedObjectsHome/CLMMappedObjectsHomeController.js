({
	onInit: function (component, event, helper) {
		var namespace;
		helper.callServer(component, 'c.getNamespace', false, function (result) {
			namespace = result;
		});
		var column = [
			{
				label: $A.get('$Label.c.SalesforceObject'),
				fieldName: 'Name',
				type: 'text',
				sortable: true,
				cellAttributes: { alignment: 'left' }
			},
			{
				label: $A.get('$Label.c.ObjectFolderName'),
				fieldName: (namespace === 'c') ? 'FolderName__c' : 'dfsle__FolderName__c',
				type: 'text',
				sortable: true,
				cellAttributes: { alignment: 'left' }
			},
			{
				label: $A.get('$Label.c.PathInDocuSignCLM'),
				fieldName: (namespace === 'c') ? 'Path__c' : 'dfsle__Path__c',
				type: 'text',
				sortable: true,
				cellAttributes: { alignment: 'left' }
			},
			{
				type: 'button',
				initialWidth: 80,
				typeAttributes: {
					label: $A.get('$Label.c.Edit'),
					name: $A.get('$Label.c.Edit'),
					title: $A.get('$Label.c.Edit'),
					disabled: false,
					value: 'edit'
				}
			},
			{
				type: 'button',
				initialWidth: 100,
				typeAttributes: {
					label: $A.get('$Label.c.Remove'),
					name: $A.get('$Label.c.Remove'),
					title: $A.get('$Label.c.Remove'),
					disabled: false,
					value: 'remove'
				}
			}
		];
		component.set('v.mapColumns', column);
		helper.callServer(component, 'c.getMappedObjectsList', false, function (result) {
			var data = result;
			if (data.Account && data.Opportunity && Object.values(data).length === 2) {
				helper.fireApplicationEvent(component, {
					fromComponent: 'CLMMappedObjectsHome',
					toComponent: 'CLMScopedNotifications',
					type: 'show'
				}, 'CLMEvent');
			}
			component.set('v.mappedObjData', Object.values(result));
		});
		helper.createComponent(component, 'c:CLMModelFooterButton', {
			primaryButtonLabel: $A.get('$Label.c.Remove'),
			secondaryButtonLabel: $A.get('$Label.c.Cancel'),
			primaryButtonVariant: 'destructive'
		}, function (newCmp) {
			component.set('v.strikeModelFooterButtons', newCmp);
		});
	},

	gotoNew: function (component, event, helper) {
		//fire event to update breadcrumb
		helper.fireApplicationEvent(component, {
			navigateTo: { index: '2' },
			fromComponent: 'CLMMappedObjectsHome',
			toComponent: 'CLMBreadcrumbs'
		}, 'CLMBreadcrumbsEvent');
		//fire event to display CLMCardModel
		helper.fireApplicationEvent(component, {
			componentName: 'CLMCardModel',
			fromComponent: 'CLMMappedObjectsHome',
			toComponent: 'CLMIntegrationLayout',
			type: 'show'
		}, 'CLMNavigationEvent');
	},

	removeMappingModalHandler: function (component, event, helper) {
		var data = component.get('v.tempMappingModelDataHolder');
		var modalComponent = component.find('popupModal');
		var mappedObjData = component.get('v.mappedObjData');
		var objDetails;
		mappedObjData.forEach(function (obj) {
			if (obj.Id === data.id) {
				objDetails = obj;
			}
		});
		if (data.type === 'remove') {
			helper.callServer(
				component,
				'c.removeMappedObject',
				{
					name: objDetails.Name
				},
				function () {
					helper.fireApplicationEvent(
						component,
						{
							fromComponent: 'CLMMappedObjectsHome',
							toComponent: 'CLMScopedNotifications',
							type: 'hide'
						},
						'CLMEvent'
					);
					helper.fireToast(
						component,
						stringUtils.format(
							$A.get('$Label.c.ObjectRemoved'),
							objDetails.Name
						),
						helper.SUCCESS
					);
					component.getEvent('CLMScopedNotificationEvent').fire();
					component.set('v.isRemove', 'false');
					var newObjectList = [];
					mappedObjData.forEach(function (obj) {
						if (obj.Id !== data.id) {
							newObjectList.push(obj);
						}
					});
					component.set('v.mappedObjData', newObjectList);
					modalComponent.hide();
				}
			);
		}
		component.set('v.showModal', 'false');
	},

	closeModal: function (component) {
		component.set('v.showModal', 'false');
		component.set('v.isRemove', 'false');
	},

	handleRowAction: function (component, event, helper) {
		var action = event.getParam('action');
		var row = event.getParam('row');
		switch (action.name) {
			case 'Edit':
				helper.edit(component, row, helper);
				break;
			case 'Remove':
				helper.remove(component, row, helper);
				break;
		}
	},

	updateColumnSorting: function (component, event, helper) {
		var fieldName = event.getParam('fieldName');
		var sortDirection = event.getParam('sortDirection');
		component.set('v.sortedBy', fieldName);
		var sortedByColumn = '';
		if (fieldName === 'firstName') {
			sortedByColumn = $A.get('$Label.c.FirstName');
		} else if (fieldName === 'lastName') {
			sortedByColumn = $A.get('$Label.c.LastName');
		} else if (fieldName === 'email') {
			sortedByColumn = $A.get('$Label.c.Email');
		}
		component.set('v.sortedByColumn', sortedByColumn);
		component.set('v.sortedBy', fieldName);
		component.set('v.sortedDirection', sortDirection);
		helper.sortData(component, fieldName, sortDirection);
	}

});