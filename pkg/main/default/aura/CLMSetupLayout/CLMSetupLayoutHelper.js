({
	insertComponent: function (component, componentName, parameter, isUpdate, body) {
		$A.createComponent(
			componentName,
			parameter,
			function (newComp, status) {
				if (status === 'SUCCESS') {
					if (isUpdate) {
						var compList = component.get(body);
						compList.push(newComp);
						component.set(body, newComp);
					} else {
						component.set(body, newComp);
					}
				}
				else {
					var toast = component.find('toast');
					component.set('v.toastTitle', stringUtils.format($A.get('$Label.c.ComponentCreationFailed'), componentName));
					component.set('v.toastVariantType', 'error');
					toast.show();
				}
			}
		);
	},
	showtoast: function (component, title, variant) {
		var toast = component.find('toast');
		if (toast) {
			component.set('v.toastTitle', title);
			component.set('v.toastVariantType', variant);
			toast.show();
			if (variant === 'success') {
				setTimeout($A.getCallback(function () {
					toast.close();
				}), 3000);
			}
		}
	},
	updateUi: function (component, index) {
		var helper = this;
		if (index === '1') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', true);
			helper.insertComponent(component, 'c:CLMOverview', { login: component.get('v.login') }, false, 'v.main');
		}
		if (index === '2') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', true);
			helper.insertComponent(component, 'c:CLMHomeBody', false, false, 'v.main');
		} else if (index === '3') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', false);
			//header 
			helper.insertComponent(component, 'c:CLMPageHeader', {
				title: $A.get('$Label.c.Integration'),
				iconUrl: 'standard:social',
				sectionTitle: $A.get('$Label.c.CLM')
			}, false, 'v.header');
			//main
			helper.insertComponent(component, 'c:CLMIntegrationLayout', false, false, 'v.main');
		} else if (index === '4') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', false);
			//header 
			helper.insertComponent(component, 'c:CLMPageHeader', {
				title: $A.get('$Label.c.DocumentGeneration'),
				iconUrl: 'standard:contract',
				sectionTitle: $A.get('$Label.c.CLM')
			}, false, 'v.header');
			//main
			helper.insertComponent(
				component,
				'c:CLMDocumentGenerationLayout',
				false,
				false,
				'v.main'
			);
		} else if (index === '5') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', false);
			//header 
			helper.insertComponent(component, 'c:CLMPageHeader', {
				title: $A.get('$Label.c.Workflow'),
				iconUrl: 'standard:campaign',
				sectionTitle: $A.get('$Label.c.CLM')
			}, false, 'v.header');
			//main
			helper.insertComponent(
				component,
				'c:CLMWorkFlowLayout',
				false,
				false,
				'v.main'
			);
		} else if (index === '6') {
			component.set('v.isCenter', false);
			component.set('v.fullLayout', false);
			//header 
			helper.insertComponent(component, 'c:CLMPageHeader', {
				title: $A.get('$Label.c.UserManagement'),
				iconUrl: 'custom:custom66',
				sectionTitle: $A.get('$Label.c.Administration')
			}, false, 'v.header');
			//main
			helper.insertComponent(component, 'c:SetupUsers', {
				products: component.get('v.products'),
				context: 'clm'
			}, false, 'v.main');
		} else if (index === '7') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', false);
			//header 
			helper.insertComponent(component, 'c:CLMPageHeader', {
				title: $A.get('$Label.c.ButtonsAndComponents'),
				iconUrl: 'standard:canvas',
				sectionTitle: $A.get('$Label.c.Administration')
			}, false, 'v.header');
			//main
			helper.insertComponent(
				component,
				'c:CLMComponentsLayout',
				false,
				false,
				'v.main'
			);
		} else if (index === '8') {
			component.set('v.isCenter', true);
			component.set('v.fullLayout', false);
			//header 
			helper.insertComponent(component, 'c:CLMPageHeader', {
				title: $A.get('$Label.c.Help'),
				iconUrl: 'standard:sossession',
				sectionTitle: $A.get('$Label.c.Administration')
			}, false, 'v.header');
			//main
			helper.insertComponent(component, 'c:CLMHelpLayout', false, false, 'v.main');
		}
	}
});