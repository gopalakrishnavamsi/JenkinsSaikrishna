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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getNameSpace_success() {
		System.runAs(UserMock.createDocuSignNegotiator(false)) {

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
				AgreementsController.getAgreement(ScmAPIMock.DOCUMENT_ID_2.value);
				throw new AssertException('Expected get Agreement to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {

			Test.startTest();
			Agreement agreement = AgreementsController.getAgreement(ScmAPIMock.DOCUMENT_ID_2.value);
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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreements_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLinkedDocuments_success() {

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.createAgreementInEOSFolder(UserInfo.getUserId(), UserInfo.getUserId(), 'testName');
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

	@IsTest
	static void test_exportAgreementToSalesforce_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.exportAgreementToSalesforce(UserInfo.getUserId(), '382bd222-1536-e911-9c1d-3ca82a1e3f41');
				throw new AssertException('Expected createAgreementInEOSFolder to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_exportAgreementToSalesforce_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.exportAgreementToSalesforce(UserInfo.getUserId(), '382bd222-1536-e911-9c1d-3ca82a1e3f41');
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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_renameAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
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
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveRecipient_success() {
		System.runAs(UserMock.createDocuSignNegotiator(true)) {
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
				AgreementsController.sendForExternalReview('Test Agreement', ScmAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
					'[{"email":"unittest@test.com", "name":"test user"}]',
					'testSubject',
					'testBody', 8);
				throw new AssertException('Expected sendForExternalReview to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendForExternalReview_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.sendForExternalReview('Test Agreement', ScmAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
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
				AgreementsController.internalApproval('Test Agreement', ScmAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
					'[{"email":"unittest@test.com", "name":"test user"}]',
					'testSubject',
					'testBody', true);
				throw new AssertException('Expected sendForInternalApproval to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectToAgreementPreview() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			String link = AgreementsController.redirectToAgreementPreview(ScmAPIMock.OBJECT_ID, ScmAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(null, link);
			System.assertEquals(link.startsWith(Site.getBaseUrl()), true);
			System.assertEquals(link.contains('sourceId=' + ScmAPIMock.OBJECT_ID), true);
			System.assertEquals(link.contains('agreementId=' + ScmAPIMock.DOCUMENT_ID.value), true);
		}
	}

	@IsTest
	static void test_sendForInternalApproval_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = AgreementsController.internalApproval('Test Agreement', ScmAPIMock.SOURCE_OBJECT_ID, new List<String> { '22222efe-e541-e911-9c1d-3ca82a1e3f41' },
				'[{"email":"unittest@test.com", "name":"test user"}]',
				'testSubject',
				'testBody', true);
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

	@IsTest
	static void test_generateUploadToken_success() {
		ScmAPIMock.success();
		TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID_2, ScmAPIMock.FOLDER_ID_2.toString());
		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			Negotiate.LimitedAccessToken limitedAccessToken = AgreementsController.generateUploadToken(ScmAPIMock.SOURCE_OBJECT_ID_2);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateUploadToken_nonDocuSignNegotiateUser() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.generateUploadToken(ScmAPIMock.SOURCE_OBJECT_ID_2);
				throw new AssertException('Expected generate upload token to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateDownloadToken_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			Negotiate.LimitedAccessToken limitedAccessToken = AgreementsController.generateDownloadToken(ScmAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateDownloadToken_nonDocuSignNegotiateUser() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.generateDownloadToken(ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected generate download token to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateUploadNewVersionToken_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			Negotiate.LimitedAccessToken limitedAccessToken = AgreementsController.generateUploadNewVersionToken(ScmAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateUploadNewVersionToken_nonDocuSignNegotiateUser() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.generateUploadNewVersionToken(ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected generate upload new version token to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateResourceToken_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			String result = AgreementsController.generateResourceToken(ScmAPIMock.DOCUMENT_ID.toString());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.contains(ScmAPIMock.DOCUMENT_ID.toString()));
		}
	}

	@IsTest
	static void test_generateResourceToken_fail() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Boolean hasError = false;
			Test.startTest();
			try {
				AgreementsController.generateResourceToken(ScmAPIMock.DOCUMENT_ID.toString());
			} catch (Exception ex) {
				hasError = true;
			}
			Test.stopTest();
			System.assert(hasError);
		}
	}

	@IsTest
	static void test_getIsCurrentUserDocuSignAdmin_positive() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			Boolean result = AgreementsController.getIsCurrentUserDocuSignAdmin();
			Test.stopTest();
			System.assertEquals(result, true);
		}
	}

	@IsTest
	static void test_getIsCurrentUserDocuSignAdmin_negative() {
		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			Boolean result = AgreementsController.getIsCurrentUserDocuSignAdmin();
			Test.stopTest();
			System.assertEquals(result, false);
		}
	}

	@IsTest
	static void test_resendRequest_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.resendRequest('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17', 'xyz');
				throw new AssertException('Expected resend Agreement to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendRequest_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {

			Test.startTest();
			Boolean result = AgreementsController.resendRequest('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17', 'ExternalReview');
			Test.stopTest();
			System.assert(result);
		}
	}

	@IsTest
	static void test_cancelApprovalOrExternalReview_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.cancelApprovalOrExternalReview(ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected cancel request to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_cancelApprovalOrExternalReview_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {

			Test.startTest();
			Boolean result = AgreementsController.cancelApprovalOrExternalReview(ScmAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assert(result);
		}
	}

	@IsTest
	static void test_getApprovalWorkItems_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			List<AgreementApprovalWorkItem> approvalWorkItems = AgreementsController.getApprovalWorkItems(String.valueOf(ScmAPIMock.APPROVAL_DOCUMENT_ID));
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
	static void test_getApprovalWorkItems_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.getApprovalWorkItems(ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected getApprovalWorkItems request to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_approveOnBehalfOrRecipientResponse_success() {
		ScmAPIMock.success();
		User user = UserMock.createDocuSignAdministrator();
		System.runAs(user) {
			Permissions.assignDocuSignNegotiatorPermissionSet(new Set<Id> { user.Id });
			Test.startTest();
			Boolean result = AgreementsController.approveOnBehalfOrRecipientResponse('Test comment', true, ScmAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assert(result);
		}
	}

	@IsTest
	static void test_approveOnBehalfOrRecipientResponse_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.approveOnBehalfOrRecipientResponse('Test comment', true, ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected approveOnBehalfOrRecipientResponse request to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreementShareLink_success() {
		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			String result = AgreementsController.getAgreementShareLink(UserInfo.getUserId(), ScmAPIMock.DOCUMENT_ID.value);
			Test.stopTest();
			System.assertNotEquals(result, null);
		}
	}

	@IsTest
	static void test_getAgreementShareLink_nonDocuSignNegotiateUser() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.getAgreementShareLink(UserInfo.getUserId(), ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected getAgreementShareLink to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_compareAgreements_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			Test.startTest();
			String result = AgreementsController.compareAgreements(ScmAPIMock.ORIGINAL_DOCUMENT_HREF, ScmAPIMock.COMPARE_VERSION_HREF);
			Test.stopTest();

			System.assert(String.isNotBlank(result));
		}
	}

	@IsTest
	static void test_compareAgreements_nonDocuSignNegotiateUser() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.compareAgreements(UserInfo.getUserId(), ScmAPIMock.DOCUMENT_ID.value);
				throw new AssertException('Expected compareAgreements to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_externalReviewOnBehalfOfRequest_Success() {
		ScmAPIMock.success();
		User user = UserMock.createDocuSignAdministrator();
		System.runAs(user) {
			Permissions.assignDocuSignNegotiatorPermissionSet(new Set<Id> { user.Id });
			Test.startTest();
			Boolean isExternalReviewCompleted = AgreementsController.externalReviewOnBehalfOfRequest('Test Comment', ScmAPIMock.DOCUMENT_HREF.toExternalForm(), String.valueOf(ScmAPIMock.DOCUMENT_ID));
			Test.stopTest();
			System.assertEquals(isExternalReviewCompleted, true);
		}
	}

	@IsTest
	static void test_externalReviewOnBehalfOfRequest_Failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AgreementsController.externalReviewOnBehalfOfRequest('Test Comment', ScmAPIMock.DOCUMENT_HREF.toExternalForm(), String.valueOf(ScmAPIMock.DOCUMENT_ID));
				throw new AssertException('Expected externalreview on behalf of to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSourceDetails() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Entity testSourceEntity = Entity.resolve(a.Id);
			PageReference pageRef = Page.Agreements;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('sId', testSourceEntity.id);
			Test.startTest();
			AgreementsController controller = new AgreementsController();
			System.assertEquals(controller.sourceEntity.typeName, testSourceEntity.typeName);
			System.assertEquals(controller.sourceEntity.name, testSourceEntity.name);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSendingDeepLink() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			String title = UUID.randomUUID().toString();
			String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data3 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			ContentVersion result1 = FileService.saveFile(null, a.Id, title, base64Data1);
			ContentVersion result2 = FileService.saveFile(null, a.Id, title, base64Data2);
			ContentVersion result3 = FileService.saveFile(null, a.Id, title, base64Data3);

			String fileIdsInCommaSeparated = String.Join(new List<String> { result1.ContentDocumentId, result2.ContentDocumentId, result3.ContentDocumentId }, ',');

			Test.startTest();
			Pagereference ref = new PageReference(AgreementsController.getSendingDeepLink(a.Id, fileIdsInCommaSeparated));
			Test.stopTest();

			System.assertEquals((Id)ref.getParameters().get('sid'), a.id);
			System.assertEquals(EncodingUtil.urlDecode(ref.getParameters().get('files'), StringUtils.ENCODING), fileIdsInCommaSeparated);
		}
	}
}
