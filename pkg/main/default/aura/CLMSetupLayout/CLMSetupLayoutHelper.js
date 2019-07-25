({
    insertComponent: function(component, componentName, parameter, isUpdate, body) {
        $A.createComponent(
            componentName,
            parameter,
            function(newComp, status, errorMessage) {
                if (status === 'SUCCESS') {
                    if (isUpdate) {
                        var compList = component.get(body);
                        compList.push(newComp);
                        component.set(body, newComp);
                    } else {
                        component.set(body, newComp);
                    }
                } 
                else if (status === 'ERROR') {
                    console.log('cannot create ',componentName)                          
                }
            }
        );
    },
    updateUi: function(component, index) {
        var helper = this;
        if (index === '1') {
            component.set('v.fullLayout', true);
            helper.insertComponent(component, 'c:CLMOverview', false, false, 'v.main');
        }
        if (index === '2') {
            component.set('v.fullLayout', true);
            helper.insertComponent(component, 'c:CLMHomeBody', false, false, 'v.main');
        } else if (index === '3') {
            component.set('v.fullLayout', false);
            //header 
            helper.insertComponent(component, 'c:CLMPageHeader', {
                title: $A.get("$Label.c.Integration"),
                iconUrl: 'standard:social'
            }, false, 'v.header');
            //main
            helper.insertComponent(component, 'c:CLMIntegrationLayout', false, false, 'v.main');
        } else if (index === '4') {
            component.set('v.fullLayout', false);
            //header 
            helper.insertComponent(component, 'c:CLMPageHeader', {
                title: $A.get("$Label.c.DocumentGeneration"),
                iconUrl: 'custom:custom66'
            }, false, 'v.header');
            //main
            component.set('v.main', '');
        } else if (index === '5') {
            component.set('v.fullLayout', false);
            //header 
            helper.insertComponent(component, 'c:CLMPageHeader', {
                title: $A.get("$Label.c.Workflow"),
                iconUrl: 'custom:custom66'
            }, false, 'v.header');
            //main
            component.set('v.main', '');
        } else if (index === '6') {
            component.set('v.fullLayout', false);
            //header 
            helper.insertComponent(component, 'c:CLMPageHeader', {
                title: $A.get("$Label.c.UserManagement"),
                iconUrl: 'custom:custom66'
            }, false, 'v.header');
            //main
            component.set('v.main', '');
        } else if (index === '7') {
            component.set('v.fullLayout', false);
            //header 
            helper.insertComponent(component, 'c:CLMPageHeader', {
                title: $A.get("$Label.c.ButtonsAndComponents"),
                iconUrl: 'custom:custom66'
            }, false, 'v.header');
            //main
            component.set('v.main', '');
        } else if (index === '8') {
            component.set('v.fullLayout', false);
            //header 
            helper.insertComponent(component, 'c:CLMPageHeader', {
                title: $A.get("$Label.c.Help"),
                iconUrl: 'custom:custom66'
            }, false, 'v.header');
            //main
            component.set('v.main', '');
        }
        
    }
})