public with sharing class CLMMapObjectController {
    
    @AuraEnabled
    public static String getMappedObjectsList(){
        return '['+
            '{"objectName": "Account", "folderName": "{!Account.Name}", "path": "/Salesforce/Accounts/","Id":"1"},'+
            '{"objectName": "Opportunity", "folderName": "{!Opportunity.Name}", "path": "/Salesforce/Accounts/{!Account.Name}/Opportunities","Id":"2"}'+
            ']';
    }

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
    
    @AuraEnabled(Cacheable=true)
    public static List<AllObjects> getAllObjectFileds(String objApiName){
        List<AllObjects> returnValue=new List<AllObjects>();
     	Map<string,SObjectField> fList = schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();
        for(string str: fList.keySet()){
            returnValue.add(new AllObjects(fList.get(str).getDescribe().getLabel(),str));
        }
        return returnValue;
    }
    
    public class AllObjects{
        @AuraEnabled
        public String objectName;
        @AuraEnabled 
        public String objecApiName;
        @AuraEnabled 
        public Boolean selected;
        public AllObjects(String objectName,String objecApiName){
            this.objectName=objectName;
            this.objecApiName=objecApiName;
            selected=false;            
        }
    }    
}