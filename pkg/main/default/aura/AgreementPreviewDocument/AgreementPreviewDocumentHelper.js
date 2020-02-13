({
  onLoad: function (component, event, helper) {
    component.set('v.loading', true);
    var agreement = component.get('v.agreement');
    helper.loadWidget(component, agreement, agreement.href);
  },

  loadAgreementStatusTypes: function (component) {
    var action = component.get('c.getAgreementStatusTypes');
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.AgreementStatusTypes', response.getReturnValue());
      }
    });
    $A.enqueueAction(action);
  },

  loadWidget: function (component, agreement, documentUrl) {
    try {
      var uiHelper = component.get('v.uiHelper');
      var self = this;
      var isCurrentUserSender = this.isCurrentUserSender(component, agreement);
      var isCurrentUserRecipientForApproval = this.isCurrentUserRecipientForApproval(component, agreement);
      Promise.all(
        [
          this.baseOptions(component, uiHelper, component.get('v.sourceId')),
          this.getResourceToken(agreement.id.value, component, uiHelper),
          this.getApprovalWorkItems(component, uiHelper)
        ]
      )
        .then(function (tokens) {
          return Object.freeze({
            baseOptions: tokens[0],
            resourceToken: tokens[1]
          });
        })
        .then(function (options) {
          var widget = self.resolvePreview(
            component,
            options,
            agreement,
            documentUrl,
            component.get('v.currentUserDocuSignAdmin'),
            isCurrentUserSender,
            isCurrentUserRecipientForApproval
          );
          component.set('v.loading', false);
          component.set('v.widget', widget);
        })
        .catch(function (err) {
          uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
        });
    } catch (err) {
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  baseOptions: function (component, uiHelper, sourceId) {
    var self = this;
    return new Promise($A.getCallback(function (resolve, reject) {
      self.getAccessToken(component, uiHelper, sourceId, true)
        .then(function (token) {
          resolve(
            Object.freeze({
              iconPath: $A.get('$Resource.scmwidgetsspritemap'),
              accessTokenFn: function () {
                return self.getAccessToken(component, uiHelper, sourceId, false);
              },
              uploadApiBaseDomain: token.apiUploadBaseUrl,
              downloadApiBaseDomain: token.apiDownloadBaseUrl,
              language: $A.get('$Locale.langLocale') ? $A.get('$Locale.langLocale').toLowerCase() : undefined,
              accountId: token.accountId.value
            })
          );
        })
        .catch(function (err) {
          reject(err);
        });
    }));
  },

  getAccessToken: function (component, uiHelper, sourceId, isSetup) {
    var agreementIdValue = component.get('v.agreement').id.value;
    var generateUploadAction = component.get('c.generateUploadNewVersionToken');
    generateUploadAction.setParams({
      agreementId: agreementIdValue
    });
    return new Promise($A.getCallback(function (resolve, reject) {
      generateUploadAction.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          if (isSetup) {
            resolve(response.getReturnValue());
          } else {
            resolve(response.getReturnValue().token);
          }
        } else {
          reject(uiHelper.getErrorMessage(response));
        }
      }));
      $A.enqueueAction(generateUploadAction);
    }));
  },

  getResourceToken: function (agreementId, component, uiHelper) {
    var action = component.get('c.generateResourceToken');
    return new Promise(function (resolve, reject) {
      action.setParams({
        agreementId: agreementId
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(uiHelper.getErrorMessage(response));
        }
      });
      $A.enqueueAction(action);
    });
  },

  getApprovalWorkItems: function (component, uiHelper) {
    var getWorkItemsAction = component.get('c.getApprovalWorkItems');
    var agreementId = component.get('v.agreement').id.value;
    var agreementStatus = component.get('v.agreement').status.toLowerCase();
    return new Promise(function (resolve, reject) {
      //Fetching approval workItems only if the current agreement status is pending approval
      if (agreementStatus === 'pending approval') {
        getWorkItemsAction.setParams({
          agreementId: agreementId
        });
        getWorkItemsAction.setCallback(this, function (response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            component.set('v.approvalWorkItems', response.getReturnValue());
            resolve();
          } else {
            reject(uiHelper.getErrorMessage(response));
          }
        });
        $A.enqueueAction(getWorkItemsAction);
      }
      //resolving the promise directly since we do not need to fetch approval workitems for agreements that are not pending approval
      else {
        resolve();
      }
    });
  },

  resolvePreview: function (component, auth, agreement, documentUrl, isAdmin, isSender, isApprover) {
    var agreementStatus = agreement.status.toUpperCase();
    var AgreementStatusTypes = component.get('v.AgreementStatusTypes');
    if (agreementStatus === AgreementStatusTypes.NEW_AGREEMENT ||
      agreementStatus === AgreementStatusTypes.NEW_VERSION ||
      agreementStatus === AgreementStatusTypes.COMPLETED ||
      agreementStatus === AgreementStatusTypes.REJECTED ||
      agreementStatus === AgreementStatusTypes.APPROVAL_CANCELLED ||
      agreementStatus === AgreementStatusTypes.REVIEW_CANCELLED ||
      agreementStatus === AgreementStatusTypes.REVIEWED ||
      agreementStatus === AgreementStatusTypes.REVIEW_EXPIRED ||
      agreementStatus === AgreementStatusTypes.APPROVED) {
      //render the Status + History View
      return this.basePreview(
        component,
        agreement.id.value,
        stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
        documentUrl,
        agreement.historyItems,
        true,
        auth
      );
    }

    //External Review Pending
    else if (agreementStatus === AgreementStatusTypes.PENDING_REVIEW) {
      //If current user is the sender of the external review request or the current user is an admin user
      //In this case the user should be presented with the options for resending, completing and cancelling the review
      if (isSender === true || isAdmin === true)
        return this.externalReviewSenderView(
          component,
          this.basePreview(
            component,
            agreement.id.value,
            stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ),
          true
        );

      //If the current user is neither the sender of the external review nor an Admin user
      //In this case the user should just be shown the History + Status view
      return this.basePreview(
        component,
        agreement.id.value,
        stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
        documentUrl,
        agreement.historyItems,
        true,
        auth
      );
    }

    //Internal Approval pending
    else if (agreementStatus === AgreementStatusTypes.PENDING_APPROVAL) {
      var hasApproverResponded = this.hasCurrentApprovalRecipientResponded(component, agreement);
      //If current user is the sender of the Approval request but not an Admin User
      //In this case the user should be presented with the options for resending, cancelling the approval request
      if (isSender === true && isAdmin === false)
        return this.approvalSenderView(
          component,
          this.basePreview(
            component,
            agreement.id.value,
            stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ),
          true,
          false
        );

      //If current user is the sender of the Approval request and also an Admin User
      //In this case the user should be presented with the options for resending, cancelling as well as approving on behalf of
      if (isSender === true && isAdmin === true)
        return this.approvalSenderView(
          component,
          this.basePreview(
            component,
            agreement.id.value,
            stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ),
          true,
          true
        );

      //If the current user is the Approver for the Approval request
      //In this case the user should be presented with option for submitting a response for the approval
      if (isApprover && !hasApproverResponded)
        return this.renderApprovalRecipientView(
          component,
          this.basePreview(
            component,
            agreement.id.value,
            stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
            documentUrl,
            agreement.historyItems,
            true,
            auth
          )
        );

      //If the current user is neither and Approver nor the Sender but an Admin user
      ////In this case the user should be presented with the options for resending, cancelling as well as approving on behalf of
      if (isAdmin === true && (isSender !== true && isApprover !== true))
        return this.approvalSenderView(
          component,
          this.basePreview(
            component,
            agreement.id.value,
            stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ),
          true,
          true
        );

      //If current user is neither the sender , admin or recipient of the approval request
      //In this case the user should be displayed with the base Status+History View
      return this.basePreview(
        component,
        agreement.id.value,
        stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
        documentUrl,
        agreement.historyItems,
        true,
        auth
      );

    } else {
      return this.basePreview(
        component,
        agreement.id.value,
        stringUtils.format('{0}{1}{2}', agreement.name, '.', agreement.extension),
        documentUrl,
        agreement.historyItems,
        true,
        auth
      );
    }
  },

  basePreview: function (
    component,
    agreementId,
    agreementName,
    documentUrl,
    historyItems,
    showHistoryView,
    auth
  ) {
    var componentHelper = this;
    if (!agreementId || !documentUrl || !agreementName || !auth) throw 'Missing Parameter';
    var preview = new SpringCM.Widgets.Preview(auth.baseOptions);
    preview.render('#agreementDocumentView');
    /* Start of versions for setting up with the widget*/
    var versions = [];
    var agreementDetails = component.get('v.agreement');
    if (!$A.util.isEmpty(agreementDetails.versions)) {
      agreementDetails.versions.forEach(function (agreementVersion) {
        versions.push({
          'version': agreementVersion.version,
          'href': agreementVersion.href,
          'modifiedBy': agreementVersion.modifiedBy,
          'modifiedDate': agreementVersion.modifiedDate
        });
      });
    }
    /* End of versions for setting up with the widget */
    preview.renderDocumentPreview({
      url: auth.resourceToken,
      name: agreementName,
      href: documentUrl,
      hasPdfPreview: true,
      uid: agreementId,
      historyItems: historyItems,
      versions: versions
    });
    if (showHistoryView) {
      preview.history.setHistoryItems(Object.assign([], historyItems));
      preview.renderHistoryView({
        historyItems: Object.assign([], historyItems)
      });
    }

    this.registerEvent('closeWindow', $A.getCallback(function () {
      $A.get('e.force:refreshView').fire();
    }));

    this.registerEvent('viewCompareDocumentPreview', $A.getCallback(function (event) {
      componentHelper.fireCompareAgreements(component, componentHelper, preview, event.detail.originalDocumentHref, event.detail.compareVersionHref);
    }));

    this.registerEvent('viewDocumentPreview', $A.getCallback(function () {
      var uiHelper = component.get('v.uiHelper');
      component.set('v.loading', true);
      componentHelper.getResourceToken(component.get('v.agreement').id.value, component, uiHelper)
        .then(function (token) {
            preview.renderDocumentPreview({
              url: token,
              hasPdfPreview: true,
            });
          }
        )
        .catch(function (error) {
            uiHelper.showToast(error, 'error');
          }
        )
        .finally(function () {
          component.set('v.loading', false);
        });
    }));
    return preview;
  },

  fireCompareAgreements: function (component, helper, preview, originalDocumentHref, compareVersionHref) {
    component.set('v.loading', true);
    var compareAction = component.get('c.compareAgreements');
    compareAction.setParams({
      originalDocumentHref: originalDocumentHref,
      compareVersionHref: compareVersionHref
    });

    compareAction.setCallback(this, $A.getCallback(function (response) {
      component.set('v.loading', false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        preview.renderDocumentPreview({
          url: response.getReturnValue(),
          hasPdfPreview: true,
        });
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    }));
    $A.enqueueAction(compareAction);
  },

  externalReviewSenderView: function (component, widget, inProgress) {
    var thisComponent = component;
    var self = this;
    var agreement = component.get('v.agreement');

    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';

    this.registerEvent('resendExternalReviewRequest', $A.getCallback(function () {
      self.externalReviewResendRequest(thisComponent, self, 'ExternalReview');
    }));

    this.registerEvent('externalReviewCompleteOnBehalf', $A.getCallback(function (event) {

      self.externalReviewOnBehalfOfRequest(thisComponent, self, event);
    }));

    this.registerEvent('cancelExternalReview', $A.getCallback(function () {
      self.cancelRequest(thisComponent, self, 'ExternalReview');
    }));

    widget.renderExternalReviewSenderView({
      subTitle: 'Document sent for External Review',
      showCompleteExternalReview: inProgress,
      showCancel: inProgress,
      showResendRequest: inProgress,
      documentUid: agreement.id.value
    });
    return widget;
  },

  approvalSenderView: function (component, widget, inProgress, isAdminUser) {
    var thisComponent = component;
    var self = this;
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';
    var agreementApprovalUsers = [];
    var approvalWorkItems = component.get('v.approvalWorkItems');
    approvalWorkItems.forEach(function (workItem) {
      var approvalUser = {
        'href': workItem.workItemUrl,
        'name': stringUtils.format('{0} {1}', workItem.firstName, workItem.lastName)
      };
      agreementApprovalUsers.push(approvalUser);
    });

    this.registerEvent('approveOnBehalf', $A.getCallback(function (event) {
      var selectedWorkItemId;
      approvalWorkItems.forEach(function (workItem) {
        if (event.detail.selectedWorkitem === workItem.workItemUrl) {
          selectedWorkItemId = workItem.workItemId.value;
        }
      });
      if (!$A.util.isEmpty(selectedWorkItemId)) {
        self.completeInternalApproval(thisComponent, self, event.detail.response, event.detail.comments, selectedWorkItemId);
      }
    }));

    this.registerEvent('cancelApproval', $A.getCallback(function () {
      self.cancelRequest(thisComponent, self, 'Approval');
    }));

    this.registerEvent('resendApprovalRequest', $A.getCallback(function () {
      self.externalReviewResendRequest(thisComponent, self, 'Approval');
    }));

    widget.renderApprovalSenderView({
      subTitle: 'Document sent for Internal Approval',
      showCancel: inProgress,
      showResendRequest: inProgress,
      showOnBehalf: isAdminUser,
      approvalUsers: agreementApprovalUsers
    });
    return widget;
  },

  renderApprovalRecipientView: function (component, widget, title, message) {
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';
    var thisComponent = component;
    var self = this;

    this.registerEvent('recipientResponse', $A.getCallback(function (event) {
      var approvalWorkItemId;
      var agreementApprovalWorkItems = thisComponent.get('v.approvalWorkItems');
      agreementApprovalWorkItems.forEach(function (workItem) {
        if (component.get('v.currentUserEmail') === workItem.email) {
          approvalWorkItemId = workItem.workItemId.value;
        }
      });
      if (!$A.util.isEmpty(approvalWorkItemId)) {
        self.completeInternalApproval(thisComponent, self, event.detail.response, event.detail.comments, approvalWorkItemId);
      }
    }));

    widget.renderApprovalRecipientView({
      title: title || '',
      message: message || ''
    });
    return widget;

  },

  reloadPreview: function (component) {
    var evt = component.getEvent('loadingEvent');
    evt.setParams({
      isLoading: true
    });
    evt.fire();
  },

  isValidWidget: function (widget) {
    return widget && widget instanceof SpringCM.Widgets.Preview;
  },

  registerEvent: function (name, callback) {
    document.addEventListener('springcm:preview:' + name, callback);
  },

  isCurrentUserSender: function (component, agreement) {
    var returnValue = false;
    var AgreementStatusTypes = component.get('v.AgreementStatusTypes');
    var currentAgreementStatus = agreement.status.toUpperCase();
    var isPending = currentAgreementStatus === AgreementStatusTypes.PENDING_APPROVAL || currentAgreementStatus === AgreementStatusTypes.PENDING_REVIEW;
    if (isPending && !$A.util.isEmpty(agreement.historyItems)) {
      var pendingHistoryItem = agreement.historyItems.find(function (item) {
        return item.historyItemType === historyItemTypes.ApprovalCheckout || item.historyItemType === historyItemTypes.ExternalReviewInitiated;
      });

      if (!$A.util.isEmpty(pendingHistoryItem) && !$A.util.isEmpty(pendingHistoryItem.actor)) {
        if (component.get('v.currentUserEmail') === pendingHistoryItem.actor.email) {
          returnValue = true;
        }
      }
    }
    return returnValue;
  },

  isCurrentUserRecipientForApproval: function (component, agreement) {
    var returnValue = false;
    var AgreementStatusTypes = component.get('v.AgreementStatusTypes');
    if (agreement.status.toUpperCase() === AgreementStatusTypes.PENDING_APPROVAL &&
      !$A.util.isEmpty(agreement.historyItems)) {

      var approvalCheckoutHistoryItem = agreement.historyItems.find(function (item) {
        return item.historyItemType === historyItemTypes.ApprovalCheckout;
      });

      if (!$A.util.isEmpty(approvalCheckoutHistoryItem) &&
        Array.isArray(approvalCheckoutHistoryItem.recipients)) {
        approvalCheckoutHistoryItem.recipients.forEach(function (recipient) {
          if (component.get('v.currentUserEmail') === recipient.email) {
            returnValue = true;
          }
        });
      }
    }
    return returnValue;
  },

  hasCurrentApprovalRecipientResponded: function (component, agreement) {
    var isCurrentUserApprovalRecipient = this.isCurrentUserRecipientForApproval(component, agreement);
    if (isCurrentUserApprovalRecipient) {
      for (var index = 0; index < agreement.historyItems.length && agreement.historyItems[index].historyItemType !== historyItemTypes.ApprovalCheckout; index++) {
        var currentHistoryItem = agreement.historyItems[index];
        if (currentHistoryItem.historyItemType === historyItemTypes.CompletedHumanActivity &&
          !$A.util.isEmpty(currentHistoryItem.actor) &&
          component.get('v.currentUserEmail') === currentHistoryItem.actor.email) {
          return true;
        }
      }
    }
    return false;
  },

  externalReviewResendRequest: function (component, helper, reviewType) {
    component.set('v.loading', true);
    var agreement = component.get('v.agreement');

    var resendAction = component.get('c.resendRequest');
    resendAction.setParams({
      documentHref: agreement.href,
      resendEmailType: reviewType
    });

    resendAction.setCallback(this, function (response) {
      component.set('v.loading', false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resendMessage = '';
        if (reviewType === 'ExternalReview') {
          resendMessage = stringUtils.format($A.get('$Label.c.AgreementResendExternalReviewMessage_1'), agreement.name);
        } else {
          resendMessage = stringUtils.format($A.get('$Label.c.AgreementResendInternalApprovalMessage_1'), agreement.name);
        }
        helper.showToast(component, resendMessage, 'success');
        helper.reloadPreview(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(resendAction);
  },

  cancelRequest: function (component, helper, reviewType) {
    component.set('v.loading', true);
    var agreement = component.get('v.agreement');

    var cancelAction = component.get('c.cancelApprovalOrExternalReview');
    cancelAction.setParams({
      documentId: agreement.id.value
    });

    cancelAction.setCallback(this, function (response) {
      component.set('v.loading', false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        var cancelMessage = '';
        if (reviewType === 'ExternalReview') {
          cancelMessage = stringUtils.format($A.get('$Label.c.AgreementCancelExternalReviewMessage_1'), agreement.name);
        } else {
          cancelMessage = stringUtils.format($A.get('$Label.c.AgreementCancelInternalApprovalMessage_1'), agreement.name);
        }
        helper.showToast(component, cancelMessage, 'success');
        helper.reloadPreview(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(cancelAction);
  },

  completeInternalApproval: function (component, helper, approvalResponseType, approvalResponseComments, approvalWorkItemId) {
    component.set('v.loading', true);

    var approvalAction = component.get('c.approveOnBehalfOrRecipientResponse');
    approvalAction.setParams({
      comment: approvalResponseComments,
      itemResponse: approvalResponseType,
      workItemsId: approvalWorkItemId
    });

    approvalAction.setCallback(this, function (response) {
      component.set('v.loading', false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        if (approvalResponseType === true) {
          helper.showToast(component, $A.get('$Label.c.AgreementApprovalResponseSuccess'), 'success');
        } else {
          helper.showToast(component, $A.get('$Label.c.AgreementRejectionResponseSuccess'), 'success');
        }
        helper.reloadPreview(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(approvalAction);
  },

  externalReviewOnBehalfOfRequest: function (component, helper, event) {
    component.set('v.loading', true);

    var comments = (event.detail && event.detail.comments) ? event.detail.comments : '';
    var documentHref = (event.detail && event.detail.documentHref) ? event.detail.documentHref : '';
    var agreement = component.get('v.agreement');

    var externalReviewOnBehalfOfAction = component.get('c.externalReviewOnBehalfOfRequest');
    externalReviewOnBehalfOfAction.setParams({
      comment: comments,
      newVersionUrl: documentHref,
      documentId: agreement.id.value
    });

    externalReviewOnBehalfOfAction.setCallback(this, function (response) {
      component.set('v.loading', false);
      var state = response.getState();
      if (state === 'SUCCESS') {
        helper.showToast(component, $A.get('$Label.c.AgreementExternalReviewOnBehalfOfSuccess'), 'success');
        helper.reloadPreview(component);
      } else {
        helper.showToast(component, stringUtils.getErrorMessage(response), 'error');
      }
    });
    $A.enqueueAction(externalReviewOnBehalfOfAction);
  },

  showToast: function (component, message, mode) {
    var evt = component.getEvent('toastEvent');
    evt.setParams({
      show: true,
      message: message,
      mode: mode
    });
    evt.fire();
  }
});
