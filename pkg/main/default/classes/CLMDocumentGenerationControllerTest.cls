@IsTest
private with sharing class CLMDocumentGenerationControllerTest {

	@IsTest
	static void test_getDocumentGenerationLink_authorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createClmUser()) {
			Test.startTest();
			System.assertNotEquals(null,CLMDocumentGenerationController.getDocGenButtonLink());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getDocumentGenerationLink_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				CLMDocumentGenerationController.getDocGenButtonLink();
			}
			catch (exception e) {
				System.assertEquals(Label.MustBeClmUser, e.getMessage());
			}
			Test.stopTest();
		}
	}
}