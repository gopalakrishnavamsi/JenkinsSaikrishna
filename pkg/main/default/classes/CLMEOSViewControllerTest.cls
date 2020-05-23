@IsTest
private class CLMEOSViewControllerTest {

	@testSetup static void setup() {
		Schema.Account a = TestUtils.createAccount();
		Schema.Contact c = TestUtils.createContact(a.Id);
	}

	@IsTest
	static void test_constructors() {
		System.assertNotEquals(null, new CLMEOSViewController());
	}

	@IsTest
	static void test_getEOSUrl_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			Id acctId = [SELECT Id FROM Account WHERE Name='UNIT TEST' LIMIT 1].Id;
			CLMEOSViewController.getEOSUrl(acctId);
			CLMEOSViewController.EOSUrlResult result = CLMEOSViewController.getEOSUrl(acctId);
			System.assert (result.connectionError);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEOSUrl_authorized_mapping_does_not_exist() {
		System.runAs(UserMock.createClmViewer()) {
			Test.startTest();
			Id acctId = [SELECT Id FROM Account WHERE Name='UNIT TEST' LIMIT 1].Id;
			CLMEOSViewController.EOSUrlResult result = CLMEOSViewController.getEOSUrl(acctId);
			System.assert (!result.mappingExists);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEOSUrl_authorized_mapping_exists() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createClmViewer()) {
			Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;
			EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.FolderName__c = '{!Contact.LastName}';
			eos.Path__c = 'Salesforce/Account/{!Account.Phone}/Contact/';
			eos.PathFormat__c= 'Salesforce/Account/{0}/Contact/';
			eos.Variables__c = 'Account.Phone';
			eos.Name = 'Contact';
			insert eos;
			Test.startTest();
			CLMEOSViewController.EOSUrlResult result=CLMEOSViewController.getEOSUrl(contactId);
			system.assertNotEquals(null, result.eosUrl);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEOSUrl_apiError() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createClmViewer()) {
			EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
			eos.FolderName__c = '{!Account.Name}';
			eos.Path__c = 'Salesforce/Account/{!Account.Phone}/';
			eos.PathFormat__c= 'Salesforce/Account/{0}/';
			eos.Variables__c = 'Account.Phone';
			eos.Name = 'Account';
			insert eos;
			Id acctId = [SELECT Id FROM Account WHERE Name='UNIT TEST' LIMIT 1].Id;
			Test.startTest();
			CLMEOSViewController.EOSUrlResult result=CLMEOSViewController.getEOSUrl(acctId);
			System.assert (result.connectionError);
			System.assertNotEquals(null, result.errorMessage);
			System.assert (result.errorMessage.contains('[1234]'));
			System.assert (result.errorMessage.contains('Reference ID'));
			Test.stopTest();
		}
	}

	// CLM service test
	@IsTest
	static void test_substituteConfigValuesInTemplate_success() {

		Schema.Account a = TestUtils.createAccount();
		Opportunity o1 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 10', CloseDate = Date.today(), StageName = 'Negotiation/Review');
		EOS_Type__c config = new EOS_Type__c(
			FolderNameFormat__c = '{0}',
			PathFormat__c = 'Salesforce/Opportunity/',
			Path__c = '/Salesforce/Opportunity/',
			Name = 'Opportunity',
			FolderName__c = '{!Opportunity.Name}_{!Opportunity.Id}_{!Account.Name}'
		);
		insert config;
		insert o1;

		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Test.setCurrentPageReference(new PageReference('Page.CLMEOSView'));
			System.currentPageReference().getParameters().put('sid', a.Id);
			CLMService.SubstitutedParams substitutedParams = CLMService.substituteConfigValuesInTemplate(config, o1.Id);
			Test.stopTest();
			System.assertNotEquals(null, substitutedParams);
			System.assertEquals(o1.Name+'_'+o1.Id+'_'+a.Name, substitutedParams.salesforceFolderName);
		}
	}

	@IsTest
	static void test_substituteConfigValuesInTemplate_success2() {

		Schema.Account a = TestUtils.createAccount();
		Opportunity o1 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 10', CloseDate = Date.today(), StageName = 'Negotiation/Review');
		EOS_Type__c config = new EOS_Type__c(
			FolderNameFormat__c = '{0}',
			PathFormat__c = 'Salesforce/Opportunity/',
			Path__c = '/Salesforce/Opportunity/',
			Name = 'Opportunity',
			FolderName__c = '_{!Opportunity.Description}'
		);
		insert config;
		insert o1;

		System.runAs(UserMock.createClmAdministrator()) {
			Test.startTest();
			Test.setCurrentPageReference(new PageReference('Page.CLMEOSView'));
			System.currentPageReference().getParameters().put('sid', a.Id);
			CLMService.SubstitutedParams substitutedParams = CLMService.substituteConfigValuesInTemplate(config, o1.Id);
			Test.stopTest();
			System.assertNotEquals(null, substitutedParams);
			System.assertEquals('_', substitutedParams.salesforceFolderName);
		}
	}
}
