trigger DynamicTrigger on blng__Invoice__c(after update){
	TriggerLogic.dynamictrigger(Trigger.new);		
}