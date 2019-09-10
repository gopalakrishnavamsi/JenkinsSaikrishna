({
	sortData: function (component, fieldName, sortDirection) {
		var data = component.get('v.mappedObjData');
		var reverse = sortDirection !== 'asc';
		data.sort(this.sortBy(fieldName, reverse));
		component.set('v.mappedObjData', data);
	},

	sortBy: function (field, reverse, primer) {
		var key = primer
			? function (x) {
				return primer(x[field]);
			}
			: function (x) {
				return x[field];
			};
		reverse = !reverse ? 1 : -1;
		return function (a, b) {
			return (a = key(a)), (b = key(b)), reverse * ((a > b) - (b > a));
		};
	},

	edit: function (component, row, helper) {
		var id = row.Id;
		var mappedObjData = component.get('v.mappedObjData');
		var objDetails;
		mappedObjData.forEach(function (obj) {
			if (obj.Id === id) {
				objDetails = obj;
			}
		});
		helper.fireApplicationEvent(
			component,
			{
				data: { objDetails: objDetails },
				componentName: 'CLMCardModel',
				fromComponent: 'CLMMappedObjectsHome',
				toComponent: 'CLMIntegrationLayout',
				type: 'edit'
			},
			'CLMNavigationEvent'
		);
		var cmpEvent = component.getEvent('CLMScopedNotificationEvent');
		cmpEvent.fire();
	},

	remove: function (component, row, helper) {
		var id = row.Id;
		component.set('v.tempMappingModelDataHolder', {
			id: id,
			type: 'remove'
		});
		helper.createComponent(
			component,
			'c:CLMModelFooterButton',
			{
				primaryButtonLabel: $A.get('$Label.c.Remove'),
				secondaryButtonLabel: $A.get('$Label.c.Cancel'),
				primaryButtonVariant: 'destructive'
			},
			function (newCmp) {
				component.set('v.strikeModelFooterButtons', newCmp);
				component.set('v.isRemove', 'true');
			}
		);
		var modalTitle = $A.get('$Label.c.RemoveMapping');
		var modalBody = $A.get('$Label.c.RemoveModalBody');
		component.set('v.modalTitleText', modalTitle);
		component.set('v.modalBodyText', modalBody);
		component.set('v.modalPrimaryButtonText', 'Remove');
		component.set('v.modalSecondaryButtonText', 'Cancel');
		component.set('v.showModal', 'true');
		var modelComponent = component.find('popupModal');
		setTimeout(
			$A.getCallback(function () {
				modelComponent.show();
			}),
			5
		);
	}
});