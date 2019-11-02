({
  buttonClick: function (component, event, helper) {
    var invokedBy = component.get('v.invokedBy');
    if (invokedBy === 'Workflow-GoToWorkflow') {
      helper.callServer(component, 'c.getWorkflowButtonLink', false, function (result) {
        navUtils.navigateToUrl(result);
      });
    }
    else if (invokedBy === 'DocGen-GoToDocGen') {
      helper.callServer(component, 'c.getDocGenButtonLink', false, function (result) {
        navUtils.navigateToUrl(result);
      });
    }
  }
})
