({
  loadWidget: function(component, agreement, documentUrl) {
    try {
      var uiHelper = component.get('v.uiHelper');
      var self = this;
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

  getResourceToken: function(agreementId, component, uiHelper) {
    var action = component.get('c.generateResourceToken');
 
    return new Promise(function(resolve, reject) {
      action.setParams({
        agreementId: agreementId
      });           
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        }
        if (state === 'ERROR') reject(uiHelper.getErrorMessage(response));
      });
      $A.enqueueAction(action);        
    });
  },

  resolvePreview: function(auth, agreement, documentUrl, isAdmin, isSender) {
    switch (agreement.status.toLowerCase()) {
      case 'new' ||
        'new version' ||
        'completed' ||
        'rejected' ||
        'approval canceled' ||
        'review canceled'||
        'reviewed':
        return this.basePreview(
          agreement.id.value,
          agreement.name,
          documentUrl,
          agreement.historyItems,
          true,
          auth
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
          true
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
          return this.approvalSenderView(
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
          return this.approvalSenderView(
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
          true,
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

  externalReviewSenderView: function(widget, inProgress) {
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';

    this.registerEvent('resendExternalReviewRequest', function() {
      this.toggleSpinner(
        widget,
        false
      );
    });
    this.registerEvent('externalReviewCompleteOnBehalf', function() {
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
      showCompleteExternalReview: inProgress,
      showCancel: inProgress,
      showResendRequest: inProgress,
    });
    return widget;
  },

  approvalSenderView: function(widget, isCompleted) {
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';

    this.registerEvent('approveOnBehalf', function() {
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
    if (this.isValidWidget(widget) === false) throw 'Invalid Widget';

    this.registerEvent('recipientResponse', function() {
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

  isValidWidget: function(widget) {
    return widget && widget instanceof SpringCM.Widgets.Preview;
  },

  registerEvent: function(name, callback) {
    document.addEventListener('springcm:preview:' + name, callback);
  },

  toggleSpinner: function(widget, isLoading) {
    widget.toggleLoadingSpinner(isLoading);
  }
});