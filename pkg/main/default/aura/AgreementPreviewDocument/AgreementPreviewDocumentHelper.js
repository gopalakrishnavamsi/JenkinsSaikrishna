({
    loadWidget: function(component, agreement, documentUrl, historyItems) {
        try {
            var widget = this.resolvePreview(
              this.baseOptions(component),
              agreement,
              documentUrl,
              true //TODO: Add Support for Non-Admin users
            );
            component.set('v.widget', widget);
        } catch (err) {
            uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
        }
    },

    baseOptions: function(component) {
      return {
        iconPath: $A.get('$Resource.scmwidgetsspritemap'),
        accessTokenFn: this.getAccessToken.bind(component),
        uploadApiBaseDomain: "https://apiuploadna11.springcm.com",
        downloadApiBaseDomain: "https://apidownloadna11.springcm.com"        
      };
    },

    getAccessToken: function(component) {
        var action = component.get('c.generateUploadToken');
        var sourceId = component.get('c.sourceId');
        return new Promise(function(resolve, reject) {
            action.setParams({
                objectId: sourceId
            });
            action.setCallback(this, function(response) {
              var state = response.getState();
              if (state === 'SUCCESS') resolve(response.getReturnValue());
              if (state === 'ERROR') reject(uiHelper.getErrorMessage(response));
            });
            $A.enqueueAction(action);
        });
    },

    resolvePreview: function(auth, agreement, documentUrl, isAdmin, isSender) {
        switch (agreement.status) {
            case 'New' || 'New Version' || 'Completed' || 'Approved' || 'Rejected' || 'Approval Canceled' || 'Review Canceled' || 'Reviewed':
                return this.basePreview(agreement.id, agreement.name, documentUrl, true, auth);

            case 'Pending Review':
                return this.externalReviewSenderView(this.basePreview(agreement.id, agreement.name, documentUrl, true, auth), isAdmin);

            case 'Review Expired':
                return this.basePreview(agreement.id, agreement.name, documentUrl, false, auth);

            case 'Pending Approval':
                if (isSender) this.renderApprovalRecipientView(this.basePreview(agreement.id, agreement.name, documentUrl, false, auth));
                return this.approvalSenderView(this.basePreview(agreement.id, agreement.name, documentUrl, agreement.historyItems true, auth));

            default:
                return this.basePreview(agreement.id, agreement.name, documentUrl, false, auth);
        }
    },

    basePreview: function(agreementId, agreementName, documentUrl, historyItems, showHistoryView, auth) {
        if (!agreement || !documentUrl || !auth) throw 'Missing Parameter';
        var preview = new SpringCM.Widgets.Preview(auth);
        preview.render();
        preview.renderDocumentPreview({
            name: agreementName,
            href: documentUrl,
            hasPdfPreview: true,
            uid: agreementId
        });
        if (showHistoryView) {
            preview.history.setHistoryItems(Object.assign([], agreements.historyItems));
            preview.renderHistoryView(Object.assign([], agreements.historyItems));
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