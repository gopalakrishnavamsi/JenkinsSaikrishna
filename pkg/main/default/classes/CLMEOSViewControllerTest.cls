@isTest
private class CLMEOSViewControllerTest {
	
	@testSetup static void setup(){
		Schema.Account a = TestUtils.createAccount();
		Schema.Contact c = TestUtils.createContact(a.Id);
	}
	 
	@IsTest
	static void test_constructor_valid() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createClmUser()){			
			EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.FolderName__c = '{!Account.Name}';
			eos.Path__c = 'Salesforce/Account/{!Account.Phone}/';
			eos.PathFormat__c= 'Salesforce/Account/{0}/';
			eos.Variables__c = 'Account.Phone';
			eos.Name = 'Account';
			insert eos;
			Id acctId = [SELECT Id FROM Account WHERE Name='UNIT TEST' LIMIT 1].Id;
			Test.setCurrentPageReference(new PageReference('Page.CLMEOSView')); 
			Test.startTest();
			System.currentPageReference().getParameters().put('sid', acctId);            
			System.assertNotEquals(null, new CLMEOSViewController());
			Test.stopTest();
		}        
	}    			 
	
	@IsTest
	static void test_constructor_inValid() {
		System.runAs(UserMock.createClmUser()){
			Test.startTest();
			try{
				Test.setCurrentPageReference(new PageReference('Page.CLMEOSView')); 
				System.currentPageReference().getParameters().put('sid', '');            
			}catch(AuraHandledException ae){
				System.assertNotEquals(null, ae);
			}  
			Test.stopTest();
		}        
	}    
		
	@IsTest
	static void test_getEOSUrl_unauthorized(){
		System.runAs(UserMock.createUser()){            
			Test.startTest();
			try{
				Id acctId = [SELECT Id FROM Account WHERE Name='UNIT TEST' LIMIT 1].Id;
				String result = CLMEOSViewController.getEOSUrl(acctId);
				throw new AssertException('Expected failure when fetching eos url.');   
			}catch(AuraHandledException ae){
				System.assertNotEquals(null, ae);
			}  
			Test.stopTest();
		}
	}  
	
	@IsTest
	static void test_getEOSUrl_authorized_mapping_does_not_exist(){
		System.runAs(UserMock.createClmUser()){            
			Test.startTest();
			try{
				Id acctId = [SELECT Id FROM Account WHERE Name='UNIT TEST' LIMIT 1].Id;
				String result = CLMEOSViewController.getEOSUrl(acctId);
				
				throw new AssertException('Expected failure when fetching eos url.');   
			}catch(AuraHandledException ae){
				System.assertNotEquals(null, ae);
			}  
			Test.stopTest();
		}
	}    
	
	@IsTest
	static void test_getEOSUrl_authorized_mapping_exists(){
		DocuSignAPIMock.success();
		System.runAs(UserMock.createClmUser()){            
			
			Id contactId = [SELECT Id FROM Contact  LIMIT 1].Id;
			EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.FolderName__c = '{!Contact.LastName}';
			eos.Path__c = 'Salesforce/Account/{!Account.Phone}/Contact/';
			eos.PathFormat__c= 'Salesforce/Account/{0}/Contact/';
			eos.Variables__c = 'Account.Phone';
			eos.Name = 'Contact';
			insert eos;
			Test.startTest();
			String result = CLMEOSViewController.getEOSUrl(contactId);
			Test.stopTest();              
		}
	}    	
}