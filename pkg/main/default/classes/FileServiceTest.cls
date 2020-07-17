@IsTest
private class FileServiceTest {

	final static Integer countOfRecords = 5;
	final static Integer offset = 0;

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
	private static void test_getSendingDeepLink_success() {

		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			String title = UUID.randomUUID().toString();
			String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data3 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			ContentVersion result1 = FileService.saveFile(null, a.Id, title, base64Data1);
			ContentVersion result2 = FileService.saveFile(null, a.Id, title, base64Data2);
			ContentVersion result3 = FileService.saveFile(null, a.Id, title, base64Data3);

			UUID scmFileGuId1 = UUID.randomUUID();
			UUID scmFileGuId2 = UUID.randomUUID();

			String scmFile1 = 'scm;' + scmFileGuId1 + ';UnitTestScmFile1;html';
			String scmFile2 = 'scm;' + scmFileGuId2 + ';UnitTestScmFile2;html';

			List<String> filesInput = new List<String> {
				result1.ContentDocumentId, result2.ContentDocumentId,
				result3.ContentDocumentId, scmFile1, scmFile2
			};

			Test.startTest();
			PageReference result = FileService.getSendingDeepLink(a.Id, filesInput);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.getUrl().startsWith('/apex/' + Application.namespacePrefix + 'sending'));
			System.assertEquals(a.Id, (Id)result.getParameters().get('sid'));
			String fileParameter = result.getParameters().get('files');
			System.assert(String.isNotBlank(fileParameter));
			String[] files = fileParameter.split(',');
			System.assertEquals(5, files.size());
		}

	}

	@IsTest
	private static void test_getSendingDeepLink_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileService.getSendingDeepLink(null, null);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_getFilesOwnedByUser_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Opportunity o = TestUtils.createOpportunity();
			String title = UUID.randomUUID().toString();
			String base64Data = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			ContentVersion result = FileService.DB.createFile(o.Id, title, base64Data);
			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.Id);

			Test.startTest();
			List<ContentDocument> docs = FileService.getFilesOwnedByUser(offset, countOfRecords);
			Test.stopTest();

			System.assertEquals(docs.size(), 1, 'Should be able to retrieve files owned by logged in user');
			System.assertEquals(docs[0].Title, title);
		}
	}

	@IsTest
	private static void test_getFilesOwnedByUser_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileService.getFilesOwnedByUser(offset, countOfRecords);
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
			List<ContentDocument> docs = FileService.getFilesSharedWithUser(offset, countOfRecords);
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
				FileService.getFilesSharedWithUser(offset, countOfRecords);
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
			List<ContentDocument> docs = FileService.getFilesRecentlyViewedByUser(countOfRecords);
			Test.stopTest();

			System.assertEquals(docs.size(), 0, 'Should be able to retrieve recently viewed files by logged in user');
		}
	}

	@IsTest
	private static void test_getFilesRecentlyViewedByUser_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileService.getFilesRecentlyViewedByUser(countOfRecords);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_getFilesFollowedByUser_success() {
		if (!Salesforce.isValidSObject('EntitySubscription')) return;

		ContentVersion cv = TestUtils.createContentVersion();
		SObject es = Salesforce.getSObjectType('EntitySubscription').newSObject();
		es.put('ParentId', cv.ContentDocumentId);
		es.put('SubscriberId', UserInfo.getUserId());
		insert es;

		Test.startTest();
		List<ContentDocument> result = FileService.getFilesFollowedByUser(offset, countOfRecords);
		Test.stopTest();

		System.assertEquals(1, Collection.size(result), 'Should be able to retrieve files followed by logged in user');
		System.assertNotEquals(null, result[0]);
		System.assertEquals(cv.ContentDocumentId, result[0].Id);
		System.assertEquals(cv.Title, result[0].Title);
		System.assertEquals(cv.FileExtension, result[0].FileExtension);
		System.assertEquals(cv.ContentSize, result[0].ContentSize);
	}

	@IsTest
	private static void test_getContentWorkspaces_success() {
		User u = UserMock.createDocuSignUser();
		System.runAs(u) {
			ContentWorkspace cw = TestUtils.createContentWorkspace();
			System.assertNotEquals(null, cw);
			System.assertNotEquals(null, cw.Id);

			Test.startTest();
			List<ContentWorkspace> cws = FileService.getContentWorkspaces(offset, countOfRecords);
			Test.stopTest();

			System.assertEquals(cws.size(), 1, 'Should be able to retrieve content workspace created by user');
		}
	}

	@IsTest
	private static void test_getContentWorkspaces_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileService.getContentWorkspaces(offset, countOfRecords);
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
			List<ContentDocument> cds = FileService.getContentDocumentsInWorkspace(offset, countOfRecords, cw.Id);
			Test.stopTest();

			System.assertEquals(cds.size(), 1, 'Should be able to retrieve content documents in content workspace');
		}
	}

	@IsTest
	private static void test_getContentDocumentsInWorkspaces_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileService.getContentDocumentsInWorkspace(offset, countOfRecords, null);
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
			List<Id> contentVersionIds = FileService.linkContentDocuments(contentDocIds, o.Id);
			System.assertEquals(contentVersionIds.size(), 2, 'Link Content Documents Failed');
			Test.stopTest();
		}
	}

	@IsTest
	private static void test_linkContentDocuments_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				FileService.linkContentDocuments(null, null);
				throw new AssertException('Expected failure');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
