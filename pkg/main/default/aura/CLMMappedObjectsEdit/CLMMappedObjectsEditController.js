({
    onInit: function(component, event, helper) {

        helper.callServer(component, 'c.getAllObjects', false, function(result) {


            component.set('v.allObjects', result);
            component.set('v.allObjectsList', result);
        });
    },
    handleSearchObject: function(component, event, helper) {
        var queryTerm = component.find('search-object').get('v.value');
        var allObjs = component.get('v.allObjects');
        if (queryTerm.length > 1) {

            component.set('v.allObjectsList', allObjs.filter(obj => obj.objectName.toLowerCase().includes(queryTerm.toLowerCase())));
        } else {
            component.set('v.allObjectsList', allObjs);
        }
    },
    handleSearchField: function(component, event, helper) {
        var queryTerm = component.find('search-field').get('v.value');
        var allObjs = component.get('v.allObjectFileds');
        if (queryTerm.length > 1) {
            component.set('v.allObjectFiledsList', allObjs.filter(obj => obj.objectName.toLowerCase().includes(queryTerm.toLowerCase())));
        } else {
            component.set('v.allObjectFiledsList', allObjs);
        }
    },
    onObjSelection: function(component, event, helper) {
        var apiName = event.currentTarget.id;
        var allObjects = component.get('v.allObjects');
        var allObjectsList = component.get('v.allObjectsList');
        allObjects.forEach(function(data) {
            if (data.objecApiName === apiName) {
                data.selected = true;
                component.set('v.SelectedObjDetais', data);
            } else {
                data.selected = false;
            }
        });
        allObjectsList.forEach(function(data) {
            if (data.objecApiName === apiName) {
                data.selected = true;
            } else {
                data.selected = false;
            }
        });
        component.set('v.allObjects', allObjects);
        component.set('v.allObjectsList', allObjectsList);
    },
    onObjFieldSelection: function(component, event, helper) {
        var apiName = event.currentTarget.id;
        var SelectedObjDetais = component.get('v.SelectedObjDetais');
        var allObjects = component.get('v.allObjectFileds');
        var allObjectsList = component.get('v.allObjectFiledsList');

        allObjects.forEach(function(datamain) {
            if (datamain.objecApiName === apiName) {
                datamain.selected = true;
                component.set('v.SelectedObjFieldName', '{!' + SelectedObjDetais.objectName + '.' + datamain.objecApiName + '}');
            } else {
                datamain.selected = false;
            }
        });
        allObjectsList.forEach(function(data) {
            if (data.objecApiName === apiName) {
                data.selected = true;
            } else {
                data.selected = false;
            }
        });
        component.set('v.SelectedFiledsDetails', allObjects.filter(data => data.selected === true));
        component.set('v.allObjectFileds', allObjects);
        component.set('v.allObjectFiledsList', allObjectsList);
    },
    onObjFieldDeSelection: function(component, event, helper) {
        var apiName = event.currentTarget.id;
        var SelectedObjDetais = component.get('v.SelectedObjDetais');
        var allObjects = component.get('v.allObjectFileds');
        var allObjectsList = component.get('v.allObjectFiledsList');

        allObjects.forEach(function(datamain) {
            if (datamain.objecApiName === apiName) {
                datamain.selected = false;
                component.set('v.SelectedObjFieldName', '{!' + SelectedObjDetais.objectName + '.}');
            } else {
                datamain.selected = false;
            }
        });
        allObjectsList.forEach(function(data) {
            if (data.objecApiName === apiName) {
                data.selected = false;
            } else {
                data.selected = false;
            }
        });
        component.set('v.SelectedFiledsDetails', allObjects.filter(data => data.selected === true));
        component.set('v.allObjectFileds', allObjects);
        component.set('v.allObjectFiledsList', allObjectsList);
    },
    back: function(component, event, helper) {
        var currentStep = component.get('v.currentStep');
        if (currentStep == '3') {
            helper.UpdateUI(component, '2');
        } else if (currentStep == '2') {
            helper.UpdateUI(component, '1');
        } else if (currentStep == '1') {
            //firet event to update breadcrumb
            helper.fireApplicationEvent(component, {
                navigateTo: { index: '1' },
                fromComponent: 'CLMMappedObjectsEdit',
                toComponent: 'CLMBreadcrumbs'
            }, 'CLMBreadcrumbsEvent');
            //fire event to display CLMCardModel
            helper.fireApplicationEvent(component, {
                componentName: 'CLMMappedObjectsHome',
                fromComponent: 'CLMMappedObjectsEdit',
                toComponent: 'CLMIntegrationLayout',
                type: 'show'
            }, 'CLMNavigationEvent');
        }
    },
    gotNextStep: function(component, event, helper) {
        var SelectedObjDetais = component.get('v.SelectedObjDetais');
        var currentStep = component.get('v.currentStep');
        if (currentStep == '1') {
            helper.UpdateUI(component, '2');
        } else if (currentStep == '2') {
            helper.UpdateUI(component, '3');
        }



    },

    updateFromPathUI: function(component, event, helper) {
        //-temporry need to migrate tis to base component--
        var navigateFrom = event.getParam("navigateFrom");
        var navigateTo = event.getParam("navigateTo");
        var fromComponent = event.getParam("fromComponent");
        var toComponent = event.getParam("toComponent");
        if ((toComponent == 'CLMCardModel' || toComponent == 'ANY') && fromComponent != 'CLMCardModel') {
            if (navigateTo != undefined) {
                helper.UpdateUI(component, navigateTo.index);

            }
        }
    },
})