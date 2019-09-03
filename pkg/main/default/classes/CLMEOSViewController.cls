public with sharing class CLMEOSViewController {      	
    public String hostingUrl{set;get;}
    public Boolean mappingExists{set;get;}
    public Boolean connectionError{set;get;}    
    public String objectType{set;get;}
    private static final String POST_REQ_PATH = 'EOS/GetEosInformation.aspx';   
    private static final String SFOID='sfoid';
    private static final String SFON='sfon';
    private static final String SFOT='sfot';
    private static final String EOSPATH='eosPath';
    
    //Constructor called from VF page - CLMEOSView.page
    public CLMEOSViewController(){
        try{
            Permissions.verifyIsClmUser();
            String id=system.currentPageReference().getParameters().get('sid');
            objectType = MetadataService.getObject(id).getName();
            if(String.isNotEmpty(id)){
                String url=getEOSUrl((Id) id);
                hostingUrl=url;
                mappingExists=true;
                connectionError = false;
            }
        }catch(Exception ex){
            if(ex.getMessage().equals('Mapping Does Not Exist.')){
                connectionError = false;
                mappingExists = false;
            }else{
                connectionError = true;
                mappingExists = false;
            }
        }        
    }
    
    @AuraEnabled
    public static String getEOSUrl(Id recordId){
        try{
            Permissions.verifyIsClmUser();
            EOS_Type__c config = CLMService.getCurrentMappingConfig(recordId);
            if(config==null){
                throw Controller.wrapException('Mapping Does Not Exist.');            
            }else{   
                CLMService.SubstitutedParams eosValues = CLMService.substituteConfigValuesInTemplate(config, recordId); 
                QueryString queryParams =  new QueryString(new Map<String, String> {SFOID => eosValues.sfoid, SFON => eosValues.sfon, SFOT => eosValues.sfot, EOSPATH => eosValues.eosPath});
                return CLMService.getHostingUrl(recordId, POST_REQ_PATH, queryParams);                
            }
        }catch(Exception ex){
            throw Controller.wrapException(ex.getMessage());                
        }		
    }
}