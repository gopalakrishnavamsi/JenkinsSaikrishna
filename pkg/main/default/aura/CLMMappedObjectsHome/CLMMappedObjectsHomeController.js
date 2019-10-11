({
  onInit: function (component, event, helper) {
    helper.callServer(component, 'c.getNamespace', false, function (namespace) {
      namespace = namespace || component.get('v.namespace');
      var actions = [
        { label: 'Edit Mapping', name: 'edit' },
        { label: 'Remove Mapping', name: 'remove' }
      ];
      var pathApiName = namespace === 'c' ? 'Path__c' : namespace + '__Path__c';
      var folderApiName = namespace === 'c' ? 'FolderName__c' : namespace + '__FolderName__c';
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
          fieldName: folderApiName,
          type: 'url',
          sortable: true,
          cellAttributes: { alignment: 'left' },
          typeAttributes: {
            label: {
              fieldName: folderApiName
            },
            tooltip: {
              fieldName: folderApiName
            },
            title: {
              fieldName: folderApiName
            }
          }
        },
        {
          label: $A.get('$Label.c.PathInDocuSignCLM'),
          fieldName: pathApiName,
          type: 'url',
          sortable: true,
          cellAttributes: { alignment: 'left', tooltip: 'actions' },
          typeAttributes: {
            label: {
              fieldName: pathApiName
            },
            tooltip: {
              fieldName: pathApiName
            },
            title: {
              fieldName: pathApiName
            }
          }
        },
        {
          label: 'Date Added',
          fieldName: 'CreatedDate',
          type: 'date-local',
          sortable: true,
          cellAttributes: { alignment: 'left' },
          typeAttributes: {
            month: '2-digit',
            day: '2-digit'
          }
        },
        {
          label: 'Date Modified',
          fieldName: 'LastModifiedDate',
          type: 'date-local',
          sortable: true,
          cellAttributes: { alignment: 'left' },
          typeAttributes: {
            month: '2-digit',
            day: '2-digit'
          }
        },
        { type: 'action', typeAttributes: { rowActions: actions } }
      ];
      component.set('v.mapColumns', column);
      helper.callServer(component, 'c.getMappedObjectsList', false, function (data) {
        if (data.Account && data.Opportunity && Object.values(data).length === 2) {
          helper.fireApplicationEvent(component, {
            fromComponent: 'CLMMappedObjectsHome',
            toComponent: 'CLMScopedNotifications',
            type: 'show'
          }, 'CLMEvent');
        }
        if (Object.values(data).length === 0) {
          helper.fireApplicationEvent(
            component,
            {
              componentName: 'CLMCardModel',
              fromComponent: 'CLMMappedObjectsHome',
              toComponent: 'CLMIntegrationLayout',
              type: 'hide'
            },
            'CLMNavigationEvent'
          );
        }
        component.set('v.mappedObjData', Object.values(data));
        component.set('v.sortedByColumn', $A.get('$Label.c.SalesforceObject'));
        component.set('v.sortedBy', 'Name');
        component.set('v.sortedDirection', 'asc');
        helper.sortData(component, 'Name', 'asc');
      });
      helper.createComponent(component, 'c:CLMModelFooterButton', {
        primaryButtonLabel: $A.get('$Label.c.Remove'),
        secondaryButtonLabel: $A.get('$Label.c.Cancel'),
        primaryButtonVariant: 'destructive'
      }, function (newCmp) {
        component.set('v.strikeModelFooterButtons', newCmp);
      });
    });
  },

  gotoNew: function (component, event, helper) {
    //fire event to display CLMCardModel
    helper.fireApplicationEvent(
      component,
      {
        componentName: 'CLMCardModel',
        fromComponent: 'CLMMappedObjectsHome',
        toComponent: 'CLMIntegrationLayout',
        type: 'show'
      },
      'CLMNavigationEvent'
    );
    helper.fireApplicationEvent(
      component,
      {
        fromComponent: 'CLMMappedObjectsHome',
        toComponent: 'CLMSetupLayout',
        type: 'update',
        tabIndex: '3.1'
      },
      'CLMNavigationEvent'
    );
  },

  removeMappingModalHandler: function (component, event, helper) {
    var data = component.get('v.tempMappingModalDataHolder');
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
          if (newObjectList.length === 0) {
            helper.fireApplicationEvent(
              component,
              {
                componentName: 'CLMCardModel',
                fromComponent: 'CLMMappedObjectsHome',
                toComponent: 'CLMIntegrationLayout',
                type: 'hide'
              },
              'CLMNavigationEvent'
            );
          }
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
      case 'edit':
        helper.edit(component, row, helper);
        break;
      case 'remove':
        helper.remove(component, row, helper);
        break;
    }
  },

  updateColumnSorting: function (component, event, helper) {
    var namespace = component.get('v.namespace');
    var fieldName = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    component.set('v.sortedBy', fieldName);
    var sortedByColumn = '';
    var folderName = namespace === 'c' ? 'FolderName__c' : namespace + '__FolderName__c';
    var path = namespace === 'c' ? 'Path__c' : namespace + '__Path__c';
    if (fieldName === 'Name') {
      sortedByColumn = $A.get('$Label.c.SalesforceObject');
    } else if (fieldName === folderName) {
      sortedByColumn = $A.get('$Label.c.ObjectFolderName');
    } else if (fieldName === path) {
      sortedByColumn = $A.get('$Label.c.PathInDocuSignCLM');
    } else if (fieldName === 'CreatedDate') {
      sortedByColumn = 'Date Added';
    } else if (fieldName === 'LastModifiedDate') {
      sortedByColumn = 'Date Modified';
    }
    component.set('v.sortedByColumn', sortedByColumn);
    component.set('v.sortedBy', fieldName);
    component.set('v.sortedDirection', sortDirection);
    helper.sortData(component, fieldName, sortDirection);
  }

});