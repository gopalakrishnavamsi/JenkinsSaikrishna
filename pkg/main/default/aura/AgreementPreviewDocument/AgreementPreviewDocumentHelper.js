({
    loadWidget: function(component, id, documentUrl, documentName, historyItems) {
        try {
        	var uiHelper = component.get('v.uiHelper');
            var widget = new SpringCM.Widgets.Preview({
                iconPath: $A.get('$Resource.scmwidgetsspritemap'),
                accessTokenFn: this.getAccessToken.bind(component),
                uploadApiBaseDomain: "https://apiuploadna11.springcm.com",
                downloadApiBaseDomain: "https://apidownloadna11.springcm.com"
            });
            widget.render('#agreementDocumentView');
            widget.renderDocumentPreview({
                name: documentName,
                href: documentUrl,
                hasPdfPreview: true,
                uid: id
            });
            widget.history.setHistoryItems(Object.assign([], historyItems));
            component.set('v.widget', widget);
        } catch (err) {
        	uiHelper.showToast(err, uiHelper.ToastMode.ERROR);
        }
    },

    //FixMe: Refrence Server side action for getting AccessToken and resolve the results. 
    getAccessToken: function(component) {
        return new Promise(function(resolve) {
            resolve('12345667');
        });
    }
})