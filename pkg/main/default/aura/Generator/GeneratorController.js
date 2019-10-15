({
  onChangeIsAuthorized: function (component, event, helper) {
    var isAuthorized = component.get('v.isAuthorized');
    var products = component.get('v.products');
    if (!$A.util.isUndefinedOrNull(products)) {
      products.forEach(function (product) {
        if (product.name === 'e_sign' && product.status === 'active') {
          component.set('v.isESignatureEnabled', true);
        } else if (product.name === 'negotiate' && product.status === 'active') {
          component.set('v.isNegotiateEnabled', true);
        } else if (product.name === 'gen') {
          component.set('v.isGenEnabled', product.status === 'active');
          component.set('v.isGenTrialExpired', product.isExpired);
        }
      });
    }
    var isGenEnabled = component.get('v.isGenEnabled');
    if (isAuthorized && isGenEnabled) {
      var config = component.get('v.config');
      helper.checkMultiCurrency(component);
      if ($A.util.isEmpty(config)) {
        var templateId = component.get('v.templateId');
        if (!$A.util.isUndefinedOrNull(templateId)) {
          var action = component.get('c.getTemplate');

          action.setParams({
            templateId: templateId
          });

          action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
              var results = response.getReturnValue();
              component.set('v.config', results);
              component.set('v.templateFiles', results.generated);
              helper.setupData(component);
            } else {
              component.set('v.errType', 'error');
              component.set('v.errMsg', stringUtils.getErrorMessage(response));
            }
          });
          $A.enqueueAction(action);
        }
      } else {
        component.set('v.isLoading', true);
        // TODO: Verify has Gen license, trial not expired, etc.
        helper.setupData(component);
        component.set('v.isLoading', false);
      }
    }
  },

  generateDocs: function (component, event, helper) {
    helper.getRecordData(component);
  },

  checkRemaingFiles: function (component) {
    var files = component.get('v.templateFiles');
    var selected = [];

    files.forEach(function (el) {
      if (el.isChecked) {
        selected.push(el);
      }
    });

    component.set('v.disableGenerateButton', selected.length === 0);
  },

  removeFocusCatcher: function (component, event) {
    event.currentTarget.remove();
  },

  sendForSignature: function (component, event, helper) {
    var isESignatureEnabled = component.get('v.isESignatureEnabled');
    if (isESignatureEnabled) {
      helper.sendForSignature(component);
    }
  },

  goBack: function (component, event, helper) {
    helper.navigateToSource(component);
  },

  previewFile: function (component, event) {
    var fileId = event.currentTarget.getAttribute('data-fileId');
    navUtils.navigateToUrl('/' + fileId);
  },

  downloadFile: function (component, event) {
    var fileId = event.currentTarget.getAttribute('data-fileId');
    navUtils.navigateToUrl($A.get('$Label.c.DocumentPreviewLink') + fileId);
  },

  internalApproval: function (component, event, helper) {
    var isNegotiateEnabled = component.get('v.isNegotiateEnabled');
    if (isNegotiateEnabled) {
      component.set('v.isLoading', true);
      helper.createAgreement(component, event, helper).then(
        $A.getCallback(function () {
          helper.createInternalApprovalComponent(component);
        })
      );
    }
  },

  externalReview: function (component, event, helper) {
    var isNegotiateEnabled = component.get('v.isNegotiateEnabled');
    if (isNegotiateEnabled) {
      component.set('v.isLoading', true);
      helper.createAgreement(component, event, helper).then(
        $A.getCallback(function () {
          helper.createExternalReviewComponent(component);
        })
      );
    }
  },

  genFileCheckboxToggle: function (component, event, helper) {
    helper.genFileCheckboxToggle(component);
  },

  handleToastEvent: function (component, event, helper) {
    var params = event.getParams();
    if (params && params.show === true) {
      helper.showToast(component, params.message, params.mode);
      if (params.mode === 'success') {
        setTimeout($A.getCallback(function () {
          helper.hideToast(component);
        }), 5000);
      }
    } else {
      helper.hideToast(component);
    }
  },

  navigateToSource: function (component, event, helper) {
    window.setTimeout($A.getCallback(function () {
      helper.navigateToSource(component);
    }), 1000);
  }
});
