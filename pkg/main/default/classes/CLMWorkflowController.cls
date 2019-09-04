public with sharing class CLMWorkflowController {
    
    @AuraEnabled
    public static String getWorkflowButtonLink() {
        try {
            Permissions.verifyIsClmUser();
            Url workflowUrl =  CLMService.getWorkflowLink();                
            return workflowUrl.toExternalForm();                           
        } catch (Exception ex) {
            throw Controller.wrapException(ex, 'getWorkflowButtonLink: Failed to fetch Document Generation configuration Url');                
        }		
    }
}