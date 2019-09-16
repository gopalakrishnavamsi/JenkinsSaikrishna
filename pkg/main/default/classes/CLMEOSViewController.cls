public with sharing class CLMEOSViewController {      	
    public String hostingUrl{set;get;}
    public Boolean mappingExists{set;get;}
    public Boolean connectionError{set;get;}    
    public String objectType{set;get;}
    
    //Constructor called from VF page - CLMEOSView.page
    public CLMEOSViewController() {
        try {
            Permissions.verifyIsClmUser();
            hostingUrl = '';
            Id sid = System.currentPageReference().getParameters().get('sid');
            if (sid != NULL) {
                DescribeSObjectResult objDetails = MetadataService.getObject(sid);
                if (objDetails != NULL) {
                    objectType = objDetails.getName();            
                    EOSUrlResult eosRes = fetchUrl(sid);
                        if (eosRes.mappingExists) {
	                        hostingUrl= eosRes.eosUrl;
                            mappingExists=true;
                            connectionError = false;                                                           
                        } else {
							mappingExists = false;
                            connectionError = false;
                        }
                }                
            }
        } catch (Exception ex) {
            LoggerService.getInstance().exception(ex, 'Failed to fetch clm Url');
            connectionError = true;
            mappingExists = false;
        }        
    }    

    @AuraEnabled
    public static EOSUrlResult getEOSUrl(Id recordId){
        try {
        	return fetchUrl(recordId);    
        } catch (Exception ex) {
            LoggerService.getInstance().exception(ex, 'Failed to fetch clm Url');
            return new EOSUrlResult(true,false,null);
        }                            
    }
    
    public class EOSUrlResult {
        @AuraEnabled
        public final Boolean connectionError{private set;get;}
        @AuraEnabled
        public final Boolean mappingExists{private set;get;}
        @AuraEnabled
        public final String eosUrl{private set;get;}
        
        public EOSUrlResult(Boolean connectionError, Boolean mappingExists, String eosUrl) {
            this.connectionError = connectionError;
            this.mappingExists = mappingExists;
            this.eosUrl = eosUrl;
        }
    }
    
    private static EOSUrlResult fetchUrl(Id recordId) {
            Permissions.verifyIsClmUser();            
            EOSUrlResult eosResult;
            EOS_Type__c config = CLMService.getCurrentMappingConfig(recordId);  
            if (config==null) {
                eosResult = new EOSUrlResult(false, false, ''); 
            } else {   
                eosResult = new EOSUrlResult(false, true, CLMService.getHostingUrl(config, recordId).toExternalForm());
            }
            return eosResult;        
    }
}