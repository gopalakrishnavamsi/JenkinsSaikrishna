({
  initializeNewVersionWidget: function (component, event, helper) {
    component.set('v.loading', true);
    helper.fetchAgreementVersions(component);
    var agreement = component.get('v.agreementDetails');
    var limitedAccessToken = component.get('c.generateUploadNewVersionToken');
    limitedAccessToken.setParams({
      agreementId: agreement.id.value
    });
    limitedAccessToken.setCallback(this, function (response) {
      var state = response.getState();
      var result = response.getReturnValue();
      if (state === 'SUCCESS') {
        try {
          var options = {
            iconPath: $A.get('$Resource.scmwidgetsspritemap'),
            accessTokenFn: function () {
              return new Promise(function (resolve, reject) {
                limitedAccessToken.setCallback(this, function (response2) {
                  var state2 = response2.getState();
                  if (state2 === 'SUCCESS') {
                    resolve(response2.getReturnValue().token);
                  } else if (state2 === 'ERROR') {
                    reject(response2.getError());
                  }
                });
                $A.enqueueAction(limitedAccessToken);
              });
            },
            apiBaseDomain: result.apiUploadBaseUrl,
            accountId: result.accountId.value
          };
          var uploadWidget = new SpringCM.Widgets.Upload(options);
          uploadWidget.render('#upload-wrapper');
          helper.setUploadEvent(component);
          component.set('v.widget', uploadWidget);
          component.set('v.loading', false);
        } catch (error) {
          helper.showToast(component, error, 'error');
          component.set('v.loading', false);
        }
      } else {
        var errorMessage = $A.get('$Label.c.ErrorMessage');
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            errorMessage += errors[0].message;
          }
        } else {
          errorMessage += $A.get('$Label.c.UnknownError');
        }
        component.set('v.loading', false);
        helper.showToast(component, errorMessage, 'error');
      }
    });
    $A.enqueueAction(limitedAccessToken);
  },

  fetchAgreementVersions: function (component) {
    var agreementVersions = [];
    var agreement = component.get('v.agreementDetails');
    //set original version
    var originalVersion = {
      'name': stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
      'currentVersion': stringUtils.format('{0} {1} ', 'Original', '-'),
      'createdDate': agreement.createdDate,
      'extension': agreement.extension
    };

    //If no versions have been uploaded apart from the original version then display only the original version with details
    if ($A.util.isEmpty(agreement.versions)) {
      agreementVersions.push(originalVersion);
    }

    //If versions exists for an agreement push all the version details
    else {
      agreement.versions.forEach(function (versionInformation) {
        agreementVersions.push({
          'name': stringUtils.format('{0}{1}{2}', versionInformation.name, '.', versionInformation.extension),
          'currentVersion': stringUtils.format('{0} {1} ', versionInformation.version, '-'),
          'createdDate': versionInformation.createdDate,
          'extension': versionInformation.extension
        });
      });
      //Add original version
      agreementVersions.push(originalVersion);
    }
    component.set('v.agreementVersions', agreementVersions);
  },

  uploadButtonClicked: function (component, event, helper) {
    component.set('v.loading', true);
    var widget = component.get('v.widget');
    var agreement = component.get('v.agreementDetails');

    try {
      widget
        .uploadNewDocumentVersion(agreement.id.value)
        .then(function () {
          helper.showToast(
            component,
            $A.get('$Label.c.UploadNewVersionSuccess'),
            'success'
          );
          helper.reloadAgreementsSpace(component);
          helper.close(component);

        })
        .catch(function () {
          helper.showToast(component,
            $A.get('$Label.c.UploadNewVersionError'),
            'error');
          helper.close(component);

        });
    } catch (error) {
      helper.showToast(component,
        $A.get('$Label.c.UploadNewVersionError'),
        'error');
      helper.close(component);
    }
  },

  close: function (component) {
    component.destroy();
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  },

  setUploadEvent: function (component) {
    document.addEventListener('springcm:upload:fileChange', function (event) {
      component.set(
        'v.hasDocument',
        event.detail && event.detail.files && event.detail.files.length > 0
      );
    });
  },

  reloadAgreementsSpace: function (component) {
    component.getEvent('reloadEvent').fire();
  }
});
