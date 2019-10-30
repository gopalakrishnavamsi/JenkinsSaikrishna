@IsTest
private class StatusControllerTest {

	@IsTest
	static void test_constructor() {
		Test.startTest();
		StatusController result = new StatusController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Application.namespace, result.namespace);
	}

	@IsTest
	static void test_getStatus_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			TestUtils.createEnvelopeStatus(TestUtils.createEnvelope(a.Id));
			TestUtils.createEnvelopeStatus(TestUtils.createEnvelope(a.Id));
			TestUtils.createEnvelopeStatus(TestUtils.createEnvelope(a.Id));

			Test.startTest();
			List<Envelope.Status> result = StatusController.getStatus(a.Id, 2);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_getStatus_error() {
		System.runAs(UserMock.createUser()) { // Unauthorized
			Test.startTest();
			try {
				StatusController.getStatus(UserInfo.getUserId(), 1);
				throw new AssertException('Expected getStatus to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getStatusListViews() { // No way to test error case
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			List<ListView> result = StatusController.getStatusListViews();
			Test.stopTest();

			System.assert(!Collection.isEmpty(result));
		}
	}
}
