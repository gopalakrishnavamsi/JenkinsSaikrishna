trigger DynamicInv on blng__Invoice__c (after update) {
    list<blng__Invoice__c> toUpdate = new list<blng__Invoice__c>();
    if(CheckRecursive.firstRun) {
        CheckRecursive.firstRun=false;
        for(blng__Invoice__c c : [SELECT Id,blng__InvoiceStatus__c,blng__Notes__c  FROM blng__Invoice__c WHERE Id IN :Trigger.new]){
            if(c.blng__InvoiceStatus__c == 'Posted') {
                c.blng__Notes__c = ' Posted Updating value thorugh Trigger';       
            } 
            toUpdate.add(c);
        }
    update toUpdate; 
    }
}