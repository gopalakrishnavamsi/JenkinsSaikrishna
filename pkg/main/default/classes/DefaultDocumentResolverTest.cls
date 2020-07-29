@IsTest
private class DefaultDocumentResolverTest {

	@IsTest
	static void test_canResolveDocuments() {
		DefaultDocumentResolver dr = new DefaultDocumentResolver();

		Test.startTest();
		System.assert(dr.canResolveDocuments(Schema.ContentDocument.getSObjectType()));
		System.assert(dr.canResolveDocuments(Schema.ContentVersion.getSObjectType()));
		System.assert(dr.canResolveDocuments(Schema.Document.getSObjectType()));
		System.assert(!dr.canResolveDocuments(Schema.Lead.getSObjectType()));
		System.assert(!dr.canResolveDocuments(null));
		Test.stopTest();
	}

	@IsTest
	static void test_getDocuments_ContentDocument() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			List<Document> result = dr.getDocuments(
				ContentDocument.getSObjectType(),
				new Set<Id> { cv1.ContentDocumentId, cv2.ContentDocumentId });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(Document.TYPE_FILE, result[0].type);
			System.assertEquals(null, result[0].sequence);
			System.assertEquals(cv1.Title, result[0].name);
			System.assertEquals(cv1.FileExtension, result[0].extension);
			System.assertEquals(cv1.ContentSize, result[0].size);
			System.assertNotEquals(null, result[0].lastModified);
			System.assertEquals(cv1.ContentDocumentId, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(Document.TYPE_FILE, result[1].type);
			System.assertEquals(null, result[1].sequence);
			System.assertEquals(cv2.Title, result[1].name);
			System.assertEquals(cv2.FileExtension, result[1].extension);
			System.assertEquals(cv2.ContentSize, result[1].size);
			System.assertNotEquals(null, result[1].lastModified);
			System.assertEquals(cv2.ContentDocumentId, result[1].sourceId);
		}
	}

	@IsTest
	static void test_getDocuments_ContentVersion() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			List<Document> result = dr.getDocuments(ContentVersion.getSObjectType(), new Set<Id> { cv1.Id, cv2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(Document.TYPE_FILE, result[0].type);
			System.assertEquals(null, result[0].sequence);
			System.assertEquals(cv1.Title, result[0].name);
			System.assertEquals(cv1.FileExtension, result[0].extension);
			System.assertEquals(cv1.ContentSize, result[0].size);
			System.assertNotEquals(null, result[0].lastModified);
			System.assertEquals(cv1.Id, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(Document.TYPE_FILE, result[1].type);
			System.assertEquals(null, result[1].sequence);
			System.assertEquals(cv2.Title, result[1].name);
			System.assertEquals(cv2.FileExtension, result[1].extension);
			System.assertEquals(cv2.ContentSize, result[1].size);
			System.assertNotEquals(null, result[1].lastModified);
			System.assertEquals(cv2.Id, result[1].sourceId);
		}
	}

	@IsTest
	static void test_getDocuments_Document() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Document d1 = TestUtils.createDocument();
			Schema.Document d2 = TestUtils.createDocument();

			Test.startTest();
			List<Document> result = dr.getDocuments(Schema.Document.getSObjectType(), new Set<Id> { d1.Id, d2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(Document.TYPE_DOCUMENT, result[0].type);
			System.assertEquals(null, result[0].sequence);
			System.assertEquals(d1.Name, result[0].name);
			System.assertEquals(d1.Type, result[0].extension);
			System.assertEquals(d1.BodyLength, result[0].size);
			System.assertNotEquals(null, result[0].lastModified);
			System.assertEquals(d1.Id, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(Document.TYPE_DOCUMENT, result[1].type);
			System.assertEquals(null, result[1].sequence);
			System.assertEquals(d2.Name, result[1].name);
			System.assertEquals(d2.Type, result[1].extension);
			System.assertEquals(d2.BodyLength, result[1].size);
			System.assertNotEquals(null, result[1].lastModified);
			System.assertEquals(d2.Id, result[1].sourceId);
		}
	}

	@IsTest
	static void test_getDocuments_invalid() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			try {
				dr.getDocuments(Schema.User.getSObjectType(), new Set<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected getDocuments to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveDocumentType_1, new List<String> { 'User' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLinkedDocuments_ContentVersion_all() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Account a1 = TestUtils.createAccount();
			Opportunity o1 = TestUtils.createOpportunity(a1.Id);
			Contact c1 = TestUtils.createContact(a1.Id);
			ContentVersion cv1 = TestUtils.createContentVersion(a1.Id);
			ContentVersion cv2 = TestUtils.createContentVersion(a1.Id);
			ContentVersion cv3 = TestUtils.createContentVersion(o1.Id);

			Test.startTest();
			List<Document> result = dr.getLinkedDocuments(
				ContentVersion.getSObjectType(),
				new Set<Id> { a1.Id, o1.Id, c1.Id },
				null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			Boolean foundCV1 = false, foundCV2 = false, foundCV3 = false;
			for (Document d : result) {
				System.assertNotEquals(null, d);
				System.assertNotEquals(null, d.lastModified);
				if (d.sourceId == cv1.Id) {
					foundCV1 = true;
					System.assertEquals(Document.TYPE_FILE, d.type);
					System.assertNotEquals(null, d.sequence);
					System.assertEquals(cv1.Title, d.name);
					System.assertEquals(cv1.FileExtension, d.extension);
					System.assertEquals(cv1.ContentSize, d.size);
					System.assertEquals(cv1.Id, d.sourceId);
				} else if (d.sourceId == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(Document.TYPE_FILE, d.type);
					System.assertNotEquals(null, d.sequence);
					System.assertEquals(cv2.Title, d.name);
					System.assertEquals(cv2.FileExtension, d.extension);
					System.assertEquals(cv2.ContentSize, d.size);
					System.assertEquals(cv2.Id, d.sourceId);
				} else if (d.sourceId == cv3.Id) {
					foundCV3 = true;
					System.assertEquals(Document.TYPE_FILE, d.type);
					System.assertNotEquals(null, d.sequence);
					System.assertEquals(cv3.Title, d.name);
					System.assertEquals(cv3.FileExtension, d.extension);
					System.assertEquals(cv3.ContentSize, d.size);
					System.assertEquals(cv3.Id, d.sourceId);
				} else {
					throw new AssertException('Unexpected document: ' + d);
				}
			}
			System.assert(foundCV1);
			System.assert(foundCV2);
			System.assert(foundCV3);
		}
	}

	@IsTest
	static void test_getLinkedDocuments_ContentVersion_with_filter() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Account a1 = TestUtils.createAccount();
			ContentVersion cv1 = TestUtils.createContentVersion(a1.Id);
			cv1.Title = 'a';
			cv1.Description = 'desc1';
			ContentVersion cv2 = TestUtils.createContentVersion(a1.Id);
			cv2.Title = 'b';
			cv2.Description = 'desc2';
			ContentVersion cv3 = TestUtils.createContentVersion(a1.Id);
			cv3.Title = 'c';
			cv3.Description = 'other';
			update new List<ContentVersion> { cv1, cv2, cv3 };

			Test.startTest();
			List<Document> result = dr.getLinkedDocuments(
				ContentVersion.getSObjectType(),
				new Set<Id> { a1.Id },
				new Query.Filter(
					'ContentDocument.LatestPublishedVersion.Description LIKE \'desc%\'',
					'ContentDocument.LatestPublishedVersion.Title DESC',
					1));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(cv2.Id, result[0].sourceId);
		}
	}

	@IsTest
	static void test_getLinkedDocuments_Document() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Account a = TestUtils.createAccount();

			Test.startTest();
			List<Document> result = dr.getLinkedDocuments(
				Schema.Document.getSObjectType(),
				new Set<Id> { a.Id },
				null);
			Test.stopTest();

			System.assert(Collection.isEmpty(result));
		}
	}

	@IsTest
	static void test_getLinkedDocuments_invalid() {
		Test.startTest();
		try {
			new DefaultDocumentResolver().getLinkedDocuments(User.getSObjectType(), null, null);
			throw new AssertException('Expected getLinkedDocuments to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(String.format(Label.CannotResolveDocumentType_1,
				new List<String> { 'User' }), ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getDocumentContent_ContentDocument() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			Map<Id, Blob> result = dr.getDocumentContent(
				ContentDocument.getSObjectType(),
				new Set<Id> { cv1.ContentDocumentId, cv2.ContentDocumentId });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(cv1.VersionData.toString(), result.get(cv1.ContentDocumentId).toString());
			System.assertEquals(cv2.VersionData.toString(), result.get(cv2.ContentDocumentId).toString());
		}
	}

	@IsTest
	static void test_getDocumentContent_ContentVersion() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			Map<Id, Blob> result = dr.getDocumentContent(ContentVersion.getSObjectType(), new Set<Id> { cv1.Id, cv2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(cv1.VersionData.toString(), result.get(cv1.Id).toString());
			System.assertEquals(cv2.VersionData.toString(), result.get(cv2.Id).toString());
		}
	}

	@IsTest
	static void test_getDocumentContent_Document() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Document d1 = TestUtils.createDocument();
			Schema.Document d2 = TestUtils.createDocument();

			Test.startTest();
			Map<Id, Blob> result = dr.getDocumentContent(Schema.Document.getSObjectType(), new Set<Id> { d1.Id, d2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertEquals(d1.Body.toString(), result.get(d1.Id).toString());
			System.assertEquals(d2.Body.toString(), result.get(d2.Id).toString());
		}
	}

	@IsTest
	static void test_getDocumentContent_invalid() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			try {
				dr.getDocumentContent(User.getSObjectType(), new Set<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected getDocumentContent to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveDocumentType_1, new List<String> { 'User' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getDocumentFolders_ContentVersion() {
		System.runAs(UserMock.createUser()) {
			ContentWorkspace cw1 = TestUtils.createContentWorkspace();
			ContentWorkspace cw2 = TestUtils.createContentWorkspace();
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			List<Document.Folder> result = dr.getDocumentFolders(Schema.ContentVersion.getSObjectType());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.size() >= 2); // There can be extra workspaces available, but there must be at least 2.

			Boolean foundCW1, foundCW2;
			for (Document.Folder f : result) {
				if (f.id == cw1.Id) {
					foundCW1 = true;
					System.assertEquals(cw1.Name, f.name);
				} else if (f.id == cw2.Id) {
					foundCW2 = true;
					System.assertEquals(cw2.Name, f.name);
				}
			}
			System.assert(foundCW1);
			System.assert(foundCW2);
		}
	}

	@IsTest
	static void test_getDocumentFolders_Document() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			List<Document.Folder> result = dr.getDocumentFolders(Schema.Document.getSObjectType());
			Test.stopTest();

			System.assertNotEquals(null, result);
			// No way to control folders returned. DML not allowed on Folder metadata objects, so we are at the mercy
			// of whatever folders already exist in the org.
		}
	}

	@IsTest
	static void test_getDocumentFolders_invalid() {
		System.runAs(UserMock.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			try {
				dr.getDocumentFolders(Schema.User.getSObjectType());
				throw new AssertException('Expected getDocumentFolders to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveDocumentType_1, new List<String> { 'User' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getFolderDocuments_ContentVersion() {
		// Cannot create and link doc to workspace in one go, so try using existing one. Otherwise skip test.
		ContentWorkspace lib = TestUtils.getFirstAvailableContentWorkspace();
		ContentVersion cv1, cv2;
		ContentWorkspaceDoc libDoc1, libDoc2;

		if (lib != null) {
			System.runAs(UserMock.createAdministrator()) {
				cv1 = TestUtils.createContentVersion();
				cv2 = TestUtils.createContentVersion();
				libDoc1 = TestUtils.createContentWorkspaceDoc(lib.Id, cv1.ContentDocumentId);
				libDoc2 = TestUtils.createContentWorkspaceDoc(lib.Id, cv2.ContentDocumentId);
			}
		}

		System.runAs(UserMock.createAdministrator()) {
			ContentVersion cv3 = TestUtils.createContentVersion();
			ContentVersion cv4 = TestUtils.createContentVersion();
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Set<Id> folderIds = new Set<Id> { UserInfo.getUserId() };
			if (lib != null) folderIds.add(lib.Id);

			Test.startTest();
			List<Document> result = dr.getFolderDocuments(Schema.ContentVersion.getSObjectType(), folderIds);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(lib == null ? 2 : 4, result.size());

			Boolean foundCV1, foundCV2, foundCV3, foundCV4;
			for (Document d : result) {
				ContentVersion cv;
				if (d.sourceId == cv1.Id) {
					foundCV1 = true;
					cv = cv1;
				} else if (d.sourceId == cv2.Id) {
					foundCV2 = true;
					cv = cv2;
				} else if (d.sourceId == cv3.Id) {
					foundCV3 = true;
					cv = cv3;
				} else if (d.sourceId == cv4.Id) {
					foundCV4 = true;
					cv = cv4;
				} else {
					throw new AssertException('Unexpected document: ' + d);
				}
				System.assertEquals(cv.Title, d.name);
				System.assertEquals(cv.FileExtension, d.extension);
				System.assertEquals(cv.ContentSize, d.size);
			}
			System.assert(lib == null || foundCV1);
			System.assert(lib == null || foundCV2);
			System.assert(foundCV3);
			System.assert(foundCV4);
		}
	}

	@IsTest
	static void test_getFolderDocuments_Document() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			TestUtils.createDocument();
			TestUtils.createDocument();
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			List<Document> result = dr.getFolderDocuments(
				Schema.Document.getSObjectType(),
				new Set<Id> { UserInfo.getUserId() });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_getFolderDocuments_invalid() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			try {
				dr.getFolderDocuments(Schema.User.getSObjectType(), new Set<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected getFolderDocuments to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveDocumentType_1, new List<String> { 'User' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getContentVersionDocuments_success() {
		Set<Id> contentVersionIds = new Set<Id>();
		ContentVersion cv1 = TestUtils.createContentVersion();
		ContentVersion cv2 = TestUtils.createContentVersion();
		System.assertNotEquals(null, cv1.Id);
		System.assertNotEquals(null, cv2.Id);
		contentVersionIds.add(cv1.Id);
		contentVersionIds.add(cv2.Id);

		Test.startTest();
		List<ContentVersion> contentVersions = new DefaultDocumentResolver().getContentVersionDocuments(contentVersionIds);
		Test.stopTest();

		System.assertEquals(contentVersions.size(), 2, 'Content versions were not inserted');
		System.assertNotEquals(contentVersions[0].ContentDocumentId, null, 'Content versions were not inserted');
	}

}