({  
    afterRender: function(component, helper) {
        this.superAfterRender();
        
        if (!component.get('v.loggedIn')) {
            component.find('login-input').focus();
        }
    }
})