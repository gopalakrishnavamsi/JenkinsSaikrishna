({
	showToast: function (component, message, mode) {
        component.set('v.message', message);
        component.set('v.mode', mode);
        component.set('v.showToast', true);
    },

	hideToast: function (component) {
        component.find('toast').close();
    }
})