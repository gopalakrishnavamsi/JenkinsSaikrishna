@IsTest
private class DocumentServiceTest {

	@IsTest
	static void test_bad_resolver() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.DocumentResolvers__c = 'bad_resolver';
			upsert s;

			Test.startTest();
			try {
				DocumentService.getDocuments(null, null);
				throw new AssertException('Expected initialization to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.InvalidDocumentResolver_1, new List<String> { 'bad_resolver' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getFileExtension() {
		Test.startTest();
		System.assertEquals(null, DocumentService.getFileExtension(null));
		System.assertEquals(null, DocumentService.getFileExtension(''));
		System.assertEquals(null, DocumentService.getFileExtension('\t'));
		System.assertEquals(null, DocumentService.getFileExtension('file'));
		System.assertEquals('', DocumentService.getFileExtension('file.'));
		System.assertEquals('ext', DocumentService.getFileExtension('.ext'));
		System.assertEquals('ext', DocumentService.getFileExtension('file.ext'));
		System.assertEquals('ext2', DocumentService.getFileExtension('file.ext1.ext2'));
		Test.stopTest();
	}

	@IsTest
	static void test_conversion() {
		Envelope__c dse = TestUtils.createEnvelope();
		Document__c dsed1 = new Document__c(
			Envelope__c = dse.Id,
			Type__c = Document.TYPE_FILE,
			Sequence__c = 1,
			Name = 'test.pdf',
			Extension__c = '',
			Size__c = null,
			LastModified__c = Datetime.now(),
			SourceId__c = '1234');
		Document__c dsed2 = new Document__c(
			Envelope__c = dse.Id,
			Type__c = Document.TYPE_DOCUMENT,
			Sequence__c = 2,
			Name = 'test.pdf',
			Extension__c = 'docx',
			Size__c = 1234,
			LastModified__c = Datetime.now(),
			SourceId__c = UUID.randomUUID().toString());
		List<Document__c> dseds = new List<Document__c> { dsed1, dsed2 };
		insert dseds;
		ContentVersion cv = TestUtils.createContentVersion();
		Schema.Document d = TestUtils.createDocument();
		Template t = new Template(UUID.randomUUID(), 'UNIT TEST', null, null, null, null, null, Datetime.now());

		Test.startTest();
		Document result1 = DocumentService.DB.convert(dsed1);
		List<Document> result2 = DocumentService.convert(dseds);
		Document result3 = DocumentService.convert(cv);
		Document result4 = DocumentService.convert(d);
		Document result5 = DocumentService.convert(t);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(dsed1.Id, result1.id);
		System.assertEquals(dsed1.Type__c, result1.type);
		System.assertEquals(dsed1.Sequence__c, Decimal.valueOf(result1.sequence));
		System.assertEquals(dsed1.Name, result1.name);
		System.assertEquals('pdf', result1.extension);
		System.assertEquals(dsed1.Size__c, Decimal.valueOf(result1.size));
		System.assertEquals(dsed1.LastModified__c, result1.lastModified);
		System.assertEquals(dsed1.SourceId__c, result1.sourceId);

		System.assertNotEquals(null, result2);
		System.assertEquals(2, result2.size());
		System.assertEquals(dsed1.Id, result2[0].id);
		System.assertEquals(dsed1.Type__c, result2[0].type);
		System.assertEquals(dsed1.Sequence__c, Decimal.valueOf(result2[0].sequence));
		System.assertEquals(dsed1.Name, result2[0].name);
		System.assertEquals('pdf', result2[0].extension);
		System.assertEquals(dsed1.Size__c, Decimal.valueOf(result2[0].size));
		System.assertEquals(dsed1.LastModified__c, result2[0].lastModified);
		System.assertEquals(dsed1.SourceId__c, result2[0].sourceId);

		System.assertEquals(dsed2.Id, result2[1].id);
		System.assertEquals(dsed2.Type__c, result2[1].type);
		System.assertEquals(dsed2.Sequence__c, Decimal.valueOf(result2[1].sequence));
		System.assertEquals(dsed2.Name, result2[1].name);
		System.assertEquals(dsed2.Extension__c, result2[1].extension);
		System.assertEquals(dsed2.Size__c, Decimal.valueOf(result2[1].size));
		System.assertEquals(dsed2.LastModified__c, result2[1].lastModified);
		System.assertEquals(dsed2.SourceId__c, result2[1].sourceId);

		System.assertEquals(null, result3.id);
		System.assertEquals(Document.TYPE_FILE, result3.type);
		System.assertEquals(null, result3.sequence);
		System.assertEquals(cv.Title, result3.name);
		System.assertEquals(cv.FileExtension, result3.extension);
		System.assertEquals(cv.ContentSize, result3.size);
		System.assertEquals(cv.LastModifiedDate, result3.lastModified);
		System.assertEquals(cv.Id, result3.sourceId);

		System.assertEquals(null, result4.id);
		System.assertEquals(Document.TYPE_DOCUMENT, result4.type);
		System.assertEquals(null, result4.sequence);
		System.assertEquals(d.Name, result4.name);
		System.assertEquals(DocumentService.getFileExtension(d.Name), result4.extension);
		System.assertEquals(d.BodyLength, result4.size);
		System.assertEquals(d.LastModifiedDate, result4.lastModified);
		System.assertEquals(d.Id, result4.sourceId);

		System.assertEquals(null, result5.id);
		System.assertEquals(Document.TYPE_TEMPLATE, result5.type);
		System.assertEquals(null, result5.sequence);
		System.assertEquals(t.name, result5.name);
		System.assertEquals(null, result5.extension);
		System.assertEquals(null, result5.size);
		System.assertEquals(t.lastModified, result5.lastModified);
		System.assertEquals(String.valueOf(t.id), result5.sourceId);
	}

	@IsTest
	static void test_validate() {
		Document d1 = new Document(null, Document.TYPE_DOCUMENT, 1, 'doc1', 'docx', 1234, Datetime.now(), '1234');
		Document d2 = new Document(null, Document.TYPE_FILE, 2, 'doc2', 'quote', 5678, Datetime.now(), '5678');
		Document d3 = new Document(null, Document.TYPE_DOCUMENT, 3, 'doc3', '', 9012, Datetime.now(), '9012');

		Test.startTest();
		ValidationResult result1 = DocumentService.validate((Document)null);
		ValidationResult result2 = DocumentService.validate(new List<Document>());
		ValidationResult result3 = DocumentService.validate(d1);
		ValidationResult result4 = DocumentService.validate(d2);
		ValidationResult result5 = DocumentService.validate(new List<Document> { d1, d2, d3 });
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(Label.UndefinedDocument, result1.toString());

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(Label.AtLeastOneDocumentIsRequired, result2.toString());

		System.assertNotEquals(null, result3);
		System.assert(result3.isValid);

		System.assertNotEquals(null, result4);
		System.assert(!result4.isValid);
		System.assertEquals(Label.InvalidFileType, result4.toString());

		System.assertNotEquals(null, result5);
		System.assert(!result5.isValid);
		System.assertEquals(Label.InvalidFileType + '\n' + Label.InvalidFileType, result5.toString());
	}

	@IsTest
	static void test_Database_convert() {
		Envelope__c dse = TestUtils.createEnvelope();
		Document__c dsed = TestUtils.createEnvelopeDocument(dse.Id);
		Document d = new Document(dsed.Id, dsed.Type__c,
			Integer.valueOf(dsed.Sequence__c), dsed.Name, dsed.Extension__c,
			Integer.valueOf(dsed.Size__c), dsed.LastModified__c, dsed.SourceId__c);

		Test.startTest();
		Document__c result = DocumentService.DB.convert(d, dse.Id, 3);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(d.id, result.Id);
		System.assertEquals(dse.Id, result.Envelope__c);
		System.assertEquals(d.type, result.Type__c);
		System.assertEquals(3, Integer.valueOf(result.Sequence__c));
		System.assertEquals(d.name, result.Name);
		System.assertEquals(d.extension, result.Extension__c);
		System.assertEquals(d.size, Integer.valueOf(result.Size__c));
		System.assertEquals(d.lastModified, result.LastModified__c);
		System.assertEquals(d.sourceId, result.SourceId__c);
	}

	@IsTest
	static void test_Database_queryMaxSequence() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Document__c d1 = TestUtils.createEnvelopeDocument(e1.Id, 1);
			Document__c d2 = TestUtils.createEnvelopeDocument(e1.Id, 2);

			Test.startTest();
			Integer result1 = DocumentService.DB.queryMaxSequence(e1.Id);
			Integer result2 = DocumentService.DB.queryMaxSequence(e2.Id);
			Test.stopTest();

			System.assertEquals(2, result1);
			System.assertEquals(0, result2);
		}
	}

	@IsTest
	static void test_Database_queryDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c dse = TestUtils.createEnvelope(a.Id);
			Document__c dsed1 = TestUtils.createEnvelopeDocument(dse.Id, TestUtils.createDocument(), 1);
			Document__c dsed2 = TestUtils.createEnvelopeDocument(dse.Id, TestUtils.createContentVersion(), 2);

			Test.startTest();
			List<Document> result = DocumentService.DB.queryDocuments(dse.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(dsed1.Id, result[0].id);
			System.assertEquals(dsed1.Type__c, result[0].type);
			System.assertEquals(dsed1.Sequence__c, Decimal.valueOf(result[0].sequence));
			System.assertEquals(dsed1.Name, result[0].name);
			System.assertEquals(dsed1.Extension__c, result[0].extension);
			System.assertEquals(dsed1.Size__c, Decimal.valueOf(result[0].size));
			System.assertEquals(dsed1.LastModified__c, result[0].lastModified);
			System.assertEquals(dsed1.SourceId__c, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(dsed2.Id, result[1].id);
			System.assertEquals(dsed2.Type__c, result[1].type);
			System.assertEquals(dsed2.Sequence__c, Decimal.valueOf(result[1].sequence));
			System.assertEquals(dsed2.Name, result[1].name);
			System.assertEquals(dsed2.Extension__c, result[1].extension);
			System.assertEquals(dsed2.Size__c, Decimal.valueOf(result[1].size));
			System.assertEquals(dsed2.LastModified__c, result[1].lastModified);
			System.assertEquals(dsed2.SourceId__c, result[1].sourceId);
		}
	}

	@IsTest
	static void test_Database_insertDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.Id));
			Schema.Document d = TestUtils.createDocument();
			Document d2 = new Document(null, Document.TYPE_DOCUMENT, null, d.Name, d.Type, d.BodyLength, d.LastModifiedDate, d.Id);
			UUID tId = UUID.randomUUID();
			Document d3 = Document.fromTemplate(tId, 'template1');

			Test.startTest();
			List<Document> result = DocumentService.DB.insertDocuments(e.Id, new List<Document> { d2, d3 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].id);
			System.assertEquals(Document.TYPE_DOCUMENT, result[0].type);
			System.assertEquals(2, result[0].sequence);
			System.assertEquals(d.Name, result[0].name);
			System.assertEquals(d.Type, result[0].extension);
			System.assertEquals(d.BodyLength, result[0].size);
			System.assertEquals(d.LastModifiedDate, result[0].lastModified);
			System.assertEquals(d.Id, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);
			System.assertEquals(Document.TYPE_TEMPLATE, result[1].type);
			System.assertEquals(3, result[1].sequence);
			System.assertEquals('template1', result[1].name);
			System.assertEquals(null, result[1].extension);
			System.assertEquals(null, result[1].size);
			System.assertEquals(null, result[1].lastModified);
			System.assertEquals(String.valueOf(tId), result[1].sourceId);
		}
	}

	@IsTest
	static void test_Database_upsertDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id));
			Document d2 = new Document(
				null,
				Document.TYPE_TEMPLATE,
				null,
				UUID.randomUUID().toString(),
				null,
				null,
				Datetime.now(),
				UUID.randomUUID().toString());
			Document d3 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id));

			Test.startTest();
			List<Document> result = DocumentService.DB.upsertDocuments(dse.Id, new List<Document> { d1, d2, d3 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(d1.id, result[0].id);
			System.assertEquals(d1.type, result[0].type);
			System.assertEquals(1, result[0].sequence);
			System.assertEquals(d1.name, result[0].name);
			System.assertEquals(d1.extension, result[0].extension);
			System.assertEquals(d1.size, result[0].size);
			System.assertEquals(d1.lastModified, result[0].lastModified);
			System.assertEquals(d1.sourceId, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id); // Id assigned on insert
			System.assertEquals(d2.type, result[1].type);
			System.assertEquals(2, result[1].sequence);
			System.assertEquals(d2.name, result[1].name);
			System.assertEquals(d2.extension, result[1].extension);
			System.assertEquals(d2.size, result[1].size);
			System.assertEquals(d2.lastModified, result[1].lastModified);
			System.assertEquals(d2.sourceId, result[1].sourceId);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(d3.id, result[2].id);
			System.assertEquals(d3.type, result[2].type);
			System.assertEquals(3, result[2].sequence);
			System.assertEquals(d3.name, result[2].name);
			System.assertEquals(d3.extension, result[2].extension);
			System.assertEquals(d3.size, result[2].size);
			System.assertEquals(d3.lastModified, result[2].lastModified);
			System.assertEquals(d3.sourceId, result[2].sourceId);
		}
	}

	@IsTest
	static void test_Database_deleteDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 1));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 2));
			Document d3 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 3));

			Test.startTest();
			List<Document> result = null;
			if (DocumentService.DB.deleteDocuments(new Set<Id> { d2.id })) {
				result = DocumentService.DB.queryDocuments(dse.id);
			}
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(d1.id, result[0].id);
			System.assertEquals(d1.type, result[0].type);
			System.assertEquals(d1.sequence, result[0].sequence);
			System.assertEquals(d1.name, result[0].name);
			System.assertEquals(d1.extension, result[0].extension);
			System.assertEquals(d1.size, result[0].size);
			System.assertEquals(d1.lastModified, result[0].lastModified);
			System.assertEquals(d1.sourceId, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(d3.id, result[1].id);
			System.assertEquals(d3.type, result[1].type);
			System.assertEquals(d3.sequence, result[1].sequence);
			System.assertEquals(d3.name, result[1].name);
			System.assertEquals(d3.extension, result[1].extension);
			System.assertEquals(d3.size, result[1].size);
			System.assertEquals(d3.lastModified, result[1].lastModified);
			System.assertEquals(d3.sourceId, result[1].sourceId);
		}
	}

	@IsTest
	static void test_Database_updateDocumentSequence() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 3));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 5));
			Document d3 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 7));

			Test.startTest();
			List<Document> result1 = DocumentService.DB.updateDocumentSequence(dse.Id);
			List<Document> result2 = DocumentService.DB.updateDocumentSequence(dse.Id, new Map<Id, Integer> {
				d3.id => 1,
				d2.id => 2,
				d1.id => 3
			});
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(3, result1.size());

			System.assertNotEquals(null, result1[0]);
			System.assertEquals(d1.id, result1[0].id);
			System.assertEquals(d1.type, result1[0].type);
			System.assertEquals(1, result1[0].sequence);
			System.assertEquals(d1.name, result1[0].name);
			System.assertEquals(d1.extension, result1[0].extension);
			System.assertEquals(d1.size, result1[0].size);
			System.assertEquals(d1.lastModified, result1[0].lastModified);
			System.assertEquals(d1.sourceId, result1[0].sourceId);

			System.assertNotEquals(null, result1[1]);
			System.assertEquals(d2.id, result1[1].id);
			System.assertEquals(d2.type, result1[1].type);
			System.assertEquals(2, result1[1].sequence);
			System.assertEquals(d2.name, result1[1].name);
			System.assertEquals(d2.extension, result1[1].extension);
			System.assertEquals(d2.size, result1[1].size);
			System.assertEquals(d2.lastModified, result1[1].lastModified);
			System.assertEquals(d2.sourceId, result1[1].sourceId);

			System.assertNotEquals(null, result1[2]);
			System.assertEquals(d3.id, result1[2].id);
			System.assertEquals(d3.type, result1[2].type);
			System.assertEquals(3, result1[2].sequence);
			System.assertEquals(d3.name, result1[2].name);
			System.assertEquals(d3.extension, result1[2].extension);
			System.assertEquals(d3.size, result1[2].size);
			System.assertEquals(d3.lastModified, result1[2].lastModified);
			System.assertEquals(d3.sourceId, result1[2].sourceId);

			System.assertNotEquals(null, result2);
			System.assertEquals(3, result2.size());

			System.assertNotEquals(null, result2[0]);
			System.assertEquals(d3.id, result2[0].id);
			System.assertEquals(d3.type, result2[0].type);
			System.assertEquals(1, result2[0].sequence);
			System.assertEquals(d3.name, result2[0].name);
			System.assertEquals(d3.extension, result2[0].extension);
			System.assertEquals(d3.size, result2[0].size);
			System.assertEquals(d3.lastModified, result2[0].lastModified);
			System.assertEquals(d3.sourceId, result2[0].sourceId);

			System.assertNotEquals(null, result2[1]);
			System.assertEquals(d2.id, result2[1].id);
			System.assertEquals(d2.type, result2[1].type);
			System.assertEquals(2, result2[1].sequence);
			System.assertEquals(d2.name, result2[1].name);
			System.assertEquals(d2.extension, result2[1].extension);
			System.assertEquals(d2.size, result2[1].size);
			System.assertEquals(d2.lastModified, result2[1].lastModified);
			System.assertEquals(d2.sourceId, result2[1].sourceId);

			System.assertNotEquals(null, result2[2]);
			System.assertEquals(d1.id, result2[2].id);
			System.assertEquals(d1.type, result2[2].type);
			System.assertEquals(3, result2[2].sequence);
			System.assertEquals(d1.name, result2[2].name);
			System.assertEquals(d1.extension, result2[2].extension);
			System.assertEquals(d1.size, result2[2].size);
			System.assertEquals(d1.lastModified, result2[2].lastModified);
			System.assertEquals(d1.sourceId, result2[2].sourceId);
		}
	}

	@IsTest
	static void test_getDocuments_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			List<Document> result = DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id> { cv1.Id, cv2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(null, result[0].id);
			System.assertEquals(Document.TYPE_FILE, result[0].type);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(null, result[1].id);
			System.assertEquals(Document.TYPE_FILE, result[1].type);
		}
	}

	@IsTest
	static void test_getLinkedDocuments_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Opportunity o1 = TestUtils.createOpportunity();
			ContentVersion cv1 = TestUtils.createContentVersion(o1.Id);
			ContentVersion cv2 = TestUtils.createContentVersion(o1.Id);
			ContentVersion cv3 = TestUtils.createContentVersion(a1.Id);

			Test.startTest();
			List<Document> result = DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { o1.Id, a1.Id },
				false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(null, result[0].id);
			System.assertEquals(Document.TYPE_FILE, result[0].type);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(null, result[1].id);
			System.assertEquals(Document.TYPE_FILE, result[1].type);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(null, result[2].id);
			System.assertEquals(Document.TYPE_FILE, result[2].type);
		}
	}

	@IsTest
	static void test_getDocumentFolders_ContentVersion() {
		System.runAs(UserMock.createDocuSignUser()) {
			ContentWorkspace cw1 = TestUtils.createContentWorkspace();
			ContentWorkspace cw2 = TestUtils.createContentWorkspace();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			Document.Folders result = DocumentService.getDocumentFolders(ContentVersion.getSObjectType());
			Test.stopTest();

			System.assertNotEquals(null, result);

			System.assertNotEquals(null, result.folders);
			System.assert(result.folders.size() >= 3);
			Boolean foundPersonal = false, foundCW1 = false, foundCW2 = false;
			for (Document.Folder f : result.folders) {
				if (f.Id == UserInfo.getUserId()) {
					foundPersonal = true;
				} else if (f.Id == cw1.id) {
					foundCW1 = true;
				} else if (f.Id == cw2.id) {
					foundCW2 = true;
				}
			}
			System.assert(foundPersonal);
			System.assert(foundCW1);
			System.assert(foundCW2);

			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			Boolean foundCV1 = false, foundCV2 = false;
			for (Document d : result.documents) {
				if (d.sourceId == cv1.Id) {
					foundCV1 = true;
				} else if (d.sourceId == cv2.Id) {
					foundCV2 = true;
				}
			}
			System.assert(foundCV1);
			System.assert(foundCV2);
		}
	}

	@IsTest
	static void test_getDocumentFolders_Document() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Document d1 = TestUtils.createDocument();
			Schema.Document d2 = TestUtils.createDocument();

			Test.startTest();
			Document.Folders result = DocumentService.getDocumentFolders(Schema.Document.getSObjectType());
			Test.stopTest();

			System.assertNotEquals(null, result);

			System.assertNotEquals(null, result.folders);
			System.assert(result.folders.size() >= 1);
			Boolean foundPersonal = false;
			for (Document.Folder f : result.folders) {
				if (f.Id == UserInfo.getUserId()) {
					foundPersonal = true;
					break;
				}
			}
			System.assert(foundPersonal);

			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			Boolean foundD1 = false, foundD2 = false;
			for (Document d : result.documents) {
				if (d.sourceId == d1.Id) {
					foundD1 = true;
				} else if (d.sourceId == d2.Id) {
					foundD2 = true;
				}
			}
			System.assert(foundD1);
			System.assert(foundD2);
		}
	}

	@IsTest
	static void test_getFolderDocuments_ContentVersion() {
		System.runAs(UserMock.createDocuSignUser()) {
			// Cannot create and link doc to workspace in one go, so try using existing one. Otherwise skip test.
			ContentWorkspace cw = TestUtils.getFirstAvailableContentWorkspace();
			if (cw != null) {
				ContentVersion cv1 = TestUtils.createContentVersion();
				ContentVersion cv2 = TestUtils.createContentVersion();
				ContentWorkspaceDoc cwd1 = TestUtils.createContentWorkspaceDoc(cw.Id, cv1.ContentDocumentId);
				ContentWorkspaceDoc cwd2 = TestUtils.createContentWorkspaceDoc(cw.Id, cv2.ContentDocumentId);

				Test.startTest();
				List<Document> result = DocumentService.getFolderDocuments(ContentVersion.getSObjectType(), new Set<Id> { cw.Id });
				Test.stopTest();

				System.assertNotEquals(null, result);
				System.assert(result.size() >= 2);
			}
		}
	}

	@IsTest
	static void test_getFolderDocuments_Document() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Document d1 = TestUtils.createDocument();
			Schema.Document d2 = TestUtils.createDocument();

			Test.startTest();
			List<Document> result = DocumentService.getFolderDocuments(Schema.Document.getSObjectType(), new Set<Id> { UserInfo.getUserId() });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_getEnvelopeDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id));

			Test.startTest();
			List<Document> result = DocumentService.getEnvelopeDocuments(dse.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_addEnvelopeDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = new Document(null, Document.TYPE_TEMPLATE, 1, 'doc1', null, null, Datetime.now(), UUID.randomUUID().toString());
			Document d2 = new Document(null, Document.TYPE_FILE, 2, 'doc2', 'pdf', 1234, Datetime.now(), UUID.randomUUID().toString());
			Exception ex1, ex2;

			Test.startTest();
			List<Document> result = DocumentService.addEnvelopeDocuments(dse.Id, new List<Document> { d1, d2 });
			try {
				DocumentService.addEnvelopeDocuments(null, new List<Document> { d1, d2 });
				throw new AssertException('Expected addEnvelopeDocuments to fail');
			} catch (DocuSignException ex) {
				ex1 = ex;
			}
			try {
				DocumentService.addEnvelopeDocuments(dse.Id, new List<Document>());
				throw new AssertException('Expected addEnvelopeDocuments to fail');
			} catch (DocuSignException ex) {
				ex2 = ex;
			}
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, ex1);
			System.assertEquals(Label.UndefinedEnvelope, ex1.getMessage());

			System.assertNotEquals(null, ex2);
			System.assertEquals(Label.UndefinedDocument, ex2.getMessage());
		}
	}

	@IsTest
	static void test_removeEnvelopeDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 1));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 2));
			Exception ex1, ex2;

			Test.startTest();
			List<Document> result = DocumentService.removeEnvelopeDocuments(dse.Id, new Set<Id> { d1.Id });
			try {
				DocumentService.removeEnvelopeDocuments(null, new Set<Id> { d1.Id });
				throw new AssertException('Expected removeEnvelopeDocuments to fail');
			} catch (DocuSignException ex) {
				ex1 = ex;
			}
			try {
				DocumentService.removeEnvelopeDocuments(dse.Id, new Set<Id>());
				throw new AssertException('Expected removeEnvelopeDocuments to fail');
			} catch (DocuSignException ex) {
				ex2 = ex;
			}
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(d2.id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, ex1);
			System.assertEquals(Label.UndefinedEnvelope, ex1.getMessage());

			System.assertNotEquals(null, ex2);
			System.assertEquals(Label.UndefinedDocument, ex2.getMessage());
		}
	}

	@IsTest
	static void test_reorderEnvelopeDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 3));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 5));
			Document d3 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id, 7));
			Exception ex1, ex2;

			Test.startTest();
			List<Document> result = DocumentService.reorderEnvelopeDocuments(dse.Id, new Map<Id, Integer> {
				d3.id => 1,
				d2.id => 2,
				d1.id => 3
			});
			try {
				DocumentService.reorderEnvelopeDocuments(null, new Map<Id, Integer> { d1.Id => 1 });
				throw new AssertException('Expected reorderEnvelopeDocuments to fail');
			} catch (DocuSignException ex) {
				ex1 = ex;
			}
			try {
				DocumentService.reorderEnvelopeDocuments(dse.Id, new Map<Id, Integer>());
				throw new AssertException('Expected reorderEnvelopeDocuments to fail');
			} catch (DocuSignException ex) {
				ex2 = ex;
			}
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(d3.id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(d2.id, result[1].id);
			System.assertEquals(2, result[1].sequence);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(d1.id, result[2].id);
			System.assertEquals(3, result[2].sequence);
		}
	}

	@IsTest
	static void test_updateEnvelopeDocuments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c dse = TestUtils.createEnvelope();
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id));
			Document d2 = new Document(
				null,
				Document.TYPE_TEMPLATE,
				null,
				UUID.randomUUID().toString(),
				null,
				null,
				Datetime.now(),
				UUID.randomUUID().toString());
			Document d3 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(dse.Id));

			Test.startTest();
			List<Document> result = DocumentService.updateEnvelopeDocuments(
				dse.Id,
				new List<Document> { d1, d3 },
				new List<Document> { d1, d2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(d1.id, result[0].id);
			System.assertEquals(d1.type, result[0].type);
			System.assertEquals(1, result[0].sequence);
			System.assertEquals(d1.name, result[0].name);
			System.assertEquals(d1.extension, result[0].extension);
			System.assertEquals(d1.size, result[0].size);
			System.assertEquals(d1.lastModified, result[0].lastModified);
			System.assertEquals(d1.sourceId, result[0].sourceId);

			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id); // Id assigned on insert
			System.assertEquals(d2.type, result[1].type);
			System.assertEquals(2, result[1].sequence);
			System.assertEquals(d2.name, result[1].name);
			System.assertEquals(d2.extension, result[1].extension);
			System.assertEquals(d2.size, result[1].size);
			System.assertEquals(d2.lastModified, result[1].lastModified);
			System.assertEquals(d2.sourceId, result[1].sourceId);
		}
	}

	@IsTest
	static void test_resolveFiles_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				DocumentService.resolveFiles(null);
				throw new AssertException('Expected resolveFiles to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveFiles_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			List<Document> result = DocumentService.resolveFiles(new Set<Id> { cv1.Id, cv2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_resolveTemplates_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				DocumentService.resolveTemplates(null);
				throw new AssertException('Expected resolveTemplates to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveTemplates_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<Document> result = DocumentService.resolveTemplates(new Set<UUID> { UUID.randomUUID(), UUID.randomUUID() });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_resolveLinkedFiles_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				DocumentService.resolveLinkedFiles(null, false);
				throw new AssertException('Expected resolveLinkedFiles to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveLinkedFiles_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			ContentVersion cv1 = TestUtils.createContentVersion(a1.Id);
			ContentVersion cv2 = TestUtils.createContentVersion(a1.Id);
			ContentVersion cv3 = TestUtils.createContentVersion(a2.Id);

			Test.startTest();
			List<Document> result = DocumentService.resolveLinkedFiles(new Set<Id> { a1.Id, a2.Id }, false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
		}
	}
}
