@IsTest
private class HistoryAPITest {

	// FIXME: Missing tests for some public methods.

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			HistoryAPI result1 = HistoryAPI.getInstance();
			HistoryAPI result2 = HistoryAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_populateEmailToUser_success() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			HistoryAPI client = HistoryAPI.getInstance();
			client.populateEmailToUser(new Set<String> { UserInfo.getUserEmail() });
			System.assertNotEquals(client.emailToUser, null);
			System.assertEquals(client.emailToUser.get(UserInfo.getUserEmail()).Id, UserInfo.getUserId());
		}
	}

	@IsTest
	static void test_populateEmailToUser_blankInput() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			HistoryAPI client = HistoryAPI.getInstance();
			client.populateEmailToUser(new Set<String> { '' });
			System.assert(!client.emailToUser.containsKey(''));
		}
	}

	@IsTest
	static void test_populateEmailToUser_randomEmailInput() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			HistoryAPI client = HistoryAPI.getInstance();
			client.populateEmailToUser(new Set<String> { 'test@test.com' });
			System.assert(!client.emailToUser.containsKey('test@test.com'));
		}
	}

	@IsTest
	static void test_populateEmailToContact_success() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Contact testContact = new Contact (FirstName = 'test', LastName = 'contact', Email = 'test@test.com');
			insert testContact;
			HistoryAPI client = HistoryAPI.getInstance();
			client.populateEmailToContact(new Set<String> { testContact.Email });
			System.assertNotEquals(client.emailToContact, null);
			System.assert(client.emailToContact.containsKey(testContact.Email));
		}
	}

	@IsTest
	static void test_populateEmailToContact_randomEmailInput() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			HistoryAPI client = HistoryAPI.getInstance();
			client.populateEmailToContact(new Set<String> { 'randomInput' });
			System.assert(!client.emailToContact.containsKey('randomInput'));
		}
	}

	@IsTest
	static void test_populateEmailToContact_blankInput() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			HistoryAPI client = HistoryAPI.getInstance();
			client.populateEmailToContact(new Set<String> { '' });
			System.assert(!client.emailToContact.containsKey(''));
		}
	}

	@IsTest
	static void test_getHistoryItems_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			try {
				HistoryAPI.getInstance().getHistoryItems(UUID.randomUUID());
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ScmAPI.Error);
				System.assert(UUID.isNotEmpty(((ScmAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getHistoryItems_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(AgreementHistoryItem.DocumentImportFromSalesforce, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	// Agreement has rename history
	@IsTest
	static void test_getHistoryItems_success2() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(ScmAPIMock.DOCUMENT_ID_4);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.TitleChanged, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	// Agreement sent for approval
	@IsTest
	static void test_getHistoryItems_success3() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(ScmAPIMock.DOCUMENT_ID_5);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.ApprovalCheckout, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
			System.assertEquals('Full Sub', result.get(0).recipients.get(0).fullName);
			System.assertEquals('tgreen+1@springcm.com', result.get(0).recipients.get(0).email);
			System.assertEquals('For approval', result.get(0).subject);
			System.assertEquals('Please approve the documents', result.get(0).message);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	// Agreement sent for external review
	@IsTest
	static void test_getHistoryItems_success4() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(ScmAPIMock.DOCUMENT_ID_6);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.ExternalReviewInitiated, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
			System.assertEquals('For external review', result.get(0).subject);
			System.assertEquals('Please review the document', result.get(0).message);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	// Agreement maps to Salesforce contact
	@IsTest
	static void test_getHistoryItems_success5() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(ScmAPIMock.DOCUMENT_ID_7);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.ExternalReviewCompletedDocumentAndComments, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	// Agreement approved with comments
	@IsTest
	static void test_getHistoryItems_success6() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(ScmAPIMock.DOCUMENT_ID_3);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(4, result.size());
			System.assertEquals(AgreementHistoryItem.WorkflowApproved, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals('Full Sub', result.get(0).actor.fullName);
			System.assertEquals('tgreen+1@springcm.com', result.get(0).actor.email);
			System.assertNotEquals(null, result.get(0).comments);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	// Agreement rejected with comments
	@IsTest
	static void test_getHistoryItems_success7() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<AgreementHistoryItem> result = HistoryAPI.getInstance().getHistoryItems(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(AgreementHistoryItem.WorkflowRejected, result.get(0).historyItemType);
			System.assertEquals(UserInfo.getUserEmail(), result.get(0).currentUserEmail);
			System.assertEquals('Dimitri Blaiddyd', result.get(0).actor.fullName);
			System.assertEquals('dimitri.blaiddyd@example.com', result.get(0).actor.email);
			System.assertNotEquals(null, result.get(0).comments);
			System.assertEquals(null, result.get(0).previewUrl);
		}
	}

	@IsTest
	static void test_resendRequest_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			try {
				HistoryAPI.getInstance().resendRequest('https://unit.test', 'test');
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ScmAPI.Error);
				System.assert(UUID.isNotEmpty(((ScmAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendRequest_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Boolean result = HistoryAPI.getInstance().resendRequest('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17', 'ExternalReview');
			Test.stopTest();

			System.assertEquals(true, result);
		}
	}
}
