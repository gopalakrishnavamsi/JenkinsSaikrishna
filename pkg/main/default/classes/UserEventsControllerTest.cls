@IsTest
private class UserEventsControllerTest {

	@IsTest
	static void test_getUserProperties_failure() {
		System.runAs(UserMock.createRestrictedUser()) {
			Test.startTest();
			try {
				UserEventsController.getUserProperties();
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertNotEquals(null, ex);
				System.assert(String.isNotBlank(ex.getMessage()));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUserProperties_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			UserEventsController.UserProperties result1 = UserEventsController.getUserProperties();
			UserEventsController.UserProperties result2 = UserEventsController.getUserProperties();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
			System.assertEquals(Application.name, result1.application);
			System.assertEquals(String.valueOf(Application.version), result1.version);
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(s.Environment__c, result1.environment);
			System.assertEquals(StringUtils.hash(s.AccountId__c), result1.accountIdHash);
			String username = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c;
			System.assertEquals(StringUtils.hash(username), result1.userIdHash);
		}
	}
}
