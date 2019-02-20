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
