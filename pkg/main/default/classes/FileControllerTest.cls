@IsTest
private class FileControllerTest {

	final static Integer offset = 0;
	final static Integer countOfRecords = 5;

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

	@IsTest
	static void test_getFilesOwnedByUser_success() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			ContentVersion result = FileService.DB.createFile(o.Id, title, base64Data);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);

			Test.startTest();
			List<ContentDocument> docs = FileController.getFilesOwnedByUser(offset, countOfRecords);
			Test.stopTest();

			System.assertEquals(1, docs.size(), 'Should retrieve files owned by user');
		}
	}

	@IsTest
	private static void test_getFilesOwnedByUser_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.getFilesOwnedByUser(offset, countOfRecords);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_getFilesSharedWithUser_success() {
		User u = UserMock.createDocuSignUser();
		Opportunity o = TestUtils.createOpportunity();

		String title = UUID.randomUUID().toString();
		String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
		ContentVersion cv = FileService.DB.createFile(o.Id, title, base64Data);
		System.assertNotEquals(null, cv);
		System.assertNotEquals(null, cv.Id);

		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = cv.ContentDocumentId;
		cdl.LinkedEntityId = u.Id;
		cdl.ShareType = 'V';
		insert cdl;
		System.assertNotEquals(null, cdl.Id);

		System.runAs(u) {
			Test.startTest();
			List<ContentDocument> docs = FileController.getFilesSharedWithUser(offset, countOfRecords);
			Test.stopTest();

			System.assertEquals(docs.size(), 1, 'Should be able to retrieve files shared with logged in user');
			System.assertEquals(docs[0].Title, title);
		}
	}

	@IsTest
	private static void test_getFilesSharedWithUser_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.getFilesSharedWithUser(offset, countOfRecords);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	//Todo - need to try loadData with Recently Viewed Date populated?
	@IsTest
	private static void test_getFilesRecentlyViewedByUser_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			ContentVersion result = FileService.DB.createFile(o.Id, title, base64Data);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);

			Test.startTest();
			List<ContentDocument> docs = FileController.getFilesRecentlyViewedByUser(countOfRecords);
			Test.stopTest();

			System.assertEquals(docs.size(), 0, 'Should be able to retrieve recently viewed files by logged in user');
		}
	}

	@IsTest
	private static void test_getFilesRecentlyViewedByUser_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.getFilesRecentlyViewedByUser(countOfRecords);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_getFilesFollowedByUser_success() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			ContentVersion result = FileService.DB.createFile(o.Id, title, base64Data);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);

			EntitySubscription es = new EntitySubscription(ParentId = result.ContentDocumentId, SubscriberId = u.Id);
			insert es;

			Test.startTest();
			List<ContentDocument> docs = FileController.getFilesFollowedByUser(offset, countOfRecords);
			Test.stopTest();

			System.assertEquals(docs.size(), 1, 'Should be able to retrieve files followed by logged in user');
			System.assertEquals(docs[0].Title, title);
		}
	}

	@IsTest
	private static void test_getFilesFollowedByUser_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.getFilesFollowedByUser(offset, countOfRecords);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_getContentWorkspaces_success() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			ContentWorkspace cw = TestUtils.createContentWorkspace();
			System.assertNotEquals(null, cw);
			System.assertNotEquals(null, cw.Id);

			Test.startTest();
			List<ContentWorkspace> cws = FileController.getContentWorkspaces(offset, countOfRecords);
			Test.stopTest();

			System.assertEquals(cws.size(), 1, 'Should be able to retrieve content workspace created by user');
		}
	}

	@IsTest
	private static void test_getContentWorkspaces_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.getContentWorkspaces(offset, countOfRecords);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_getContentDocumentsInWorkspaces_success() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			ContentWorkspace cw = TestUtils.createContentWorkspace();
			System.assertNotEquals(null, cw);
			System.assertNotEquals(null, cw.Id);

			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			ContentVersion cv = FileService.DB.createFile(o.Id, title, base64Data);
			System.assertNotEquals(null, cv);
			System.assertNotEquals(null, cv.Id);

			TestUtils.createContentWorkspaceDoc(cw.Id, cv.ContentDocumentId);

			Test.startTest();
			List<ContentDocument> cds = FileController.getContentDocumentsInWorkspace(offset, countOfRecords, cw.Id);
			Test.stopTest();

			System.assertEquals(cds.size(), 1, 'Should be able to retrieve content documents in content workspace');
		}
	}

	@IsTest
	private static void test_getContentDocumentsInWorkspaces_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.getContentDocumentsInWorkspace(offset, countOfRecords, null);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_linkContentDocuments_success() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			List<Id> contentDocIds = new List<Id>();
			Opportunity o = TestUtils.createOpportunity();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			System.assertNotEquals(null, cv1.Id);
			System.assertNotEquals(null, cv2.Id);
			contentDocIds.add(cv1.ContentDocumentId);
			contentDocIds.add(cv2.ContentDocumentId);

			Test.startTest();
			FileController.linkContentDocuments(contentDocIds, o.Id);
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_linkContentDocumentsDuplicate_failure() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			List<Id> contentDocIds = new List<Id>();
			Opportunity o = TestUtils.createOpportunity();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			System.assertNotEquals(null, cv1.Id);
			System.assertNotEquals(null, cv2.Id);
			contentDocIds.add(cv1.ContentDocumentId);
			contentDocIds.add(cv2.ContentDocumentId);

			Test.startTest();
			try {
				FileController.linkContentDocuments(contentDocIds, o.Id);
				FileController.linkContentDocuments(contentDocIds, o.Id);
				System.assert(true, 'Should have thrown an exception for duplicate linked files');
			} catch (Exception ex) {
				System.assert(ex.getMessage().contains('is already linked with the entity'),
					'Exception should indicate duplicate files are being linked');
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_linkContentDocuments_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileController.linkContentDocuments(null, null);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
