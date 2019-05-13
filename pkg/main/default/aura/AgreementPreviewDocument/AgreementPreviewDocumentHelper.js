({
	loadWidget: function(component, id, documentUrl, documentName, historyItems) {
		try {
			console.log('payload: ', typeof documentUrl);
			var widet = new SpringCM.Widgets.Preview({
			    iconPath: $A.get('$Resource.scmwidgetsspritemap'),
			    accessTokenFn: this.getAccessToken.bind(component),
			    uploadApiBaseDomain: "https://apiuploadna11.springcm.com",
			    downloadApiBaseDomain: "https://apidownloadna11.springcm.com"
			});
			widet.render('#agreementDocumentView');
			widet.renderDocumentPreview({
		        name: documentName,
		        href: documentUrl,
		        hasPdfPreview: true,
		        uid: id
	    	});
	    	widet.history.setHistoryItems(Object.assign([],historyItems));
		} catch(err) {
			console.log('error loading preview', err);
		}
	},

	//FixMe: Refrence Server side action for getting AccessToken and resolve the results. 
	getAccessToken: function(component) {
		return new Promise(function(resolve){
			resolve('12345667');
		});
	}
})