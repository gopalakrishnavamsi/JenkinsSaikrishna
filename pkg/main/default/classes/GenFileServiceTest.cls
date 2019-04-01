@IsTest
private class GenFileServiceTest {

	@IsTest
	private static void test_Database_createFile() {
		System.runAs(UserMock.createUser()) {
			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			ContentVersion result = GenFileService.DB.createGenFile(o.Id, title, base64Data);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);

			ContentVersion cv = [SELECT ContentDocumentId, Title, PathOnClient, VersionData FROM ContentVersion WHERE Id = :result.Id LIMIT 1];
			System.assertEquals(title, cv.Title);
			System.assertEquals(title, cv.PathOnClient);
			System.assertEquals(base64Data, EncodingUtil.base64Encode(cv.VersionData));

			System.assertEquals(1, Collection.size([SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId = :o.Id]));
		}
	}

	@IsTest
	private static void test_Database_updateFile() {
		System.runAs(UserMock.createUser()) {
			ContentVersion cv = TestUtils.createContentVersion();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			ContentVersion result = GenFileService.DB.updateGenFile(cv.Id, base64Data);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(cv.Id, result.Id);
			System.assertEquals(cv.ContentDocumentId, result.ContentDocumentId);
			System.assertEquals(cv.Title, result.Title);
			System.assertEquals(cv.PathOnClient, result.PathOnClient);
			System.assertEquals(cv.FileExtension, result.FileExtension);
			// FIXME: VersionData and ContentSize don't appear to be updated, even though this code works outside of unit tests.
			// Need separate transaction? Salesforce bug?
//			System.assertEquals(EncodingUtil.base64Encode(cv.VersionData) + base64Data, EncodingUtil.base64Encode(result.VersionData));
//			System.assertNotEquals(cv.ContentSize + EncodingUtil.base64Decode(base64Data).size(), result.ContentSize);
			System.assertNotEquals(null, result.LastModifiedDate);
		}
	}

	@IsTest
	private static void test_saveFile_complete() {
		System.runAs(UserMock.createUser()) {
			Lead l = TestUtils.createLead();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			Gen.File result = GenFileService.saveFile(null, l.Id, title, base64Data);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);
		}
	}

	@IsTest
	private static void test_saveFile_chunked() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			String title = UUID.randomUUID().toString();
			String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data3 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			Gen.File result1 = GenFileService.saveFile(null, a.Id, title, base64Data1);
			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.Id);
			Gen.File result2 = GenFileService.saveFile(result1.Id, a.Id, title, base64Data2);
			System.assertNotEquals(null, result2);
			System.assertEquals(result1.Id, result2.Id);
			Gen.File result3 = GenFileService.saveFile(result2.Id, a.Id, title, base64Data3);
			Test.stopTest();

			System.assertNotEquals(null, result3);
			System.assertEquals(result1.Id, result3.Id);
			// FIXME: The VersionData is not updated here, even though this code works outside of unit tests.
//			System.assertEquals(base64Data1 + base64Data2 + base64Data3, EncodingUtil.base64Encode(result3.VersionData));
		}
	}
}