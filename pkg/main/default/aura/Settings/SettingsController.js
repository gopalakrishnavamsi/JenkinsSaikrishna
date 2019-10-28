({
  onInitialize: function (component, event, helper) {
    helper.getSettings(component, event, helper);
  },
  
  onChange: function (component, event, helper) {
    helper.saveSettings(component, event, helper);
  }
});
