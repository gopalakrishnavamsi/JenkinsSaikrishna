({
  doInit: function (component, event, helper) {
    helper.loadAllDataSources(component);
  },
  searchHandler: function (component, event, helper) {
    var searchString = event.target.value;
    helper.searchRecords(component, searchString);
  },

  optionClickHandler: function (component, event) {
    var commonObjects = ['Account', 'Contact', 'Lead', 'Case', 'Opportunity'];
    var selectedId = event.target.closest('li').dataset.id;
    var selectedValue = event.target.closest('li').dataset.value;
    component.set('v.inputValue', selectedValue);
    component.set('v.openDropDown', false);
    var template = component.get('v.template');
    var fieldMappingsString = '[{"type":"ROOT","path":[],"key":"' + selectedId + '","fields":[],"depth":1}]';
    template.objectMappings = {
      version: 2,
      name: selectedId,
      label: selectedValue,
      fieldMappings: JSON.parse(fieldMappingsString),
    };
    template.sourceObject = selectedId;
    component.set('v.template', template);
    component.set('v.iconName', commonObjects.includes(selectedId) ? 'standard:' + selectedId.toLowerCase() : 'standard:account');
  },

  clearOption: function (component) {
    component.set('v.openDropDown', false);
    component.set('v.inputValue', '');
    var template = component.get('v.template');
    template.objectMappings = {
      version: 2,
      name: '',
      label: '',
      fieldMappings: [],
    };
    template.sourceObject = '';
    component.set('v.template', template);
    component.set('v.iconName', '');
  },

  showOptions: function (component) {
    component.set('v.openDropDown', true);
  }
});