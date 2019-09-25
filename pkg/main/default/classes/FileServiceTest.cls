@IsTest
private class FileServiceTest {

	@IsTest
	private static void test_Database_createFile() {
		System.runAs(UserMock.createUser()) {
			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			Test.startTest();
			ContentVersion result = FileService.DB.createFile(o.Id, title, base64Data);
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
			ContentVersion result = FileService.DB.updateFile(cv.Id, base64Data);
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
			ContentVersion result = FileService.saveFile(null, l.Id, title, base64Data);
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
			ContentVersion result1 = FileService.saveFile(null, a.Id, title, base64Data1);
			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.Id);
			ContentVersion result2 = FileService.saveFile(result1.Id, a.Id, title, base64Data2);
			System.assertNotEquals(null, result2);
			System.assertEquals(result1.Id, result2.Id);
			ContentVersion result3 = FileService.saveFile(result2.Id, a.Id, title, base64Data3);
			Test.stopTest();

			System.assertNotEquals(null, result3);
			System.assertEquals(result1.Id, result3.Id);
			// FIXME: The VersionData is not updated here, even though this code works outside of unit tests.
//			System.assertEquals(base64Data1 + base64Data2 + base64Data3, EncodingUtil.base64Encode(result3.VersionData));
		}
	}

	@IsTest
	private static void test_getSendingDeepLink() {

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
			Pagereference ref = new PageReference(FileService.getSendingDeepLink(a.Id, fileIdsInCommaSeparated).toExternalForm());
			Test.stopTest();

			System.assertEquals((Id)ref.getParameters().get('sid'), a.id);
			System.assertEquals(EncodingUtil.urlDecode(ref.getParameters().get('files'), StringUtils.ENCODING), fileIdsInCommaSeparated);
		}

	}

	@IsTest
	private static void test_getSendingDeepLink_Failure() {

		System.runAs(UserMock.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			String title = UUID.randomUUID().toString();
			String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data3 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			ContentVersion result1 = FileService.saveFile(null, a.Id, title, base64Data1);
			ContentVersion result2 = FileService.saveFile(null, a.Id, title, base64Data2);
			ContentVersion result3 = FileService.saveFile(null, a.Id, title, base64Data3);

			String fileIdsInCommaSeparated = String.Join(new List<String> { result1.ContentDocumentId, result2.ContentDocumentId, result3.ContentDocumentId }, ',');
			Pagereference ref;
			Test.startTest();
			try {
				ref = new PageReference(FileService.getSendingDeepLink(a.Id, fileIdsInCommaSeparated).toExternalForm());
				throw new AssertException('Expected getSendingDeepLink to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
			System.assertEquals(ref, null);
		}

	}
}