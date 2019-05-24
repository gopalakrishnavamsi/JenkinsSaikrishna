({
  loadWidget: function(component, agreement, documentUrl) {
    try {
      var uiHelper = component.get('v.uiHelper');
      var self = this;
      this.baseOptions(component, uiHelper, component.get('v.sourceId'))
        .then(function(options) {
          var widget = self.resolvePreview(
            options,
            agreement,
            documentUrl,
            true //TODO: Add Support for Non-Admin users
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
    var action = component.get('c.generateUploadToken');
    var self = this;
    return new Promise(function(resolve, reject) {
      action.setParams({
        objectId: sourceId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var token = response.getReturnValue();
          resolve(
            Object.freeze({
              iconPath: $A.get('$Resource.scmwidgetsspritemap'),
              accessTokenFn: self.getAccessToken.bind(
                self,
                component,
                uiHelper,
                sourceId
              ),
              uploadApiBaseDomain: token.apiBaseUrl,
              downloadApiBaseDomain: 'https://apidownloadna11.springcm.com' //FixMe: should be returned from generateToken
            })
          );
        }
        if (state === 'ERROR') reject(uiHelper.getErrorMessage(response));
      });
      $A.enqueueAction(action);
    });
  },

  getAccessToken: function(component, uiHelper, sourceId) {
    var action = component.get('c.generateUploadToken');
    return new Promise(function(resolve, reject) {
      action.setParams({
        objectId: sourceId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue().token);
        }
        if (state === 'ERROR') reject(uiHelper.getErrorMessage(response));
      });
      $A.enqueueAction(action);
    });
  },

  resolvePreview: function(auth, agreement, documentUrl, isAdmin, isSender) {
    console.log('agreement: ', agreement);
    switch (agreement.status.toLowerCase()) {
      case 'new' ||
        'new version' ||
        'completed' ||
        'rejected' ||
        'approval canceled' ||
        'review canceled':
        return this.basePreview(
          agreement.id.value,
          agreement.name,
          documentUrl,
          agreement.historyItems,
          true,
          auth
        );

      case 'reviewed':
        return this.externalReviewSenderView(
          this.basePreview(
            agreement.id.value,
            agreement.name,
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ),
          true
        );

      case 'pending review':
        return this.externalReviewSenderView(
          this.basePreview(
            agreement.id.value,
            agreement.name,
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ),
          false
        );

      case 'review expired':
        return this.basePreview(
          agreement.id.value,
          agreement.name,
          documentUrl,
          agreement.historyItems,
          false,
          auth
        );

      case 'pending approval':
        if (isSender)
          this.approvalSenderView(
            this.basePreview(
              agreement.id.value,
              agreement.name,
              documentUrl,
              agreement.historyItems,
              true,
              auth
            ),
            false
          );
        return this.renderApprovalRecipientView(
          this.basePreview(
            agreement.id.value,
            agreement.name,
            documentUrl,
            agreement.historyItems,
            false,
            auth
          )
        );

      case 'approved':
        if (isSender)
          this.approvalSenderView(t this.basePreview(
            agreement.id.value,
            agreement.name,
            documentUrl,
            agreement.historyItems,
            true,
            auth
          ), true);
        return this.renderApprovalRecipientView(
          this.basePreview(
            agreement.id.value,
            agreement.name,
            documentUrl,
            agreement.historyItems,
            false,
            auth
          )
        );

      default:
        return this.basePreview(
          agreement.id.value,
          agreement.name,
          documentUrl,
          agreement.historyItems,
          false,
          auth
        );
    }
  },

  basePreview: function(
    agreementId,
    agreementName,
    documentUrl,
    historyItems,
    showHistoryView,
    auth
  ) {
    if (!agreementId || !documentUrl || !agreementName || !auth) throw 'Missing Parameter';
    var preview = new SpringCM.Widgets.Preview(auth);
    preview.render('#agreementDocumentView');
    preview.renderDocumentPreview({
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

  externalReviewSenderView: function(widget, isCompleted) {
    if (!widget || !widget instanceof SpringCM.Widgets.Preview) throw 'Invalid Widget';

    this.registerEvent('resendExternalReviewRequest', function() {
      this.toggleSpinner(
        widget,
        false
      );
    });
    this.registerEvent('externalReviewCompleteOnBehalf', function(event) {
      //event.details contains response.
      this.toggleSpinner(
        widget,
        false
      );
    });
    this.registerEvent('cancelExternalReview', function() {
      this.toggleSpinner(widget, false);
    });

    widget.renderExternalReviewSenderView({
      subTitle: '',
      showCompleteExternalReview: isCompleted,
      showCancel: isCompleted,
      showResendRequest: isCompleted
    });
    return widget;
  },

  approvalSenderView: function(widget, isCompleted) {
    if (!widget || !widget instanceof SpringCM.Widgets.Preview) throw 'Invalid Widget';

    this.registerEvent('approveOnBehalf', function(event) {
      //event.details contains response.
      this.toggleSpinner(widget, false);
    });
    this.registerEvent('cancelApproval', function() {
      this.toggleSpinner(widget, false);
    });
    this.registerEvent('resendApprovalRequest', function() {
      this.toggleSpinner(widget, false);
    });

    widget.renderApprovalSenderView({
      subTitle: '',
      showCancel: isCompleted,
      showResendRequest: isCompleted,
      showOnBehalf: isCompleted,
      approvalUsers: []
    });
    return widget;
  },

  renderApprovalRecipientView: function(widget, title, message) {
    if (!widget || !widget instanceof SpringCM.Widgets.Preview) throw 'Invalid Widget';

    this.registerEvent('recipientResponse', function(event) {
      /**
          event.details contains response.
          {
           "comments": "Yes",
           "response": true
          }
      **/
      this.toggleSpinner(widget, false);
    });

    widget.renderApprovalRecipientView({
      title: title || '',
      message: message || ''
    });
    return widget;
  },

  registerEvent: function(name, callback) {
    document.addEventListener('springcm:preview:' + name, callback);
  },

  toggleSpinner: function(widget, isLoading) {
    widget.toggleLoadingSpinner(isLoading);
  }
});