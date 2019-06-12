({
  onLoad: function (component, event, helper) {
    var uiHelper = component.get('v.uiHelper');
    var action = component.get('c.getDocumentURL');
    var agreement = component.get('v.agreement');
    action.setParams({
      documentId: agreement.id.value
    });
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') helper.loadWidget(component, agreement, response.getReturnValue());
      if (response.getState() === 'ERROR') uiHelper.showToast(uiHelper.getErrorMessage(response), uiHelper.ToastMode.ERROR);
    });

    $A.enqueueAction(action);
  },

  loadWidget: function(component, agreement, documentUrl) {
    try {
      var uiHelper = component.get('v.uiHelper');
      var self = this;
      var isCurrentUserLatestActor = this.isCurrentUserLatestActor(component, agreement);
      var isCurrentUserRecipientForApproval = this.isCurrentUserRecipientForApproval(component, agreement);
      Promise.all(
        [   
            this.baseOptions(component, uiHelper, component.get('v.sourceId')),
            this.getResourceToken(agreement.id.value, component, uiHelper)
        ]
      )
      .then(function(tokens) {
        return Object.freeze({
            baseOptions: tokens[0],
            resourceToken: tokens[1]
        });
      })
      .then(function(options) {
        var widget = self.resolvePreview(
          component,
            options,
            agreement,
            documentUrl,
          component.get('v.currentUserDocuSignAdmin'),
          isCurrentUserLatestActor,
          isCurrentUserRecipientForApproval
          );   
          component.set('v.widget', widget);                               
       })
       .catch(function(err) {
          uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
       });      
    } catch (err) {
      uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
    }
  },

  baseOptions: function(component, uiHelper, sourceId) {
    var self = this;
    return new Promise(function(resolve, reject) {
        self.getAccessToken(component, uiHelper, sourceId, true)
        .then(function(token) {
            resolve(
                Object.freeze({
                  iconPath: $A.get('$Resource.scmwidgetsspritemap'),
                  accessTokenFn: function() {
                    return self.getAccessToken(component, uiHelper, sourceId, false);
                  },
                  uploadApiBaseDomain: token.apiUploadBaseUrl,
                  downloadApiBaseDomain: token.apiDownloadBaseUrl
                })
            );
        })
        .catch(function(err) {
            reject(err);
        });
    });
  },

  getAccessToken: function(component, uiHelper, sourceId, isSetup){
    var action = component.get('c.generateUploadToken');
    return new Promise(function(resolve, reject) {
      action.setParams({
        objectId: sourceId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          if (isSetup) resolve(response.getReturnValue());
          else resolve(response.getReturnValue().token);
        }
        if (state === 'ERROR') reject(uiHelper.getErrorMessage(response));
      });
      $A.enqueueAction(action);
    });
  },

  getResourceToken: function (agreementId, component, uiHelper) {
    var action = component.get('c.generateResourceToken');

    return new Promise(function (resolve) {
      action.setParams({
        agreementId: agreementId
      });           
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        }
        if (state === 'ERROR') {
          uiHelper.getErrorMessage(response);
          resolve('');
          //TODO: add reject once the issue with registering tokens is sorted out
          //reject(uiHelper.getErrorMessage(response));
        }
      });
      $A.enqueueAction(action);
    });
  },

  resolvePreview: function (component, auth, agreement, documentUrl, isAdmin, isSender, isApprover) {
    switch (agreement.status.toLowerCase()) {
      case 'new' ||
        'new version' ||
        'completed' ||
        'rejected' ||
        'approval canceled' ||
        'review canceled'||
      'reviewed' ||
      'review expired' ||
      'approved' :
        //render the Status + History View
        return this.basePreview(
          component,
          agreement.id.value,
          agreement.name,
          documentUrl,
          agreement.historyItems,
          true,
          auth
        );

      //External Review Pending
      case 'pending review':
        //If current user is the sender of the external review request or the current user is an admin user
        //In this case the user should be presented with the options for resending, completing and cancelling the review
        if (isSender === true || isAdmin === true)
          return this.externalReviewSenderView(
            component,
            this.basePreview(
              component,
              agreement.id.value,
              agreement.name,
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
          agreement.name,
          documentUrl,
          agreement.historyItems,
          true,
          auth
        );

      //Internal Approval pending
      case 'pending approval':
        //If current user is the sender of the Approval request but not an Admin User
        //In this case the user should be presented with the options for resending, cancelling the approval request
        if (isSender === true && isAdmin === false)
          return this.approvalSenderView(
            component,
            this.basePreview(
              component,
              agreement.id.value,
              agreement.name,
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
              agreement.name,
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
        if (isApprover === true)
          return this.renderApprovalRecipientView(
            component,
            this.basePreview(
              component,
              agreement.id.value,
              agreement.name,
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
              agreement.name,
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
          agreement.name,
          documentUrl,
          agreement.historyItems,
          true,
          auth
        );

      default:
        return this.basePreview(
          component,
          agreement.id.value,
          agreement.name,
          documentUrl,
          agreement.historyItems,
          true,
          auth
        );
    }
  },

  basePreview: function(
    component,
    agreementId,
    agreementName,
    documentUrl,
    historyItems,
    showHistoryView,
    auth
  ) {
    if (!agreementId || !documentUrl || !agreementName || !auth) throw 'Missing Parameter';
    var preview = new SpringCM.Widgets.Preview(auth.baseOptions);
    preview.render('#agreementDocumentView');
    preview.renderDocumentPreview({
      url: auth.resourceToken,
      name: agreementName,
      href: documentUrl,
      hasPdfPreview: true,
      uid: agreementId,
      historyItems: historyItems
    });
    if (showHistoryView) {

      preview.history.setHistoryItems(Object.assign([], historyItems));
      preview.renderHistoryView({
        historyItems: Object.assign([], historyItems)
      });
    }

    this.registerEvent('closeWindow', function() {
      $A.get('e.force:refreshView').fire();
    });

    return preview;
  },

  externalReviewSenderView: function (component, widget, inProgress) {
    var thisComponent = component;
    var self = this;

    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';

    this.registerEvent('resendExternalReviewRequest', $A.getCallback(function() {
      self.externalReviewResendRequest(thisComponent, self, 'ExternalReview');
    }));

    this.registerEvent('externalReviewCompleteOnBehalf', function() {
      //show the spinner and fade background
      thisComponent.set('v.loading', true);

      //capture event.detail.comments and event.detail.response

      //call Apex Action to complete review on behalf of

      //reload preview
      self.reloadPreview(thisComponent);
    });

    this.registerEvent('cancelExternalReview', function() {
      //show the spinner and fade background
      thisComponent.set('v.loading', true);

      //call Apex Action to Cancel the current external review request

      //reload preview
      self.reloadPreview(thisComponent);
    });

    widget.renderExternalReviewSenderView({
      subTitle: 'Document sent for External Review',
      showCompleteExternalReview: inProgress,
      showCancel: inProgress,
      showResendRequest: inProgress,
    });
    return widget;
  },

  approvalSenderView: function (component, widget, inProgress, isAdminUser) {
    var thisComponent = component;
    var self = this;
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';

    this.registerEvent('approveOnBehalf', function() {
      //show the spinner and fade background
      thisComponent.set('v.loading', true);

      //capture event.detail.comments and event.detail.response

      //call Apex Action to Approve the user record on Behalf of

      //reload preview
      self.reloadPreview(thisComponent);

    });

    this.registerEvent('cancelApproval', function() {
      //show the spinner and fade background
      thisComponent.set('v.loading', true);

      //call Apex Action to Cancel the current Approval request

      //reload preview
      self.reloadPreview(thisComponent);
    });

    this.registerEvent('resendApprovalRequest', $A.getCallback(function() {
      self.externalReviewResendRequest(thisComponent, self, 'Approval');
    }));

    widget.renderApprovalSenderView({
      subTitle: 'Document sent for Internal Approval',
      showCancel: inProgress,
      showResendRequest: inProgress,
      showOnBehalf: isAdminUser,
      approvalUsers: []
    });
    return widget;
  },

  renderApprovalRecipientView: function (component, widget, title, message) {
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';
    var thisComponent = component;
    var self = this;
    this.registerEvent('recipientResponse', function() {
      //show the spinner and fade background
      thisComponent.set('v.loading', true);

      //capture event.detail.comments and event.detail.response

      //call Apex Action to record user response and update worktItem

      //reload preview
      self.reloadPreview(thisComponent);

    });


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

  isValidWidget: function(widget) {
    return widget && widget instanceof SpringCM.Widgets.Preview;
  },

  registerEvent: function(name, callback) {
    document.addEventListener('springcm:preview:' + name, callback);
  },

  isCurrentUserLatestActor: function (component, agreement) {
    var returnValue = false;

    if (!$A.util.isEmpty(agreement.historyItems) &&
      !$A.util.isEmpty(agreement.historyItems[0].actor)) {
      if (component.get('v.currentUserEmail') === agreement.historyItems[0].actor.email) {
        returnValue = true;
      }
    }
    return returnValue;
  },

  isCurrentUserRecipientForApproval: function (component, agreement) {
    var returnValue = false;

    if (agreement.status.toLowerCase() === 'pending approval' &&
      !$A.util.isEmpty(agreement.historyItems) &&
      !$A.util.isEmpty(agreement.historyItems[0].recipients)) {

      agreement.historyItems[0].recipients.forEach(function (recipient) {
        if (component.get('v.currentUserEmail') === recipient.email) {
          returnValue = true;
        }
      });
    }
    return returnValue;
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
      component.set('v.loading', true);
      var state = response.getState();
      if (state === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result === true) {
          var resendMessage = '';
          if(reviewType === 'ExternalReview') {
            resendMessage = stringUtils.format('{0} {1}', agreement.name, $A.get('$Label.c.AgreementResendExternalReviewMessage'));
          } else {
            resendMessage = stringUtils.format('{0} {1}', agreement.name, $A.get('$Label.c.AgreementResendInternalApprovalMessage'));
          }
          helper.showToast(component, resendMessage, 'success');
        } else {
          helper.showToast(component, $A.get('$Label.c.AgreementResendErrorMessage'), 'error');
        }
      } else {
        helper.showToast(component, $A.get('$Label.c.AgreementResendErrorMessage'), 'error');
      }
      helper.reloadPreview(component);
    });
    $A.enqueueAction(resendAction);
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