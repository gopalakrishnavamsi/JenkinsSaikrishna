({
	onInit : function(component, event, helper) {
        helper.callServer(component,'c.getNamespace',false, function(result){
            component.set('v.namespace',result);
        });
	}
})