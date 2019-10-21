@IsTest
public with sharing class NegotiateAPITest {
	
	// FIXME: Missing tests for some public methods.

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			NegotiateAPI result1 = NegotiateAPI.getInstance();
			NegotiateAPI result2 = NegotiateAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_createEOSFolder_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().createEOSFolder('Edge Installation', ScmAPIMock.OBJECT_ID, 'Opportunity');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(ScmAPIMock.FOLDER_ID, result);

		}
	}

	@IsTest
	static void test_createEOSFolder_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			try {
				NegotiateAPI.getInstance().createEOSFolder('Edge Installation', ScmAPIMock.OBJECT_ID, 'Opportunity');
				throw new AssertException('Expected createEOSFolder to fail');
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
	static void test_createAgreementInEOSFolder_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().createAgreementInEOSFolder(ScmAPIMock.OBJECT_ID,
				ScmAPIMock.FOLDER_ID, 'negotiate.docx');
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals(UUID.parse('4682d399-29fe-4085-9e48-126e4ffa0566'), result);
		}
	}

	@IsTest
	static void test_exportAgreementToSalesforce_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().exportAgreementToSalesforce(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals(UUID.parse('4682d399-29fe-4085-9e48-126e4ffa0566'), result);
		}
	}

	@IsTest
	static void test_getAgreementInEOSFolderStatus_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getAgreementInEOSFolderStatus(ScmAPIMock.TASK_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
		}
	}

	@IsTest
	static void test_getExportAgreementToSalesforceStatus_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getExportAgreementToSalesforceStatus(ScmAPIMock.TASK_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
			System.assertEquals('Document exported successfully', result.message);

		}
	}

	@IsTest
	static void test_getAgreementInEOSFolderStatus_success2() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getAgreementInEOSFolderStatus(ScmAPIMock.TASK_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Processing', result.status);
		}
	}

	@IsTest
	static void test_getExportAgreementToSalesforceStatus_success2() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getExportAgreementToSalesforceStatus(ScmAPIMock.TASK_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Processing', result.status);
		}
	}

	@IsTest
	static void test_getAgreements_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<Agreement> result = NegotiateAPI.getInstance().getAgreements(ScmAPIMock.FOLDER_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals('docusignlogerror7-23-18-1', result.get(0).name);
			System.assertEquals('docx', result.get(0).extension);
			System.assertEquals(UUID.parse('ea7ab407-ea41-e911-9c1d-3ca82a1e3f41'), result.get(0).id);
			System.assertEquals(160453, result.get(0).pdfFileSize);
			System.assertEquals('https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41', result.get(0).href);
		}
	}

	@IsTest
	static void test_getAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Agreement agreement = NegotiateAPI.getInstance().getAgreement(ScmAPIMock.DOCUMENT_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, agreement);
			System.assertEquals('ServiceDoc1', agreement.name);
			System.assertEquals('docx', agreement.extension);
			System.assertEquals(ScmAPIMock.DOCUMENT_ID_2, agreement.id);
			System.assertEquals(160568, agreement.pdfFileSize);
			System.assertEquals('https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e922-9c1d-3ca82a1e3f41', agreement.href);
		}
	}

	@IsTest
	static void test_renameAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().renameAgreement(ScmAPIMock.DOCUMENT_ID, 'docuTestRename.docx');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_deleteAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().deleteAgreement(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_getAgreementVersions_success() {

		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			List<Agreement> result = NegotiateAPI.getInstance().getAgreementVersions(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertEquals('newName', result.get(0).name);
			System.assertEquals('docx', result.get(0).extension);
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
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			UUID result = NegotiateAPI.getInstance().sendForApproval('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { ScmAPIMock.DOCUMENT_ID },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) }
				, 'Test subject'
				, 'Test message body: hello world', true);
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().sendForExternalReview('Test Agreement',
				ScmAPIMock.SOURCE_OBJECT_ID,
				new List<UUID> { ScmAPIMock.DOCUMENT_ID },
				new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
				'Test subject', 'Test message body: hello world',
				5);
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendForApproval_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().sendForApproval('Test Agreement',
					ScmAPIMock.SOURCE_OBJECT_ID,
					new List<UUID> { ScmAPIMock.DOCUMENT_ID },
					new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
					'Test subject',
					'Test message body: hello world', true);
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

	@IsTest
	static void test_sendForExternalReview_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().sendForExternalReview('Test Agreement',
					ScmAPIMock.SOURCE_OBJECT_ID,
					new List<UUID> { ScmAPIMock.DOCUMENT_ID },
					new List<Recipient> { Recipient.newBulkRecipient('Test User', 'Test@Test.com', new Entity(UserInfo.getUserId())) },
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

	@IsTest
	static void test_getApprovalWorkItems_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			List<AgreementApprovalWorkItem> approvalWorkItems = NegotiateAPI.getInstance().getApprovalWorkItems(ScmAPIMock.APPROVAL_DOCUMENT_ID);
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
	static void test_resolveApproverDetails_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {
			String result;
			Test.startTest();
			result = NegotiateAPI.getInstance().resolveApproverDetails(ScmAPIMock.APPROVER_USER_1);
			Test.stopTest();
			System.assertNotEquals(null, result);
			NegotiateAPI.APIMemberDetails memberResult = (NegotiateAPI.APIMemberDetails)JSON.deserialize(result, NegotiateAPI.APIMemberDetails.class);
			System.assertNotEquals(null, memberResult);
		}
	}

	@IsTest
	static void test_cancelApprovalOrExternalReview_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().cancelApprovalOrExternalReview(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);
		}
	}

	@IsTest
	static void test_approveOnBehalfOrRecipientResponse_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().approveOnBehalfOrRecipientResponse('this is the comment',
				'Approve', ScmAPIMock.WORKITEM_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);

		}
	}

	@IsTest
	static void test_externalReviewCompleteOnBehalf_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			Boolean result = NegotiateAPI.getInstance().externalReviewCompleteOnBehalf('this is the comment',
				ScmAPIMock.DOCUMENT_HREF, ScmAPIMock.EXTERNAL_REVIEW_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(true, result);
		}
	}

	@IsTest
	static void test_getDocumentReview_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			UUID result = NegotiateAPI.getInstance().getDocumentReview(ScmAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(ScmAPIMock.EXTERNAL_REVIEW_ID, result);
		}
	}

	@IsTest
	static void test_compareAgreements_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			UUID compareTaskID = NegotiateAPI.getInstance().compareAgreements(ScmAPIMock.ORIGINAL_DOCUMENT_HREF, ScmAPIMock.COMPARE_VERSION_HREF);
			System.assertNotEquals(null, compareTaskID);
			System.assertEquals(ScmAPIMock.COMPARE_TASK_ID, compareTaskID);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_compareAgreements_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().compareAgreements('', ScmAPIMock.COMPARE_VERSION_HREF);
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

	@IsTest
	static void test_getCompareAgreementsStatus_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator()) {

			Test.startTest();
			NegotiateAPI.TaskStatus result = NegotiateAPI.getInstance().getCompareAgreementsStatus(ScmAPIMock.COMPARE_TASK_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
		}
	}

	@IsTest
	static void test_getCompareAgreementsStatus_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().getCompareAgreementsStatus(ScmAPIMock.COMPARE_TASK_ID);
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

	@IsTest
	static void test_getRootLevelFolderUrl_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {

			Test.startTest();
			Url result = NegotiateAPI.getInstance().getRootLevelFolderUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41', result.toExternalForm());
		}
	}

	@IsTest
	static void test_getRootLevelFolderUrl_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().getRootLevelFolderUrl();
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

	@IsTest
	static void test_triggerChangeSecurityTask_success() {
		ScmAPIMock.success();

		Boolean executedSuccessfully = false;
		System.runAs(UserMock.createDocuSignAdministrator()) {

			Test.startTest();
			NegotiateAPI.getInstance().triggerChangeSecurityTask(new Url('https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41'));
			executedSuccessfully = true;
			Test.stopTest();

			System.assertEquals(true, executedSuccessfully);
		}
	}

	@IsTest
	static void test_triggerChangeSecurityTask_failure() {
		ScmAPIMock.failure();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Boolean hasError = false;
			try {
				NegotiateAPI.getInstance().triggerChangeSecurityTask(new Url('https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41'));
			} catch (APIException ex) {
				hasError = true;
			}
			Test.stopTest();

			System.assertEquals(hasError, true);
		}
	}

}
