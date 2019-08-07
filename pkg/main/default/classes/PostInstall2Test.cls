	@IsTest
	private class PostInstall2Test {

	@IsTest
	static void test_initializeAccountSettings_no_key() {
		insert AccountSettings__c.getOrgDefaults();
		System.assertEquals(null, AccountSettings__c.getOrgDefaults().EncryptionKey__c);

		Test.startTest();
		PostInstallResults result = PostInstall2.initializeAccountSettings();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.success);
		System.assertEquals(1, Collection.size(result.getSteps()));
		System.assertEquals(PostInstallResults.StepStatus.SUCCESS, result.getSteps()[0].status);
		System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().EncryptionKey__c);
	}

	@IsTest
	static void test_initializeAccountSettings_key_exists() {
		String pvk = UUID.randomUUID().toShortString();
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.EncryptionKey__c = pvk;
		insert s;

		Test.startTest();
		PostInstallResults result = PostInstall2.initializeAccountSettings();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.success);
		System.assertEquals(1, Collection.size(result.getSteps()));
		System.assertEquals(PostInstallResults.StepStatus.SKIPPED, result.getSteps()[0].status);
		System.assertEquals(pvk, AccountSettings__c.getOrgDefaults().EncryptionKey__c);
	}

	@isTest
	static void test_createDefaultCLMObjMappings_mappings_do_not_exist(){
		System.assertEquals(null, EOS_Type__c.getOrgDefaults().Name__c);

		Test.startTest();
		PostInstallResults result = PostInstall2.createDefaultCLMObjMappings();
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@isTest
	static void test_createDefaultCLMObjMappings_mappings_exist(){
		EOS_Type__c eos_1 = EOS_Type__c.getOrgDefaults();
		eos_1.Folder_Name__c = UUID.randomUUID().toShortString();
		eos_1.Path__c = UUID.randomUUID().toShortString();
		eos_1.Name__c = UUID.randomUUID().toShortString();
		eos_1.Folder_Name_Format__c	= UUID.randomUUID().toShortString();
		eos_1.Variables__c = UUID.randomUUID().toShortString();
		eos_1.Path_Format__c = UUID.randomUUID().toShortString();			
		eos_1.Name = UUID.randomUUID().toShortString();		
		insert eos_1;

		EOS_Type__c eos_2 = new EOS_Type__c();
		eos_2.Folder_Name__c = UUID.randomUUID().toShortString();
		eos_2.Path__c = UUID.randomUUID().toShortString();
		eos_2.Name__c = UUID.randomUUID().toShortString();
		eos_2.Folder_Name_Format__c	= UUID.randomUUID().toShortString();
		eos_2.Variables__c = UUID.randomUUID().toShortString();
		eos_2.Path_Format__c = UUID.randomUUID().toShortString();			
		eos_2.Name = UUID.randomUUID().toShortString();		
		insert eos_2;

		Test.startTest();
		PostInstallResults result = PostInstall2.createDefaultCLMObjMappings();
		Test.stopTest();

		System.assertEquals(PostInstallResults.StepStatus.SKIPPED, result.getSteps()[0].status);
	}

	@IsTest
	static void test_shouldExecute() {
		PostInstall2 pi2 = new PostInstall2();
		System.assert(!pi2.shouldExecute(UserInfo.getOrganizationId(), UserInfo.getUserId(), null, false, false));
		System.assert(!pi2.shouldExecute(UserInfo.getOrganizationId(), UserInfo.getUserId(), new Version(2, 0), true, false));
		System.assert(pi2.shouldExecute(UserInfo.getOrganizationId(), UserInfo.getUserId(), new Version(1, 2), true, false));
	}

	@IsTest
	static void test_execute() {
		insert AccountSettings__c.getOrgDefaults();
		System.assertEquals(null, AccountSettings__c.getOrgDefaults().EncryptionKey__c);

		Test.startTest();
		PostInstallResults result = new PostInstall2().execute(null, null, null, false, false);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.success);
		System.assertEquals(1, Collection.size(result.getSteps()));
		System.assertEquals(PostInstallResults.StepStatus.SUCCESS, result.getSteps()[0].status);
		System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().EncryptionKey__c);
	}
}