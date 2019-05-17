({
    loadWidget: function(component, agreement, documentUrl) {
        try {
            var uiHelper = component.get('v.uiHelper');
            var self = this;
            this.baseOptions(component, component.get('v.sourceId')).then(function(options) {
              var widget = self.resolvePreview(
                options,
                agreement,
                documentUrl,
                true //TODO: Add Support for Non-Admin users
              );
              component.set('v.widget', widget);              
            }).catch(function(err) {         
              uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
            });
        } catch (err) {
            uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
        }
    },

    baseOptions: function(component, sourceId) {
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
            resolve(Object.freeze({
              iconPath: $A.get('$Resource.scmwidgetsspritemap'),
              accessTokenFn: self.getAccessToken.bind(self, component, sourceId),
              uploadApiBaseDomain: token.apiBaseUrl,
              downloadApiBaseDomain: "https://apidownloadna11.springcm.com"      
            }));
          }
          if (state === 'ERROR') reject(uiHelper.getErrorMessage(response));
        });   
        $A.enqueueAction(action);    
      });
    },

    getAccessToken: function(component, sourceId) {
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
            case 'new' || 'new version' || 'completed' || 'approved' || 'rejected' || 'approval canceled' || 'review canceled' || 'reviewed':
                return this.basePreview(agreement.id.value, agreement.name, documentUrl, agreement.historyItems, true, auth);

            case 'pending review':
                return this.externalReviewSenderView(this.basePreview(agreement.id.value, agreement.name, documentUrl, agreement.historyItems, true, auth), isAdmin);

            case 'review expired':
                return this.basePreview(agreement.id.value, agreement.name, documentUrl, agreement.historyItems, false, auth);

            case 'pending approval':
                if (isSender) this.renderApprovalRecipientView(this.basePreview(agreement.id.value, agreement.name, documentUrl, agreement.historyItems, false, auth));
                return this.approvalSenderView(this.basePreview(agreement.id.value, agreement.name, documentUrl, agreement.historyItems, true, auth));

            default:
                return this.basePreview(agreement.id.value, agreement.name, documentUrl, agreement.historyItems, false, auth);
        }
    },

    basePreview: function(agreementId, agreementName, documentUrl, historyItems, showHistoryView, auth) {
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
            preview.renderHistoryView({ historyItems: Object.assign([], historyItems) });
        }
        return preview;
    },

    externalReviewSenderView: function(widget, isCompleted) {
        if (!widget || widget.prototype !== SpringCM.Widgets.Preview) throw 'Invalid Widget';

        widget.renderExternalReviewSenderView({
            subTitle: "",
            showCompleteExternalReview: isCompleted,
            showCancel: true,
            showResendRequest: true
        });
        return widget;
    },

    approvalSenderView: function(widget) {
        if (!widget || widget.prototype !== SpringCM.Widgets.Preview) throw 'Invalid Widget';

        widget.renderApprovalSenderView({
            subTitle: "",
            showCancel: true,
            showResendRequest: true,
            showOnBehalf: false,
            approvalUsers: []
        });
        return widget;
    },

    renderApprovalRecipientView: function(widget, title, message) {
        if (!widget || widget.prototype !== SpringCM.Widgets.Preview) throw 'Invalid Widget';

        widget.renderApprovalRecipientView({
            title: title || '',
            message: message || ''
        });
        return widget;
    }
});