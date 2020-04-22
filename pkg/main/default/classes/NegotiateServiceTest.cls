@IsTest
private class NegotiateServiceTest {

	@IsTest
	static void test_getAgreements_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.FOLDER_ID_2.toString(), null);
			Test.startTest();
			List<Agreement> result = NegotiateService.getAgreements(ScmAPIMock.SOURCE_OBJECT_ID);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_getAgreement_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Agreement result = NegotiateService.getAgreement(ScmAPIMock.DOCUMENT_ID_2);
			System.assertNotEquals(null, result);
			System.assertEquals('ServiceDoc1', result.name);
			System.assertEquals('docx', result.extension);
			System.assertEquals(ScmAPIMock.DOCUMENT_ID_2, result.id);
			System.assertEquals('2019-05-25 11:13:28', String.valueOf(result.modifiedDate));
			System.assertEquals(AgreementStatus.PENDING_REVIEW, result.status);
			System.assertEquals(2, result.historyItems.size());
			System.assertEquals(AgreementHistoryItem.ExternalReviewInitiated, result.historyItems.get(0).historyItemType);
			System.assertEquals(AgreementHistoryItem.DocumentImportFromSalesforce, result.historyItems.get(1).historyItemType);
			System.assertNotEquals(null, result.versions);
			System.assertEquals(false, result.versions.isEmpty());
			System.assertEquals('newName', result.versions.get(0).name);
			System.assertEquals('docx', result.versions.get(0).extension);

			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID_2, ScmAPIMock.FOLDER_ID_2.toString(), null);
			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateService.createAgreementInEOSFolder(ScmAPIMock.SOURCE_OBJECT_ID_2, ScmAPIMock.SOURCE_OBJECT_ID_2, 'Test_DOC_Name');
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
			System.assertEquals(Label.AgreementImportSuccessful, result.message);
		}
	}

	@IsTest
	static void test_exportAgreementToSalesforce_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID_2, ScmAPIMock.FOLDER_ID_2.toString(), null);
			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateService.exportAgreementToSalesforce(ScmAPIMock.SOURCE_OBJECT_ID_2, ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
			System.assertEquals(Label.AgreementExportSuccessful, result.message);
		}
	}

	@IsTest
	static void test_renameAgreement_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateService.renameAgreement(ScmAPIMock.DOCUMENT_ID, 'docuTestRename.docx');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_deleteAgreement_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateService.deleteAgreement(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_compareAgreements_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			UUID result = NegotiateService.compareAgreements(ScmAPIMock.ORIGINAL_DOCUMENT_HREF, ScmAPIMock.COMPARE_VERSION_HREF);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(ScmAPIMock.COMPARE_TASK_ID, result);

		}
	}

	@IsTest
	static void test_compareAgreements_failure() {
		DocuSignAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateService.compareAgreements(ScmAPIMock.ORIGINAL_DOCUMENT_HREF, ScmAPIMock.COMPARE_VERSION_HREF);
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

	@IsTest
	static void test_compareAgreements_invalidInputs() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean hasError = false;
			String errorMessage = '';
			try {
				NegotiateService.compareAgreements('', ScmAPIMock.COMPARE_VERSION_HREF);
			} catch (APIException ex) {
				hasError = true;
				errorMessage = ex.getMessage();
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
			System.assertEquals(errorMessage, Label.InvalidInputsAgreementComparison);

		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41') },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
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
	static void test_getCompareUrl_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Url result = NegotiateService.getCompareUrl(ScmAPIMock.COMPARE_TASK_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(true, result.toExternalForm().contains(String.valueOf(ScmAPIMock.COMPARE_TASK_ID)));

		}
	}

	@IsTest
	static void test_getCompareUrl_failure() {
		DocuSignAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateService.getCompareUrl(ScmAPIMock.COMPARE_TASK_ID);
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

	@IsTest
	static void test_sendForExternalReview_executing() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { ScmAPIMock.DOCUMENT_ID },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
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
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { ScmAPIMock.DOCUMENT_ID_2 },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
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
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForInternalApproval('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41') },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
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
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForInternalApproval('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { ScmAPIMock.DOCUMENT_ID },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
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
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForInternalApproval('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { ScmAPIMock.DOCUMENT_ID_2 },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
				'testSubject',
				'testBody', true);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Failed', testTaskStatus.status);
			System.assertEquals(Label.InternalApprovalFailed, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_getApprovalWorkItems_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			List<AgreementApprovalWorkItem> approvalWorkItems = NegotiateService.getApprovalWorkItems(ScmAPIMock.APPROVAL_DOCUMENT_ID);
			Test.stopTest();
			System.assertNotEquals(null, approvalWorkItems);
			System.assertNotEquals(null, approvalWorkItems[0].workItemUrl);
			System.assertNotEquals(null, approvalWorkItems[1].workItemUrl);
			System.assertNotEquals(null, approvalWorkItems[0].email);
			System.assertNotEquals(null, approvalWorkItems[1].email);
			System.assertEquals(2, approvalWorkItems.size());
		}
	}

	@IsTest
	static void test_getAgreementPreviewLink() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			String link = NegotiateService.getAgreementPreviewLink(ScmAPIMock.OBJECT_ID, ScmAPIMock.DOCUMENT_ID.value, false);
			Test.stopTest();
			System.assertNotEquals(null, link);
			System.assertEquals(link.contains('sourceId=' + ScmAPIMock.OBJECT_ID), true, link);
			System.assertEquals(link.contains('agreementId=' + ScmAPIMock.DOCUMENT_ID.value), true, link);
		}
	}

	@IsTest
	static void test_getAgreementShareLink() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			String link = NegotiateService.getAgreementPreviewLink(ScmAPIMock.OBJECT_ID, ScmAPIMock.DOCUMENT_ID.value, true);
			Test.stopTest();
			System.assertNotEquals(null, link);
			System.assertEquals(link.startsWith(Site.getBaseUrl()), true);
			System.assertEquals(link.contains('sourceId=' + ScmAPIMock.OBJECT_ID), true, link);
			System.assertEquals(link.contains('agreementId=' + ScmAPIMock.DOCUMENT_ID.value), true, link);
		}
	}

	@IsTest
	static void test_generateUploadToken_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID_2, ScmAPIMock.FOLDER_ID_2.toString(), null);
			Test.startTest();
			LimitedAccessToken limitedAccessToken = NegotiateService.generateUploadToken(ScmAPIMock.SOURCE_OBJECT_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assert(String.isNotBlank(limitedAccessToken.token));
			System.assert(String.isNotBlank(limitedAccessToken.apiUploadBaseUrl));
			System.assertEquals(ScmAPIMock.FOLDER_ID_2, limitedAccessToken.entityId);
		}
	}

	@IsTest
	static void test_generateDownloadToken_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			LimitedAccessToken limitedAccessToken = NegotiateService.generateDownloadToken(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assert(String.isNotBlank(limitedAccessToken.token));
			System.assert(String.isNotBlank(limitedAccessToken.apiDownloadBaseUrl));
			System.assertEquals(ScmAPIMock.DOCUMENT_ID, limitedAccessToken.entityId);
		}
	}

	@IsTest
	static void test_generateUploadNewVersionToken_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			LimitedAccessToken limitedAccessToken = NegotiateService.generateUploadNewVersionToken(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assert(String.isNotBlank(limitedAccessToken.token));
			System.assert(String.isNotBlank(limitedAccessToken.apiUploadBaseUrl));
			System.assertEquals(ScmAPIMock.DOCUMENT_ID, limitedAccessToken.entityId);
		}
	}

	@IsTest
	static void test_cancelApprovalOrExternalReview_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateService.cancelApprovalOrExternalReview(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_resendRequest_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateService.resendRequest('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17', 'ExternalReview');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_approveOnBehalfOrRecipientResponse_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Boolean result = NegotiateService.approveOnBehalfOrRecipientResponse('this is the comment', true,
				ScmAPIMock.WORKITEM_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_approveOnBehalfOrRecipientResponse_failure() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Boolean hasError = false;
			String errorMessage = '';
			Test.startTest();
			try {
				NegotiateService.approveOnBehalfOrRecipientResponse('this is the comment', true,
					ScmAPIMock.WORKITEM_ID);
			} catch (Exception ex) {
				hasError = true;
				errorMessage = ex.getMessage();
			}
			Test.stopTest();
			System.assertEquals(hasError, true);
			System.assertEquals(errorMessage, Label.MustBeDocuSignNegotiator);
		}
	}

	@IsTest
	static void test_externalReviewCompleteOnBehalf_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Boolean result = NegotiateService.externalReviewCompleteOnBehalf('this is the comment',
				ScmAPIMock.DOCUMENT_HREF, ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_getResourceToken_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			String result = NegotiateService.getResourceToken(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.contains(ScmAPIMock.DOCUMENT_ID.toString()));
		}
	}

	@IsTest
	static void test_getResourceToken_fail() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Boolean hasError = false;
			Test.startTest();
			try {
				NegotiateService.getResourceToken(ScmAPIMock.DOCUMENT_ID);
			} catch (APIException ex) {
				hasError = true;
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ScmAPI.Error);
				System.assert(UUID.isNotEmpty(((ScmAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
			System.assert(hasError);
		}
	}
}
