public with sharing class CLMMapObjectController {

    @auraEnabled 
    public static String getNamespace(){
        return Application.namespace;
    }
    @AuraEnabled
    public static String getMappedObjectsList(){
        return '['+
            '{"objectName": "Account", "folderName": "{!Account.Name}", "path": "/Salesforce/Accounts/","Id":"1"},'+
            '{"objectName": "Opportunity", "folderName": "{!Opportunity.Name}", "path": "/Salesforce/Accounts/{!Account.Name}/Opportunities","Id":"2"}'+
            ']';
    }
    //TODO: Change below method to use MergeObject instead of AllObjects
    @AuraEnabled(Cacheable=true)
    public static List<AllObjects> getAllObjects(){
        List<AllObjects> returnValue=new List<AllObjects>();
        for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
        {
            Schema.DescribeSObjectResult objResult = o.getDescribe();
            returnValue.add(new AllObjects(objResult.getLabel(),objResult.getName()));
            
        }
        return returnValue;
    }
    //TODO: Change below method to use MergeObject instead of AllObjects
    @AuraEnabled(Cacheable=true)
    public static List<AllObjects> getAllObjectFileds(String apiName){ 
        List<AllObjects> returnValue=new List<AllObjects>();
     	Map<string,SObjectField> fList = schema.getGlobalDescribe().get(apiName).getDescribe().fields.getMap();
        for(string str: fList.keySet()){
            returnValue.add(new AllObjects(fList.get(str).getDescribe().getLabel(),str));
        }
        return returnValue;
    }
    
    public class AllObjects{
        @AuraEnabled
        public String name;
        @AuraEnabled 
        public String apiName;
        @AuraEnabled 
        public Boolean selected;
        public AllObjects(String name,String apiName){
            this.name=name;
            this.apiName=apiName;
            selected=false;            
        }
    }    
}