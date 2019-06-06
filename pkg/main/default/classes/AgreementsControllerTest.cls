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
	static void test_getAgreement_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.getAgreement(NegotiateAPIMock.DOCUMENT_ID_2.value);
				throw new AssertException('Expected get Agreement to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {

			Test.startTest();
			Agreement agreement = AgreementsController.getAgreement(NegotiateAPIMock.DOCUMENT_ID_2.value);
			Test.stopTest();
			System.assertNotEquals(null, agreement);
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
				AgreementsController.sendForExternalReview('Test Agreement', NegotiateAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
					'[{"email":"unittest@test.com", "name":"test user"}]',
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
			testTaskStatus = AgreementsController.sendForExternalReview('Test Agreement', NegotiateAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
				'[{"email":"unittest@test.com", "name":"test user"}]',
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
				AgreementsController.sendForInternalApproval('Test Agreement', NegotiateAPIMock.SOURCE_OBJECT_ID,new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
					'[{"email":"unittest@test.com", "name":"test user"}]',
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
	static void test_redirectToAgreementPreview() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String link = AgreementsController.redirectToAgreementPreview(NegotiateAPIMock.OBJECT_ID, NegotiateAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(null, link);
			System.assertEquals(link.startsWith(Site.getBaseUrl()), true);
			System.assertEquals(link.contains('sourceId=' + NegotiateAPIMock.OBJECT_ID), true);
			System.assertEquals(link.contains('agreementId=' + NegotiateAPIMock.DOCUMENT_ID.value), true);
		}		
	}

	@IsTest
	static void test_sendForInternalApproval_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.sendForInternalApproval('Test Agreement', NegotiateAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
				'[{"email":"unittest@test.com", "name":"test user"}]',
				'testSubject',
				'testBody');
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

	@IsTest
	static void test_generateUploadToken_success() {
		NegotiateAPIMock.success();
		SObject configuration = TestUtils.createAgreementConfiguration(NegotiateAPIMock.SOURCE_OBJECT_ID_2, NegotiateAPIMock.FOLDER_ID_2.toString());
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			NegotiateService.LimitedAccessToken limitedAccessToken = AgreementsController.generateUploadToken(NegotiateAPIMock.SOURCE_OBJECT_ID_2);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateDownloadToken_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			NegotiateService.LimitedAccessToken limitedAccessToken = AgreementsController.generateDownloadToken(NegotiateAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateResourceToken_success() {
		GenAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String result = AgreementsController.generateResourceToken(GenAPIMock.DOCUMENT_ID.toString());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.contains(GenAPIMock.DOCUMENT_ID.toString()));
		}
	}

	@IsTest
	static void test_generateResourceToken_fail() {
		GenAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Boolean hasError = false;
			Test.startTest();
			try {
				String result = AgreementsController.generateResourceToken(GenAPIMock.DOCUMENT_ID.toString());
			} catch(APIException ex) {
				hasError = true;
			}
			Test.stopTest();
			System.assert(hasError);
		}
	}	

}
