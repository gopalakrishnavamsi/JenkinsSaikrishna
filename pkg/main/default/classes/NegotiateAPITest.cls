@IsTest
public with sharing class NegotiateAPITest {

	@IsTest
	static void test_createEOSFolder_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().createEOSFolder('Edge Installation', NegotiateAPIMock.OBJECT_ID, 'Opportunity');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(NegotiateAPIMock.FOLDER_ID, result);

		}
	}

	@IsTest
	static void test_createEOSFolder_failure() {
		NegotiateAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			try {
				NegotiateAPI.getInstance().createEOSFolder('Edge Installation', NegotiateAPIMock.OBJECT_ID, 'Opportunity');
				throw new AssertException('Expected createEOSFolder to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof NegotiateAPI.Error);
				System.assert(UUID.isNotEmpty(((NegotiateAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().createAgreementInEOSFolder(NegotiateAPIMock.OBJECT_ID,
				NegotiateAPIMock.FOLDER_ID, 'negotiate.docx');
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals(UUID.parse('4682d399-29fe-4085-9e48-126e4ffa0566'), result);
		}
	}

	@IsTest
	static void test_getAgreements_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<Agreement> result = NegotiateAPI.getInstance().getAgreements(NegotiateAPIMock.FOLDER_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals('docusignlogerror7-23-18-1.docx', result.get(0).name);
			System.assertEquals(UUID.parse('ea7ab407-ea41-e911-9c1d-3ca82a1e3f41'), result.get(0).id);
		}
	}

	@IsTest
	static void test_renameAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().renameAgreement(NegotiateAPIMock.DOCUMENT_ID, 'docuTestRename.docx');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_deleteAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().deleteAgreement(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_getAgreementVersions_success() {

		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<Agreement> result = NegotiateAPI.getInstance().getAgreementVersions(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals('newName.docx', result.get(0).name);
			System.assertEquals(UUID.parse('213e9c1a-8f46-e911-9c1d-3ca82a1e3f41'), result.get(0).id);
		}
	}

	@IsTest
	static void test_sendForApproval_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().sendForApproval('test-document 123', new List<UUID> {
				NegotiateAPIMock.DOCUMENT_ID
			}, new List<String> {
				NegotiateAPIMock.USER_EMAIL
			}, 'Test subject', 'Test message body: hello world');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().sendForExternalReview('test-document 123', new List<UUID> {
				NegotiateAPIMock.DOCUMENT_ID
			}, new List<String> {
				NegotiateAPIMock.USER_EMAIL
			}, 'Test subject', 'Test message body: hello world', 5);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_sendForApproval_failure() {
		NegotiateAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().sendForApproval('test-document 123', new List<UUID> {
					NegotiateAPIMock.DOCUMENT_ID
				}, new List<String> {
					NegotiateAPIMock.USER_EMAIL
				}, 'Test subject', 'Test message body: hello world');
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);

		}
	}

	@IsTest
	static void test_sendForExternalReview_failure() {
		NegotiateAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().sendForExternalReview('test-document 123', new List<UUID> {
					NegotiateAPIMock.DOCUMENT_ID
				}, new List<String> {
					NegotiateAPIMock.USER_EMAIL
				}, 'Test subject', 'Test message body: hello world', 5);
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);

		}
	}

	// Agreement has new history
	@IsTest
	static void test_getHistoryItems_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<NegotiateAPI.APIHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.ACCOUNT_ID,
				NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(HistoryItemAction.DOCUMENT_IMPORTED_FROM_SALESFORCE, result.get(0).action);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).userEmail);
			System.assertEquals('Tyler Green', result.get(0).data.actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).data.actor.emailAddress);
		}
	}

	// Agreement has rename history
	@IsTest
	static void test_getHistoryItems_success2() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<NegotiateAPI.APIHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.ACCOUNT_ID_2,
				NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(HistoryItemAction.DOCUMENT_RENAMED, result.get(0).action);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).userEmail);
			System.assertEquals('Tyler Green', result.get(0).data.actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).data.actor.emailAddress);
		}
	}

	// Agreement sent for approval
	@IsTest
	static void test_getHistoryItems_success3() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<NegotiateAPI.APIHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.ACCOUNT_ID_3,
				NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(HistoryItemAction.APPROVAL_CHECKOUT, result.get(0).action);
			System.assertEquals(null, result.get(0).userEmail);
			System.assertEquals('Tyler Green', result.get(0).data.actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).data.actor.emailAddress);
			System.assertEquals('Full Sub', result.get(0).data.approvers.get(0).fullName);
			System.assertEquals('tgreen+1@springcm.com', result.get(0).data.approvers.get(0).emailAddress);
			System.assertEquals('For approval', result.get(0).data.emailSubject);
			System.assertEquals('Please approve the documents', result.get(0).data.emailMessage);
		}
	}

	// Agreement sent for external review
	@IsTest
	static void test_getHistoryItems_success4() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<NegotiateAPI.APIHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.ACCOUNT_ID_4,
				NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(HistoryItemAction.EXTERNAL_REVIEW_INITIATED, result.get(0).action);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).userEmail);
			System.assertEquals('Tyler Green', result.get(0).data.actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).data.actor.emailAddress);
			System.assertEquals('John Doe', result.get(0).data.reviewer.fullName);
			System.assertEquals('someguy+externalReviewRecipient@springcm.com', result.get(0).data.reviewer.emailAddress);
			System.assertEquals('For external review', result.get(0).data.emailSubject);
			System.assertEquals('Please review the document', result.get(0).data.emailMessage);
		}
	}
}