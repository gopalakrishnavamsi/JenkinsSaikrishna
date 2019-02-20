@IsTest
private class FileControllerTest {

	@IsTest
	static void test_constructor() {
		Test.startTest();
		FileController result = new FileController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Application.lightningNamespace, result.namespace);
		System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
		System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
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
			Id result = FileController.saveChunk(null, linkedEntityId, UUID.randomUUID().toString(),
				EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString())));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(ContentVersion.getSObjectType(), result.getSobjectType());
			System.assertEquals(1, Collection.size([SELECT Id FROM ContentVersion WHERE Id = :result]));
		}
	}
}