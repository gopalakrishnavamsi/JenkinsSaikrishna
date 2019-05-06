@IsTest
public with sharing class NegotiateServiceTest {

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
			System.assertNotEquals(null,  result.get(0).versions);
			System.assertEquals(false,  result.get(0).versions.isEmpty());
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
}