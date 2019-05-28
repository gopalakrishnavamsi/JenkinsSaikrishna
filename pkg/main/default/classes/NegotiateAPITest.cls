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
	static void test_getAgreementInEOSFolderStatus_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getAgreementInEOSFolderStatus(NegotiateAPIMock.TASK_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
		}
	}

	@IsTest
	static void test_getAgreementInEOSFolderStatus_success2() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getAgreementInEOSFolderStatus(NegotiateAPIMock.TASK_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Processing', result.status);
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
			System.assertEquals(160453, result.get(0).pdfFileSize);
			System.assertEquals('https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41', result.get(0).href.toExternalForm());
		}
	}

	@IsTest
	static void test_getAreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Agreement agreement = NegotiateAPI.getInstance().getAgreement(NegotiateAPIMock.DOCUMENT_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, agreement);
			System.assertEquals('ServiceDoc1.docx', agreement.name);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID_2, agreement.id);
			System.assertEquals(160568, agreement.pdfFileSize);
			System.assertEquals('https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e922-9c1d-3ca82a1e3f41', agreement.href.toExternalForm());
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
			System.assertEquals('pratik.hatkar@docusign.com', result.get(0).modifiedBy);
			System.assertEquals(UUID.parse('213e9c1a-8f46-e911-9c1d-3ca82a1e3f41'), result.get(0).id);
			System.assertEquals('3.0', result.get(0).version);
			System.assertNotEquals(null, result.get(0).versions);
			System.assertEquals(true, result.get(0).versions.isEmpty());
			System.assertEquals(true, result.get(0).historyItems.isEmpty());
		}
	}

	@IsTest
	static void test_sendForApproval_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			UUID result = NegotiateAPI.getInstance().sendForApproval('Test Agreement', 
			NegotiateAPIMock.SOURCE_OBJECT_ID,
			new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
			new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT }
			, 'Test subject'
			, 'Test message body: hello world');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().sendForExternalReview('Test Agreement',
			NegotiateAPIMock.SOURCE_OBJECT_ID, 
			new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
			new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT }, 
			'Test subject', 'Test message body: hello world', 
			5);
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendForApproval_failure() {
		NegotiateAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().sendForApproval('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID,	
				new List<UUID> {NegotiateAPIMock.DOCUMENT_ID }, 
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT }, 
				'Test subject', 
				'Test message body: hello world');
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
				NegotiateAPI.getInstance().sendForExternalReview('Test Agreement', 
					NegotiateAPIMock.SOURCE_OBJECT_ID, 
					new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
					new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT }, 
					'Test subject', 
					'Test message body: hello world', 
					5);
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
			List<AgreementHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(AgreementHistoryItem.DocumentImportFromSalesforce, result.get(0).historyItemType);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
		}
	}

	// Agreement has rename history
	@IsTest
	static void test_getHistoryItems_success2() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<AgreementHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.DOCUMENT_ID_4);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.TitleChanged, result.get(0).historyItemType);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
		}
	}

	// Agreement sent for approval
	@IsTest
	static void test_getHistoryItems_success3() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<AgreementHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.DOCUMENT_ID_5);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.ApprovalCheckout, result.get(0).historyItemType);
			System.assertEquals(null, result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
			System.assertEquals('Full Sub', result.get(0).recipients.get(0).fullName);
			System.assertEquals('tgreen+1@springcm.com', result.get(0).recipients.get(0).email);
			System.assertEquals('For approval', result.get(0).subject);
			System.assertEquals('Please approve the documents', result.get(0).message);
		}
	}

	// Agreement sent for external review
	@IsTest
	static void test_getHistoryItems_success4() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<AgreementHistoryItem> result = NegotiateAPI.getInstance().getHistoryItems(
				NegotiateAPIMock.DOCUMENT_ID_6);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(AgreementHistoryItem.ExternalReviewInitiated, result.get(0).historyItemType);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).currentUserEmail);
			System.assertEquals('Tyler Green', result.get(0).actor.fullName);
			System.assertEquals('tgreen+packageb@springcm.com', result.get(0).actor.email);
			System.assertEquals('John Doe', result.get(0).recipients.get(0).fullName);
			System.assertEquals('someguy+externalReviewRecipient@springcm.com', result.get(0).recipients.get(0).email);
			System.assertEquals('For external review', result.get(0).subject);
			System.assertEquals('Please review the document', result.get(0).message);
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			NegotiateService.LimitedAccessToken limitedAccessToken = NegotiateAPI.getInstance().generateLimitedAccessToken(NegotiateAPIMock.DOCUMENT_ID, 'accessToken');
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assertEquals('eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjY4MTg1ZmYxLTRlNTEtNGNlOS1hZjFjLTY4OTgxMjIwMzMxNyJ9.eyJUb2tlblR5cGUiOjUsIklzc3VlSW5zdGFudCI6MTU1ODU2NDgyMywiZXhwIjoxNTU4NTY4NDIzLCJVc2VySWQiOiIzZGVkYWM1My00OGZhLTRkZTYtODk0YS0zNWI0ODAyYWQxMGQiLCJzaXRlaWQiOjEsInNjcCI6WyJzcHJpbmdfY29udGVudCJdLCJhdWQiOiI1NzUxYzI1NS0zM2E0LTRjOGQtYmY1YS0wNjU0YTUwNDE4ODYiLCJpc3MiOiJodHRwczovL2FjY291bnQtZC5kb2N1c2lnbi5jb20vIiwic3ViIjoiM2RlZGFjNTMtNDhmYS00ZGU2LTg5NGEtMzViNDgwMmFkMTBkIiwiYWN0IjoiNTc1MWMyNTUtMzNhNC00YzhkLWJmNWEtMDY1NGE1MDQxODg2IiwiYW1yIjpbImp3dF9iciJdfQ.aBrwKSZ09AqGqCNTE4NsAY-qDhflif94kcMEdq7zosZ7HRSFIggSOdRY8d9cvznGWsCp4hk4eKlihoUaHohMRKMwNW8dsmhPbff1t4Cm5xYEDTOOOrhA5ZC6bKJXBlLB5vhEga0yShMAY7ggbCOqxdCZH9pi3hp_1Z8G_8-7vQAPLfmqJo3tcdtyDXHfpdyJs5-4toxWiFtxX1VZS3I4tVre8w0P1QIpESDv-_-qHaE-4zniddCpg_CCR90ON83ZtBTG0HLQNj52YFAjKs5wm3nQrMC4V9C3vo9uyCSeBa9Lq0AgswFNoSLn7eiviRJB9iwSBx9Vuqx8xsOaKC9CMg', limitedAccessToken.token);
			System.assertEquals('https://apiuatna11.springcm.com/v2/63d5ccaa-67ff-452b-8e5e-ee2dd94f1a00', limitedAccessToken.apiBaseUrl);
			System.assertEquals('https://apidownloaduatna11.springcm.com', limitedAccessToken.apiDownLoadBaseUrl);
			System.assertEquals('https://apiuploaduatna11.springcm.com', limitedAccessToken.apiUploadBaseUrl);
		}
	}

	@IsTest
	static void test_getApprovalUsers_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<AgreementHistoryItem.Actor> approvalUsers = NegotiateAPI.getInstance().getApprovalUsers(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, approvalUsers);
			System.assertEquals(2, approvalUsers.size());
			System.assertEquals('https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7', approvalUsers.get(0).accountUrl);
			System.assertEquals('John Doe', approvalUsers.get(0).fullName);
			System.assertEquals('Jane Doe', approvalUsers.get(1).fullName);
		}
	}

	@IsTest
	static void test_getDocumentURL() {
		System.runAs(UserMock.createDocuSignUser()) {
			String endpoint = NegotiateAPI.getInstance().getDocumentURL(NegotiateAPIMock.DOCUMENT_ID);
			System.assertNotEquals(endpoint, null);
			System.assert(endpoint.contains('/' + NegotiateAPIMock.DOCUMENT_ID));
		}
	}

	@IsTest
	static void test_cancelApprovalOrExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().cancelApprovalOrExternalReview(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_resendRequest_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().resendRequest(NegotiateAPIMock.DOCUMNET_HREF, 'ExternalReview');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}
}