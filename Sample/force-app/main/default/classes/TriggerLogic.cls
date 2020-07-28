public with sharing class TriggerLogic {
    
    public static void dynamictrigger(List<Sobject> ids) {
     list<Sobject> toUpdate = new list<Sobject>();
        Map<String, SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
        if(checkRecursive.firstRun){
            checkRecursive.firstRun=false;
            if(GLOBAL_DESCRIBE.get('blng__Invoice__c') != null){
                for(Sobject c : Database.Query('SELECT Id,blng__InvoiceStatus__c,blng__Notes__c FROM blng__Invoice__c WHERE Id IN : ids')){
                    if(c.get('blng__InvoiceStatus__c') !=null) {
                        c.put('blng__Notes__c' , 'rest api trigsssger');
                    }
                    toUpdate.add(c);
                }
            }
            update toUpdate;
        }      
        
    }
}