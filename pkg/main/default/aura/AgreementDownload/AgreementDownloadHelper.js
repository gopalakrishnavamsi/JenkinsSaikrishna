({
  fireDownloadEvent: function (component, event, helper) {
    var downloadWithRedlines = component.get('v.downloadWithRedlines');

    if (downloadWithRedlines) {
      helper.triggerDownloadWithRedlines(component, helper);
    } else {
      helper.triggerDownload(component, helper);
    }
  },

  // when downloading a redlined agreement, compare versions to produce a task ID for downloading
  triggerDownloadWithRedlines: function (component, helper) {
    helper.fetchCompareVersionsTaskId(component, helper)
      .then(function (taskId) {
        helper.downloadAgreement(component, helper, taskId.value);
      })
      .catch(function (error) {
        helper.showToast(component, error, 'error');
      });
  },

  // pass agreement ID for regular download (no redlines)
  triggerDownload: function (component, helper) {
    var agreementDetails = component.get('v.agreementDetails');
    helper.downloadAgreement(component, helper, agreementDetails.id.value);
  },

  // Resolves with a task ID produced from versions comparison
  fetchCompareVersionsTaskId: function (component, helper) {
    var agreementDetails = component.get('v.agreementDetails');
    var actionName = 'c.compareAgreementsTaskId';
    var parameters = {
      originalDocumentHref: agreementDetails.versions[0].href,
      compareVersionHref: agreementDetails.href
    };
    return helper.fireApiEvent(component, actionName, parameters);
  },

  // Resolves with a payload containing a limited content access token based on a given object ID
  generateDownloadToken: function (component, helper, objectId) {
    var actionName = 'c.generateDownloadToken';
    var parameters = {
      objectId: objectId
    };
    return helper.fireApiEvent(component, actionName, parameters);
  },

  downloadAgreement: function (component, helper, objectId) {
    helper.generateDownloadToken(component, helper, objectId)
      .then(function (response) {
        helper.beginDownload(component, helper, response, objectId);
      })
      .catch(function (error) {
        helper.showToast(component, error, 'error');
      });
  },

  fireApiEvent: function (component, actionName, parameters) {
    var action = component.get(actionName);
    action.setParams(parameters);
    return new Promise($A.getCallback(function (resolve, reject) {
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(stringUtils.getErrorMessage(response));
        }
      });
      $A.enqueueAction(action);
    }));
  },

  beginDownload: function (component, helper, response, objectId) {
    var agreementDetails = component.get('v.agreementDetails');
    var fileName = stringUtils.format('{0}{1}{2}', agreementDetails.name, '.', agreementDetails.extension);
    var successMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.SuccessDownloadingFile'), agreementDetails.name);
    var errorMessage = stringUtils.format('{0} {1}', $A.get('$Label.c.ErrorDownloadingFile'), agreementDetails.name);

    var downloadAction = helper.getDownloadAction(component);
    downloadAction(response.apiDownloadBaseUrl, response.token, response.accountId.value, objectId, fileName)
      .then(helper.toastEvent(component, helper, successMessage, 'success'))
      .catch(helper.toastEvent(component, helper, errorMessage, 'error'));
  },

  getDownloadAction: function (component) {
    return component.get('v.downloadWithRedlines') ?
      SpringCM.Widgets.Download.downloadGeneratedDocument :
      SpringCM.Widgets.Download.downloadDocument;
  },

  toastEvent: function (component, helper, message, mode) {
    return function () {
      helper.showToast(component, message, mode);
    };
  },

  showToast: function (component, message, mode) {
    var fireToastEvent = component.getEvent('toastEvent');
    fireToastEvent.setParams({
      show: true,
      message: message,
      mode: mode
    });
    fireToastEvent.fire();
  }
});
