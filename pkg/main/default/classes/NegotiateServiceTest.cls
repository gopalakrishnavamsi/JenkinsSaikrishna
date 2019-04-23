@IsTest
public with sharing class NegotiateServiceTest {

	@IsTest
	static void test_getAgreements_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {

			Test.startTest();
			List<Agreement> result = NegotiateService.getAgreements(NegotiateAPIMock.FOLDER_ID_2);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals('ServiceDoc1.docx', result.get(0).name);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID_2, result.get(0).id);
			System.assertEquals('2019-05-25 11:13:28', String.valueOf(result.get(0).modifiedDate));
			System.assertEquals(AgreementStatus.PENDING_REVIEW, result.get(0).status);
			System.assertEquals(2, result.get(0).historyItems.size());
			System.assertEquals(AgreementHistoryItem.Action.ExternalReviewInitiated, result.get(0).historyItems.get(0).historyItemType);
			System.assertEquals(AgreementHistoryItem.Action.DocumentImportedFromSalesforce, result.get(0).historyItems.get(1).historyItemType);
			System.assertEquals('ServiceDoc2.docx', result.get(1).name);
			System.assertEquals(NegotiateAPIMock.DOCUMENT_ID_3, result.get(1).id);
			System.assertEquals(AgreementStatus.PENDING_APPROVAL, result.get(1).status);
			System.assertEquals(4, result.get(1).historyItems.size());
			System.assertEquals(AgreementHistoryItem.Action.WorkflowApproved, result.get(1).historyItems.get(0).historyItemType);
			System.assertEquals(AgreementHistoryItem.Action.ApprovalCheckout, result.get(1).historyItems.get(2).historyItemType);
		}
	}
}