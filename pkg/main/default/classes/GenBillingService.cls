public with sharing class GenBillingService {
  
   private static final Map<String, InvoiceRecipients> fieldAPINames = new Map<String, InvoiceRecipients> {
       	    'blng__Account__r'=> new InvoiceRecipients ('Bill To Contact (Account)','blng__Account__r.blng__BillToContact__r.email'),
            'blng__BillToContact__r'=> new InvoiceRecipients  ('Bill To Contact (Invoice)', 'blng__BillToContact__r.email'),
            'blng__Order__r'=> new InvoiceRecipients ('Bill To Contact (Order)','blng__Order__r.BillToContact.email'),
            'CreatedBy'=> new InvoiceRecipients ('Created By','createdBy.email')
   };
   public static final String INVOICE_API_NAME = 'blng__Invoice__c';
    
    @AuraEnabled
    public static Integer invoiceAutomationExists() {
        Integer invoiceAutomationCount = 0;
        /* // here need to execute countQuery on gentemplate object to get know Invoice automation exists or not.
         * if(GenTemplate__c.getSobjectType().getDescribe().fields.getMap().containsKey(MetadataAPI.NAMESPACE_PREFIX +  'IsAutomateInvoice__c'))
         *  onLoadAutomateInvoiceCount = Database.countQuery('SELECT COUNT() FROM GenTemplate__c WHERE ' + MetadataAPI.NAMESPACE_PREFIX +  'IsAutomateInvoice__c' + '= true ');
         */
		return invoiceAutomationCount;
    }
    
    @AuraEnabled
    public static void saveAutomateTemplate() {
        //WIP
        //Creating Dynamic fields and Dynamic Trigger
    }
    
   @AuraEnabled
    public static List<InvoiceRecipients> getRecipientsData() {
        DescribeSObjectResult typeDesc = null; 
        List<InvoiceRecipients> result = new  List<InvoiceRecipients>();  
        if (Salesforce.isValidSObject(INVOICE_API_NAME)){
            Schema.DescribeSobjectResult[] INVOICE_SOBJECT = Schema.describeSObjects(new List<String> { INVOICE_API_NAME });
            typeDesc = INVOICE_SOBJECT.get(0).getSObjectType().getDescribe();
        }
        List<SobjectField> sobjectFieldResults = typeDesc != null ? typeDesc.fields.getMap().values() : new List<SobjectField>();
        for (SObjectField field : sobjectFieldResults) {
            DescribeFieldResult fieldDesc = field.getDescribe();
            if(fieldAPINames.containsKey(fieldDesc.getRelationshipName())){
                result.add(fieldAPINames.get(fieldDesc.getRelationshipName()));
            }
            if(fieldDesc.getType() == Schema.DisplayType.Email){
                 result.add(
                     new InvoiceRecipients(fieldDesc.getLabel() , fieldDesc.getName()));
            }
        }
        return result;
    }
    
    public class InvoiceRecipients {
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
        @AuraEnabled
		public String variant { get; private set; }
        @AuraEnabled
		public String scope { get; private set; }
        
		public InvoiceRecipients (
			final String label,
			final String name
			) {
			this.label = label;
            this.name = name;
			this.variant = '';
			this.scope = '';
		}
	}

}