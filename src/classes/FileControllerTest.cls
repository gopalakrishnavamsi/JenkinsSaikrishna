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
		System.assert(!result.uploadFinished);
		System.assertEquals(null, result.contentDocumentId);
		System.assertEquals(null, result.contentDocumentTitle);
		System.assertEquals(null, result.message);
		System.assertEquals(null, result.messageType);
		System.assertEquals(null, result.contentVersion);
	}

	@IsTest
	static void test_getContentVersion() {
		FileController fc = new FileController();

		Test.startTest();
		ContentVersion result = fc.getContentVersion();
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@IsTest
	static void test_uploadFile_success() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			ContentVersion cv = new ContentVersion(
				Title = UUID.randomUUID().toString(),
				PathOnClient = UUID.randomUUID().toString() + '.pdf',
				VersionData = Blob.valueOf(UUID.randomUUID().toString())
			);
			FileController fc = new FileController();
			fc.contentVersion = cv;
			PageReference pg = Page.FileUploader;
			pg.getParameters().put('Id', a.Id);
			Test.setCurrentPage(pg);

			Test.startTest();
			fc.uploadFile();
			Test.stopTest();

			System.assert(fc.uploadFinished);
			System.assertNotEquals(null, fc.contentDocumentId);
			System.assertEquals(cv.Title, fc.contentDocumentTitle);
			System.assertEquals(Label.UploadSuccessful, fc.message);
			System.assertEquals('SUCCESS', fc.messageType);

			List<ContentDocumentLink> cdls = [
				SELECT Id
				FROM ContentDocumentLink
				WHERE ContentDocumentId = :fc.contentDocumentId AND LinkedEntityId = :a.Id
			];
			System.assertNotEquals(null, cdls);
			System.assertEquals(1, cdls.size());
		}
	}

	@IsTest
	static void test_uploadFile_error() {
		System.runAs(UserMock.createUser()) {
			FileController fc = new FileController();
			PageReference pg = Page.FileUploader;
			Test.setCurrentPage(pg);

			Test.startTest();
			fc.uploadFile();
			Test.stopTest();

			System.assert(fc.uploadFinished);
			System.assertEquals('ERROR', fc.messageType);
			System.assertEquals(Label.SomethingWrong, fc.message);
		}
	}

	@IsTest
	static void test_uploadFile_file_size_limit_reached() {
		System.runAs(UserMock.createUser()) {
			FileController fc = new FileController();
			PageReference pg = Page.FileUploader;
			Test.setCurrentPage(pg);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FileSizeLimitReached));

			Test.startTest();
			fc.uploadFile();
			Test.stopTest();

			System.assert(fc.uploadFinished);
			System.assertEquals('ERROR', fc.messageType);
			System.assertEquals(Label.FileSizeLimit, fc.message);
		}
	}

	@IsTest
	static void test_getVisualforceHost(){
		System.runAs(UserMock.createUser()) {
			String testVisualForceHost = FileController.getVisualForceHost();
			System.assert(String.isNotBlank(testVisualForceHost));
		}
	}
}
