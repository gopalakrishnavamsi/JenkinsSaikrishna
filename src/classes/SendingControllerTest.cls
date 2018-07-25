@IsTest
private class SendingControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a = TestUtils.createAccount();

			Test.startTest();
			SendingController result = new SendingController(new ApexPages.StandardController(a));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Application.lightningNamespace, result.namespace);
			System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
			System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
		}
	}

	@IsTest
	static void test_getReturnUrl() {
		Id sId = UserInfo.getUserId();
		Id eId = UserInfo.getUserRoleId();

		Test.startTest();
		Url result = SendingController.getReturnUrl(sId, eId);
		Test.stopTest();
	}
}
