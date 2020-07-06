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

	@IsTest
	static void test_voidEnvelope_Success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(UUID.parse(e1.DocuSignId__c));
			es1.Status__c = Envelope.STATUS_SENT;
			update es1;

			Test.startTest();
			Boolean result = StatusController.voidEnvelope(e1.DocuSignId__c, 'reason');
			Test.stopTest();
			System.assert(result);
		}
	}

	@IsTest
	static void test_voidEnvelope_Unauthorized() {
		Envelope e1;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				StatusController.voidEnvelope(String.valueOf(e1.docuSignId), 'reason');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendEnvelope_Success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			UUID dseId = UUID.randomUUID();
			Envelope__c e = TestUtils.createEnvelope(dseId);
			TestUtils.createEnvelopeStatus(e);

			Test.startTest();
			System.assert(StatusController.resendEnvelope(String.valueOf(dseId)));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendEnvelope_Unauthorize() {
		Envelope e1;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				StatusController.resendEnvelope(String.valueOf(e1.docuSignId));
				throw new AssertException('Expected resendEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
