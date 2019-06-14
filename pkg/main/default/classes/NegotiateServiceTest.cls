@IsTest
private class NegotiateServiceTest {

	@IsTest
	static void test_getAgreements_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			SObject configuration = TestUtils.createAgreementConfiguration(NegotiateAPIMock.SOURCE_OBJECT_Id, NegotiateAPIMock.FOLDER_ID_2.toString());
			Test.startTest();
			List<Agreement> result = NegotiateService.getAgreements(NegotiateAPIMock.SOURCE_OBJECT_Id);
			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals('ServiceDoc1.docx', result.get(0).name);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID_2, result.get(0).id);
			System.assertEquals('2019-05-25 11:13:28', String.valueOf(result.get(0).modifiedDate));
			System.assertEquals(AgreementStatus.PENDING_REVIEW, result.get(0).status);
			System.assertEquals(2, result.get(0).historyItems.size());
			System.assertEquals(AgreementHistoryItem.ExternalReviewInitiated, result.get(0).historyItems.get(0).historyItemType);
			System.assertEquals(AgreementHistoryItem.DocumentImportFromSalesforce, result.get(0).historyItems.get(1).historyItemType);
			System.assertEquals(null, result.get(0).version);
			System.assertNotEquals(null, result.get(0).versions);
			System.assertEquals(false, result.get(0).versions.isEmpty());
			System.assertEquals('newName.docx', result.get(0).versions.get(0).name);

			System.assertEquals('ServiceDoc2.docx', result.get(1).name);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID_3, result.get(1).id);
			System.assertEquals(AgreementStatus.PENDING_APPROVAL, result.get(1).status);
			System.assertEquals(4, result.get(1).historyItems.size());
			System.assertEquals(AgreementHistoryItem.WorkflowApproved, result.get(1).historyItems.get(0).historyItemType);
			System.assertEquals(AgreementHistoryItem.ApprovalCheckout, result.get(1).historyItems.get(2).historyItemType);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Agreement result = NegotiateService.getAgreement(NegotiateAPIMock.DOCUMENT_ID_2);
			System.assertNotEquals(null, result);
			System.assertEquals('ServiceDoc1.docx', result.name);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID_2, result.id);
			System.assertEquals('2019-05-25 11:13:28', String.valueOf(result.modifiedDate));
			System.assertEquals(AgreementStatus.PENDING_REVIEW, result.status);
			System.assertEquals(2, result.historyItems.size());
			System.assertEquals(AgreementHistoryItem.ExternalReviewInitiated, result.historyItems.get(0).historyItemType);
			System.assertEquals(AgreementHistoryItem.DocumentImportFromSalesforce, result.historyItems.get(1).historyItemType);
			System.assertNotEquals(null, result.versions);
			System.assertEquals(false, result.versions.isEmpty());
			System.assertEquals('newName.docx', result.versions.get(0).name);

			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			SObject configuration = TestUtils.createAgreementConfiguration(NegotiateAPIMock.SOURCE_OBJECT_ID_2, NegotiateAPIMock.FOLDER_ID_2.toString());
			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateService.createAgreementInEOSFolder(NegotiateAPIMock.SOURCE_OBJECT_ID_2, NegotiateAPIMock.SOURCE_OBJECT_ID_2, 'Test_DOC_Name');
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
			System.assertEquals('Agreement has been imported successfully.', result.message);
		}
	}

	@IsTest
	static void test_renameAgreement_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateService.renameAgreement(NegotiateAPIMock.DOCUMENT_ID, 'docuTestRename.docx');
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
			Boolean result = NegotiateService.deleteAgreement(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID, 
				new List<UUID> { UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41') },
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT },
				'testSubject',
				'testBody', 
				8);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Waiting', testTaskStatus.status);
			System.assertEquals(Label.ExternalReviewSuccess, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_sendForExternalReview_executing() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID, 
				new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT },
				'testSubject',
				'testBody', 8);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Executing', testTaskStatus.status);
			System.assertEquals(Label.ExternalReviewProcessing, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_sendForExternalReview_failed() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID, 
				new List<UUID> { NegotiateAPIMock.DOCUMENT_ID_2 },
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT },
				'testSubject',
				'testBody', 8);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Failed', testTaskStatus.status);
			System.assertEquals(Label.ExternalReviewFailed, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_sendForInternalApproval_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForInternalApproval('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID, 
				new List<UUID> { UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41') },
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT },
				'testSubject',
				'testBody', true);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Waiting', testTaskStatus.status);
			System.assertEquals(Label.InternalApprovalSuccess, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_sendForInternalApproval_executing() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForInternalApproval('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID, 
				new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT },
				'testSubject',
				'testBody', true);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Executing', testTaskStatus.status);
			System.assertEquals(Label.InternalApprovalProcessing, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_sendForInternalApproval_failed() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForInternalApproval('Test Agreement', 
				NegotiateAPIMock.SOURCE_OBJECT_ID, 
				new List<UUID> { NegotiateAPIMock.DOCUMENT_ID_2 },
				new List<Recipient> { NegotiateAPIMock.WORKFLOW_RECIPIENT },
				'testSubject',
				'testBody', true);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Failed', testTaskStatus.status);
			System.assertEquals(Label.InternalApprovalFailed, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_getApprovalUsers_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<AgreementHistoryItem.Actor> approvalUsers = NegotiateService.getApprovalUsers(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, approvalUsers);
			System.assertEquals(2, approvalUsers.size());
			System.assertEquals('https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7', approvalUsers.get(0).accountUrl);
			System.assertEquals('John Doe', approvalUsers.get(0).fullName);
			System.assertEquals('Jane Doe', approvalUsers.get(1).fullName);
		}
	}

	@IsTest
	static void test_getAgreementPreviewLink() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String link = NegotiateService.getAgreementPreviewLink(NegotiateAPIMock.OBJECT_ID, NegotiateAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(null, link);
			System.assertEquals(link.startsWith(Site.getBaseUrl()), true);
			System.assertEquals(link.contains('sourceId=' + NegotiateAPIMock.OBJECT_ID), true);
			System.assertEquals(link.contains('agreementId=' + NegotiateAPIMock.DOCUMENT_ID.value), true);
		}
	}

	@IsTest
	static void test_generateUploadToken_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			SObject configuration = TestUtils.createAgreementConfiguration(NegotiateAPIMock.SOURCE_OBJECT_ID_2, NegotiateAPIMock.FOLDER_ID_2.toString());
			Test.startTest();
			NegotiateService.LimitedAccessToken limitedAccessToken = NegotiateService.generateUploadToken(NegotiateAPIMock.SOURCE_OBJECT_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assertEquals('eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjY4MTg1ZmYxLTRlNTEtNGNlOS1hZjFjLTY4OTgxMjIwMzMxNyJ9.eyJUb2tlblR5cGUiOjUsIklzc3VlSW5zdGFudCI6MTU1ODU2NDgyMywiZXhwIjoxNTU4NTY4NDIzLCJVc2VySWQiOiIzZGVkYWM1My00OGZhLTRkZTYtODk0YS0zNWI0ODAyYWQxMGQiLCJzaXRlaWQiOjEsInNjcCI6WyJzcHJpbmdfY29udGVudCJdLCJhdWQiOiI1NzUxYzI1NS0zM2E0LTRjOGQtYmY1YS0wNjU0YTUwNDE4ODYiLCJpc3MiOiJodHRwczovL2FjY291bnQtZC5kb2N1c2lnbi5jb20vIiwic3ViIjoiM2RlZGFjNTMtNDhmYS00ZGU2LTg5NGEtMzViNDgwMmFkMTBkIiwiYWN0IjoiNTc1MWMyNTUtMzNhNC00YzhkLWJmNWEtMDY1NGE1MDQxODg2IiwiYW1yIjpbImp3dF9iciJdfQ.aBrwKSZ09AqGqCNTE4NsAY-qDhflif94kcMEdq7zosZ7HRSFIggSOdRY8d9cvznGWsCp4hk4eKlihoUaHohMRKMwNW8dsmhPbff1t4Cm5xYEDTOOOrhA5ZC6bKJXBlLB5vhEga0yShMAY7ggbCOqxdCZH9pi3hp_1Z8G_8-7vQAPLfmqJo3tcdtyDXHfpdyJs5-4toxWiFtxX1VZS3I4tVre8w0P1QIpESDv-_-qHaE-4zniddCpg_CCR90ON83ZtBTG0HLQNj52YFAjKs5wm3nQrMC4V9C3vo9uyCSeBa9Lq0AgswFNoSLn7eiviRJB9iwSBx9Vuqx8xsOaKC9CMg', limitedAccessToken.token);
			System.assertEquals('https://apiuploaduatna11.springcm.com', limitedAccessToken.apiUploadBaseUrl);
			System.assertEquals(NegotiateAPIMock.FOLDER_ID_2, limitedAccessToken.entityId);
		}
	}

	@IsTest
	static void test_generateDownloadToken_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			NegotiateService.LimitedAccessToken limitedAccessToken = NegotiateService.generateDownloadToken(NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assertEquals('eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjY4MTg1ZmYxLTRlNTEtNGNlOS1hZjFjLTY4OTgxMjIwMzMxNyJ9.eyJUb2tlblR5cGUiOjUsIklzc3VlSW5zdGFudCI6MTU1ODU2NDgyMywiZXhwIjoxNTU4NTY4NDIzLCJVc2VySWQiOiIzZGVkYWM1My00OGZhLTRkZTYtODk0YS0zNWI0ODAyYWQxMGQiLCJzaXRlaWQiOjEsInNjcCI6WyJzcHJpbmdfY29udGVudCJdLCJhdWQiOiI1NzUxYzI1NS0zM2E0LTRjOGQtYmY1YS0wNjU0YTUwNDE4ODYiLCJpc3MiOiJodHRwczovL2FjY291bnQtZC5kb2N1c2lnbi5jb20vIiwic3ViIjoiM2RlZGFjNTMtNDhmYS00ZGU2LTg5NGEtMzViNDgwMmFkMTBkIiwiYWN0IjoiNTc1MWMyNTUtMzNhNC00YzhkLWJmNWEtMDY1NGE1MDQxODg2IiwiYW1yIjpbImp3dF9iciJdfQ.aBrwKSZ09AqGqCNTE4NsAY-qDhflif94kcMEdq7zosZ7HRSFIggSOdRY8d9cvznGWsCp4hk4eKlihoUaHohMRKMwNW8dsmhPbff1t4Cm5xYEDTOOOrhA5ZC6bKJXBlLB5vhEga0yShMAY7ggbCOqxdCZH9pi3hp_1Z8G_8-7vQAPLfmqJo3tcdtyDXHfpdyJs5-4toxWiFtxX1VZS3I4tVre8w0P1QIpESDv-_-qHaE-4zniddCpg_CCR90ON83ZtBTG0HLQNj52YFAjKs5wm3nQrMC4V9C3vo9uyCSeBa9Lq0AgswFNoSLn7eiviRJB9iwSBx9Vuqx8xsOaKC9CMg', limitedAccessToken.token);
			System.assertEquals('https://apidownloaduatna11.springcm.com', limitedAccessToken.apiDownloadBaseUrl);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID, limitedAccessToken.entityId);
		}
	}


	@IsTest
	static void test_cancelApprovalOrExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateService.cancelApprovalOrExternalReview(NegotiateAPIMock.DOCUMENT_ID);
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
			Boolean result = NegotiateService.resendRequest('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17', 'ExternalReview');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_approveOnBehalfOrRecipientResponse_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateService.approveOnBehalfOrRecipientResponse('this is the comment', true,
				NegotiateAPIMock.WORKITEM_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_externalReviewCompleteOnBehalf_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			Boolean result = NegotiateService.externalReviewCompleteOnBehalf('this is the comment',
				NegotiateAPIMock.DOCUMENT_HREF, NegotiateAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}
}