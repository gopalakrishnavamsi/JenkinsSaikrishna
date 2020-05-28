@IsTest
private class FileControllerTest {

	@IsTest
	static void test_constructor() {
		Test.startTest();
		FileController result = new FileController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Application.namespace, result.namespace);
	}

	@IsTest
	static void test_saveChunk_failure() {
		System.runAs(UserMock.createUser()) {
			Id linkedEntityId = TestUtils.createLead().Id;

			Test.startTest();
			try {
				// Should fail because VersionData is null
				FileController.saveChunk(null, linkedEntityId, UUID.randomUUID().toString(), null);
				throw new AssertException('Expected saveChunk to fail');
			} catch (AuraHandledException ex) {
				System.assert(!String.isBlank(ex.getMessage()));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveChunk_success() {
		System.runAs(UserMock.createUser()) {
			Id linkedEntityId = TestUtils.createLead().Id;

			Test.startTest();
			ContentVersion result = FileController.saveChunk(null, linkedEntityId, UUID.randomUUID().toString(),
				EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString())));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);
			System.assertNotEquals(null, result.ContentDocumentId);
		}
	}
}
