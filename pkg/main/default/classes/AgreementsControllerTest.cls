@IsTest
private class AgreementsControllerTest {

	@IsTest
	static void test_constructors() {
		System.assertNotEquals(null, new AgreementsController());
		System.assertNotEquals(null, new AgreementsController(null));
	}

	@IsTest
	static void test_getNameSpace_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.getNameSpace();
				throw new AssertException('Expected get namespace to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getNameSpace_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {

			Test.startTest();
			String result = AgreementsController.getNameSpace();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getAgreements_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.getAgreements(UserInfo.getUserId());
				throw new AssertException('Expected get agreements to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreements_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			List<Agreement> agreements;
			Test.startTest();
			agreements = AgreementsController.getAgreements(UserInfo.getUserId());
			Test.stopTest();
			System.assertNotEquals(null, agreements);
		}
	}

	@IsTest
	static void test_getLinkedDocuments_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.getLinkedDocuments(UserInfo.getUserId());
				throw new AssertException('Expected getLinkedDocuments to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLinkedDocuments_success() {

		System.runAs(UserMock.createDocuSignUser(true)) {
			List<Document> documents;
			Test.startTest();
			documents = AgreementsController.getLinkedDocuments(UserInfo.getUserId());
			Test.stopTest();
			System.assertNotEquals(null, documents);
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.createAgreementInEOSFolder(UserInfo.getUserId(), UserInfo.getUserId(), 'testName');
				throw new AssertException('Expected createAgreementInEOSFolder to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.createAgreementInEOSFolder(UserInfo.getUserId(), UserInfo.getUserId(), 'testName');
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

	@IsTest
	static void test_renameAgreement_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.renameAgreement('22222efe-e541-e911-9c1d-3ca82a1e3f41', 'test');
				throw new AssertException('Expected renameAgreement to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_renameAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			Boolean testResult;
			Test.startTest();
			testResult = AgreementsController.renameAgreement('22222efe-e541-e911-9c1d-3ca82a1e3f41', 'test');
			Test.stopTest();
			System.assertNotEquals(null, testResult);
		}
	}

	@IsTest
	static void test_deleteAgreement_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.deleteAgreement('22222efe-e541-e911-9c1d-3ca82a1e3f41');
				throw new AssertException('Expected deleteAgreement to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			Boolean testResult;
			Test.startTest();
			testResult = AgreementsController.deleteAgreement('22222efe-e541-e911-9c1d-3ca82a1e3f41');
			Test.stopTest();
			System.assertNotEquals(null, testResult);
		}
	}

	@IsTest
	static void test_resolveRecipient_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.resolveRecipient(UserInfo.getUserId());
				throw new AssertException('Expected resolveRecipient to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveRecipient_success() {
		System.runAs(UserMock.createDocuSignUser(true)) {
			Recipient testRecipient;
			Test.startTest();
			testRecipient = AgreementsController.resolveRecipient(UserInfo.getUserId());
			Test.stopTest();
			System.assertNotEquals(null, testRecipient);
		}
	}

	@IsTest
	static void test_sendForExternalReview_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.sendForExternalReview(new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
					new List<String> { 'unittest@test.com' },
					'testSubject',
					'testBody', 8);
				throw new AssertException('Expected sendForExternalReview to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.sendForExternalReview(new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
				new List<String> { 'unittest@test.com' },
				'testSubject',
				'testBody', 8);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

	@IsTest
	static void test_sendForInternalApproval_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.sendForInternalApproval(new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
					new List<String> { 'unittest@test.com' },
					'testSubject',
					'testBody');
				throw new AssertException('Expected sendForInternalApproval to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendForInternalApproval_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.sendForInternalApproval(new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
				new List<String> { 'unittest@test.com' },
				'testSubject',
				'testBody');
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

}
