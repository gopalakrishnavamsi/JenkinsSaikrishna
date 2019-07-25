/*
*/
public with sharing class CLMMapObjectController {
    
    /*Returns all mapped objects 
*/
    @auraEnabled
    public static String getMappedObjectsList(){
        return '['+
            '{"objectName": "Account", "folderName": "{!Account.Name}", "path": "/Salesforce/Accounts/","Id":"1"},'+
            '{"objectName": "Opportunity", "folderName": "{!Opportunity.Name}", "path": "/Salesforce/Accounts/{!Account.Name}/Opportunities","Id":"2"}'+
            ']';
    }
    @auraEnabled(cacheable=true)
    public static List<allObjectsWrapper> getAllObjects(){
        List<allObjectsWrapper> returnValue=new List<allObjectsWrapper>();
        for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
        {
            Schema.DescribeSObjectResult objResult = o.getDescribe();
            returnValue.add(new allObjectsWrapper(objResult.getLabel(),objResult.getName()));
            
        }
        return returnValue;
    }
    
    @auraEnabled(cacheable=true)
    public static List<allObjectsWrapper> getAllObjectFileds(String objApiName){
        List<allObjectsWrapper> returnValue=new List<allObjectsWrapper>();
     	Map<string,SObjectField> fList = schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();
        for(string str: fList.keySet()){
            returnValue.add(new allObjectsWrapper(fList.get(str).getDescribe().getLabel(),str));
        }
        return returnValue;
    }
    
    public class allObjectsWrapper{
        @auraEnabled
        public String objectName;
        @auraEnabled 
        public String objecApiName;
        @auraEnabled 
        public Boolean selected;
        public allObjectsWrapper(String objectName,String objecApiName){
            this.objectName=objectName;
            this.objecApiName=objecApiName;
            selected=false;
            
        }
    }
    
}