@IsTest
private class ResourceTokenAPITest {

	@IsTest
	static void test_getResourceToken_success() {
		GenAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Url result = ResourceTokenAPI.getInstance().getResourceToken(GenAPIMock.DOCUMENT_ID);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.toExternalForm().contains(GenAPIMock.DOCUMENT_ID.toString()));
		}
	}

	@IsTest
	static void test_getResourceToken_fail() {
		GenAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Boolean hasError = false;
			Test.startTest();
			try {
				Url result = ResourceTokenAPI.getInstance().getResourceToken(GenAPIMock.DOCUMENT_ID);
			} catch (APIException ex) {
				hasError = true;
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ResourceTokenAPI.Error);
				System.assert(UUID.isNotEmpty(((ResourceTokenAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
			System.assert(hasError);
		}
	}

}