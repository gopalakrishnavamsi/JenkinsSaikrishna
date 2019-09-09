({
	afterRender: function (component) {
		this.superAfterRender();
		var iframe = component.find('frame');
		if (iframe && iframe.getElement()) {
			var iframeWin = iframe.getElement();
			var frameHeight = Math.max(
				iframeWin.scrollHeight || 0,
				iframeWin.offsetHeight || 0,
				iframeWin.clientHeight || 0
			);
			var content = iframeWin.contentWindow || iframeWin.contentDocument;
			var contentHeight = Math.max(
				content.parent.innerHeight || 0,
				content.parent.outerHeight || 0
			);
			component.set('v.frameHeight', Math.max(contentHeight, frameHeight, 350));
		}
	},

	rerender: function (component) {
		this.superRerender();
		var iframe = component.find('frame');
		if (iframe && iframe.getElement()) {
			var iframeWin = iframe.getElement();
			var frameHeight = Math.max(
				iframeWin.scrollHeight || 0,
				iframeWin.offsetHeight || 0,
				iframeWin.clientHeight || 0
			);
			var content = iframeWin.contentWindow || iframeWin.contentDocument;
			var contentHeight = Math.max(
				content.parent.innerHeight || 0,
				content.parent.outerHeight || 0
			);
			var height = Math.max(contentHeight, frameHeight, 150);
			if (component.get('v.frameHeight') < height) {
				component.set('v.frameHeight', height);
			}
		}
	}
});