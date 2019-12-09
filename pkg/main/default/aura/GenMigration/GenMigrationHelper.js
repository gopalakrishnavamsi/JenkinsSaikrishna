({
  handleScope: function (component, getResult, helper) {
    var scope = component.get('v.scope');
    // Handle Component view if rendered via DocumentGeneration Tab
    if (scope === 'DocumentGeneration') {
      helper.setMigrationTemplateHeader(component);
      component.set('v.showBlock', getResult.isGenPackageUser ? true : false);
      if (getResult.onLoadTemplateCount === 0 || (!$A.util.isEmpty(getResult.getGenStatus) && getResult.getGenStatus.dfsle__GenTemplatesMigrated__c)) {
        component.set('v.isGenPackageUser', false);
        component.set('v.showBlock', false);
      }
      // Handle Component view if rendered via UserManagement Tab
    } else if (scope === 'User') {
      helper.setMigrationUserHeader(component);
      component.set('v.showBlock', getResult.isGenPackageUser ? true : false);
      if (getResult.onLoadUserCount === 0 || (!$A.util.isEmpty(getResult.getGenStatus) && getResult.getGenStatus.dfsle__GenUsersMigrated__c)) {
        component.set('v.isGenPackageUser', false);
        component.set('v.showBlock', false);
      }
    }
    helper.toggleView(component, getResult, helper);
  },

  toggleView: function (component, getResult, helper) {

    // based on custom setting record we are showing user/template block
    if (!$A.util.isEmpty(getResult.getGenStatus)) {
      // When User Batch is in Queue,Showing loader Icon,text and hiding User button
      if (getResult.getGenStatus.dfsle__GenUsersMigrated__c === false && !$A.util.isEmpty(getResult.getGenStatus.dfsle__UserMigrationBatchId__c) && $A.util.isEmpty(getResult.getGenStatus.dfsle__UserMigrationBatchStatus__c)) {
        component.set('v.isUsersMigrated', true);
        component.set('v.migrationUserStatusMessage', $A.get('$Label.c.OnLoadMigrationText'));
      }
      // When User Batch encounters an error,Showing error msg
      else if (getResult.getGenStatus.dfsle__GenUsersMigrated__c === false && !$A.util.isEmpty(getResult.getGenStatus.dfsle__UserMigrationBatchId__c) && !$A.util.isEmpty(getResult.getGenStatus.dfsle__UserMigrationBatchStatus__c)) {
        component.set('v.isUsersMigrated', false);
        component.set('v.migrationUserStatusMessage', stringUtils.format($A.get('$Label.c.MigrateTemplateErrorText'), component.get('v.getResult').onLoadUserCount + ' user(s) ', getResult.getGenStatus.dfsle__UserMigrationBatchStatus__c));
      }
      // When User Batch finished successfully,showing success text and hiding button
      else if (getResult.getGenStatus.dfsle__GenUsersMigrated__c === true) {
        component.set('v.migrationUserStatusMessage', stringUtils.format($A.get('$Label.c.MigrateUsersSuccessMsg')));
        component.set('v.isUsersMigrated', true);
        component.set('v.userStatusIcon', false);
      }
      // When Template Batch is in Queue,Showing loader Icon,text and hiding Template button
      if (getResult.getGenStatus.dfsle__GenTemplatesMigrated__c === false && !$A.util.isEmpty(getResult.getGenStatus.dfsle__TemplateMigrationBatchId__c) && $A.util.isEmpty(getResult.getGenStatus.dfsle__TemplateMigrationBatchStatus__c)) {
        component.set('v.isTemplatesMigrated', true);
        component.set('v.migrationTemplateStatusMessage', $A.get('$Label.c.OnLoadMigrationText'));
      }
      // When Template Batch encounters an error,Showing error msg
      else if (getResult.getGenStatus.dfsle__GenTemplatesMigrated__c === false && !$A.util.isEmpty(getResult.getGenStatus.dfsle__TemplateMigrationBatchId__c) && !$A.util.isEmpty(getResult.getGenStatus.dfsle__TemplateMigrationBatchStatus__c)) {
        component.set('v.isTemplatesMigrated', false);
        component.set('v.migrationTemplateStatusMessage', stringUtils.format($A.get('$Label.c.MigrateTemplateErrorText'), component.get('v.getResult').onLoadTemplateCount + ' template(s) ', getResult.getGenStatus.dfsle__TemplateMigrationBatchStatus__c));
      }
      // When Template Batch finished successfully,showing success text and hiding button
      else if (getResult.getGenStatus.dfsle__GenTemplatesMigrated__c === true) {
        component.set('v.migrationTemplateStatusMessage', stringUtils.format($A.get('$Label.c.MigrateTemplatesSuccessMsg')));
        component.set('v.isTemplatesMigrated', true);
        component.set('v.templateStatusIcon', false);
      }
      // When User and Template Migration is completed then Showing Success msgs and Uninstall text
      if (getResult.getGenStatus.dfsle__GenTemplatesMigrated__c === true && getResult.getGenStatus.dfsle__GenUsersMigrated__c === true) {
        component.set('v.migrationTemplateStatusMessage', stringUtils.format($A.get('$Label.c.MigrateTemplatesSuccessMsg')));
        component.set('v.migrationUserStatusMessage', stringUtils.format($A.get('$Label.c.MigrateUsersSuccessMsg')));
        component.set('v.showPackageUnInstallText', true);
      }

    }

    // Hiding User or Template Block if there are No Users or No Templates to Migrate respectively
    if (getResult.onLoadUserCount === 0) {
      helper.setMigrationTemplateHeader(component);
    }
    if (getResult.onLoadTemplateCount === 0) {
      helper.setMigrationUserHeader(component);
    }
    if (getResult.onLoadUserCount === 0 && getResult.onLoadTemplateCount === 0) {
      component.set('v.tabMigrationHeader', $A.get('$Label.c.TabMigrationHeaderUninstallText'));
      component.set('v.migrationHelpText', $A.get('$Label.c.MigrationHelpTextforUninstall'));
      component.set('v.showPackageUnInstallText', false);
    }
  },

  callServer: function (component, method, param, callback) {
    var action = component.get(method);
    if (param) {
      action.setParams(param);
    }
    action.setCallback(this, callback);
    $A.enqueueAction(action);
  },

  // for Error msgs
  showToast: function (component, message, mode) {
    component.set('v.message', message);
    component.set('v.mode', mode);
    component.set('v.showToast', true);
    setTimeout($A.getCallback(function () {
      component.find('toast').close();
    }), 3000);
  },

  setMigrationTemplateHeader: function (component) {
    component.set('v.migrationHelpText', $A.get('$Label.c.DocumentGenerationText'));
    component.set('v.tabMigrationHeader', $A.get('$Label.c.DocumentGenerationTabText'));
    component.set('v.hideMigrateUsers', false);
  },

  setMigrationUserHeader: function (component) {
    component.set('v.tabMigrationHeader', $A.get('$Label.c.UserManagementTabHeader'));
    component.set('v.migrationHelpText', $A.get('$Label.c.MigrationUsersHelpText'));
    component.set('v.hideMigrateTemplates', false);
  }
});