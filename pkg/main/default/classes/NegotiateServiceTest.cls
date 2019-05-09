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

	@IsTest
	static void test_sendForExternalReview_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = NegotiateService.sendForExternalReview(new List<UUID> { UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41') },
				new List<String> { 'unittest@test.com' },
				'testSubject',
				'testBody', 8);
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
			testTaskStatus = NegotiateService.sendForExternalReview(new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
				new List<String> { 'unittest@test.com' },
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
			testTaskStatus = NegotiateService.sendForExternalReview(new List<UUID> { NegotiateAPIMock.DOCUMENT_ID_2 },
				new List<String> { 'unittest@test.com' },
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
			testTaskStatus = NegotiateService.sendForInternalApproval(new List<UUID> { UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41') },
				new List<String> { 'unittest@test.com' },
				'testSubject',
				'testBody');
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
			testTaskStatus = NegotiateService.sendForInternalApproval(new List<UUID> { NegotiateAPIMock.DOCUMENT_ID },
				new List<String> { 'unittest@test.com' },
				'testSubject',
				'testBody');
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
			testTaskStatus = NegotiateService.sendForInternalApproval(new List<UUID> { NegotiateAPIMock.DOCUMENT_ID_2 },
				new List<String> { 'unittest@test.com' },
				'testSubject',
				'testBody');
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
			System.assertEquals('Failed', testTaskStatus.status);
			System.assertEquals(Label.InternalApprovalFailed, testTaskStatus.message);

		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_success() {
		NegotiateAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Credentials.AccessToken token = NegotiateAPI.getHistoryAPIInstance().generateLimitedAccessToken(NegotiateAPIMock.DOCUMENT_ID, 'accessTokenExample');
			Test.stopTest();

			System.assertNotEquals(null, token);
			System.assertEquals('eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjY4MTg1ZmYxLTRlNTEtNGNlOS1hZjFjLTY4OTgxMjIwMzMxNyJ9.eyJUb2tlblR5cGUiOjUsIklzc3VlSW5zdGFudCI6MTU1NzM2MjYxOSwiZXhwIjoxNTU3MzY2MjE5LCJVc2VySWQiOiI5MTVjN2ViNi05M2IxLTQ2NGEtYjBkYS00OTBiMzc4YjQ2NzEiLCJzaXRlaWQiOjEsInNjcCI6WyJzaWduYXR1cmUiLCJpbXBlcnNvbmF0aW9uIiwic3ByaW5nX3JlYWQiLCJzcHJpbmdfd3JpdGUiXSwiYXVkIjoiYjI5YWJkZTYtYjhkYi00MDg1LWFlZGYtZDRlZmNiOTc2MWE5IiwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50LWQuZG9jdXNpZ24uY29tLyIsInN1YiI6IjkxNWM3ZWI2LTkzYjEtNDY0YS1iMGRhLTQ5MGIzNzhiNDY3MSIsImFjdCI6ImIyOWFiZGU2LWI4ZGItNDA4NS1hZWRmLWQ0ZWZjYjk3NjFhOSIsImFtciI6WyJqd3RfYnIiXX0.uzv3TWXs7WEu6cshk5Je8iwxxd_jgG9AESbOT4EKbmiYD9YFHoiyr2jMA26JrkCUKq6sm-SdJtRYK5qqgKuNI-CXBTsQidTIC2V7q_ggIMllHq_ta6FrJ1Zas-C0pKondqy0GTdtWPVz0yFDk4qo51j_WimnaU8d9WcliKinUmdU05T0A5QyEKfZhN9Ji39hYGbUQDGDbdvEYbbQgTlr0-8PQnaSKVNBtB2Kl3ttGZJTK0ijRIhLmDvBOSK0n0guNHEx0aYy9HxnkeBwX8kU-Nuixk54TAHKU0Z6M_t-3xNNVMyvRRRFwlj2JzZW4j08xoyHZ7VnN1tkAjCZHzVJTA', token.token);
			System.assert(token.isValid);
		}
	}

}