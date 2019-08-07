public with sharing class CLMMapObjectController {    
    @AuraEnabled 
    public static String getNamespace(){
        return Application.namespace;
    }
    
    @AuraEnabled
    public static Boolean removeMappedObject(String name){
        try{
            delete EOS_Type__c.getInstance(name);
            return true;
        }
        catch(Exception e){
            throw New auraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean setMappedObject(EOS_Type__c eosDetails){
        try{
            insert eosDetails;
            return true;
        }
        catch(Exception e){
            throw New auraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static Map<String, EOS_Type__c> getMappedObjectsList(){
      
		return EOS_Type__c.getAll();
    }
   
    @AuraEnabled(Cacheable=true)
    public static List<MergeObject> getAllObjects(){
        try{
            
            return MetadataService.getObjects();
           
        }
        catch(exception e){
            throw New auraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)                                        
    public static List<MergeField> getAllObjectFields(String apiName, Boolean isChild){ 
        try{
            
         
            return MetadataService.getFields(schema.getGlobalDescribe().get(apiName),isChild);
        }
        catch(exception e){
            throw New auraHandledException(e.getMessage());
        }
    }
    //Returns the record count from the custom setting
    @AuraEnabled(Cacheable=true)
    public static Integer getRecordCount(){
        return EOS_Type__c.getAll().values().size();
    }     
}