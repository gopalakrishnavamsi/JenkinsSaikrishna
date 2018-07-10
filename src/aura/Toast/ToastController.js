({
    close: function(component, event, helper) {
    	component.set('v.showToast', false);
    },
    show: function(component, event, helper) {
    	component.set('v.showToast', true);
    },
    toggleToast: function(component, event, helper) {
    	var toast = component.find('toast').getElement();
    	$A.util.toggleClass(toast, 'ds-toast_shown');
    	if(component.get('v.inVfPage')) {
    		$A.util.toggleClass(toast, 'ds-toast_vf');
    	}
    }
})