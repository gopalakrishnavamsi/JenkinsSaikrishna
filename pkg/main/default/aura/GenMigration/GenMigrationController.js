({
  onInitialize: function (component, event, helper) {
    component.set('v.showBlock', false);
    helper.callServer(component, 'c.isGenPackageInstalled', {},
      function (response) {
        var result = response.getReturnValue();
        var status = response.getState();
        if (status === 'SUCCESS') {
          component.set('v.getResult', result);
          component.set('v.isGenPackageUser', result.isGenPackageUser);
          component.set('v.migrationUserStatusMessage', stringUtils.format($A.get('$Label.c.NumberOfGenUsers'), result.onLoadUserCount || 0));
          component.set('v.migrationTemplateStatusMessage', stringUtils.format($A.get('$Label.c.OnLoadTemplateText'), result.onLoadTemplateCount || 0));
          helper.handleScope(component, result, helper);
        } else {
          helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
        }
      });
  },

  migrateUsersConfiguration: function (component, event, helper) {
    // For hiding/showing UserButton
    component.set('v.isUsersMigrated', true);
    // adding time interval to avoid duplicate setupOwnerId issue in custom setting,
    // when user clicks User & Template without any time gap
    var interval = 0;
    if (component.get('v.scope') === 'All' && component.get('v.isTemplatesMigrated')) {
      interval = 500;
    }
    setTimeout($A.getCallback(function () {
      helper.callServer(component, 'c.initiateUserMigration', {},
        function (response) {
          var status = response.getState();
          if (status === 'SUCCESS') {
            component.set('v.migrationUserStatusMessage', $A.get('$Label.c.OnLoadMigrationText'));
          } else {
            component.set('v.isUsersMigrated', false);
            component.set('v.migrationUserStatusMessage', stringUtils.format($A.get('$Label.c.MigrateTemplateErrorText'),
              component.get('v.getResult').onLoadUserCount + ' user(s) ', stringUtils.getErrorMessage(response)));
          }
        });
    }), interval);

  },

  migrateTemplateConfiguration: function (component, event, helper) {
    component.set('v.isTemplatesMigrated', true); // For hiding/showing TemplateButton
    // adding time interval to avoid duplicate setupOwnerId issue in custom setting,
    // when user clicks User & Template button without any time gap
    var interval = 0;
    if (component.get('v.scope') === 'All' && component.get('v.isUsersMigrated')) {
      interval = 500;
    }
    setTimeout($A.getCallback(function () {
      helper.callServer(component, 'c.initiateTemplateMigration', {},
        function (response) {
          var status = response.getState();
          if (status === 'SUCCESS') {
            component.set('v.migrationTemplateStatusMessage', $A.get('$Label.c.OnLoadMigrationText'));
          } else {
            component.set('v.isTemplatesMigrated', false);
            component.set('v.migrationTemplateStatusMessage', stringUtils.format($A.get('$Label.c.MigrateTemplateErrorText'),
              component.get('v.getResult').onLoadTemplateCount + ' template(s)', stringUtils.getErrorMessage(response)));
          }
        });
    }), interval);

  }
});
