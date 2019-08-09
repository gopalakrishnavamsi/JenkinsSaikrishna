public with sharing class CLMMapObjectController {    
    @AuraEnabled 
    public static String getNamespace(){
        try {
            Permissions.verifyIsClmAdministrator();
            return Application.namespace;
        } catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }     
    }
    
    @AuraEnabled
    public static Boolean removeMappedObject(String name){
        try {
            Permissions.verifyIsClmAdministrator(); 
            delete EOS_Type__c.getInstance(name);
            return true;
        }
        catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean setMappedObject(EOS_Type__c eosDetails){
        try {
            Permissions.verifyIsClmAdministrator(); 
            insert eosDetails;
            return true;
        } catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static Map<String, EOS_Type__c> getMappedObjectsList(){
        try {
            Permissions.verifyIsClmAdministrator();
            return EOS_Type__c.getAll();
        } catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }        
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<MergeObject> getAllObjects(){
        try{
            Permissions.verifyIsDocuSignAdministrator();
            return MetadataService.getObjects();
        }
        catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)                                        
    public static List<MergeField> getAllObjectFields(String apiName, Boolean isChild){ 
        try {
            Permissions.verifyIsDocuSignAdministrator();
            return MetadataService.getFields(schema.getGlobalDescribe().get(apiName),isChild);
        } catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static Integer getRecordCount(){
        try {
            Permissions.verifyIsClmAdministrator();
            return EOS_Type__c.getAll().values().size();
        } catch (Exception e) {
            throw Controller.wrapException(e.getMessage());
        }        
    }     
}