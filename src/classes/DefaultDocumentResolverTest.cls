@IsTest
private class DefaultDocumentResolverTest {

	static testMethod void test_canResolve() {
		DefaultDocumentResolver dr = new DefaultDocumentResolver();

		Test.startTest();
		System.assert(dr.canResolve('ContentVersion'));
		System.assert(dr.canResolve(' attachment '));
		System.assert(dr.canResolve('DOCUMENT'));
		System.assert(!dr.canResolve('whatever'));
		System.assert(!dr.canResolve(null));
		System.assert(!dr.canResolve(' '));
		Test.stopTest();
	}

	static testMethod void test_resolve_ContentVersion() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			ContentVersion obj = TestUtils.createContentVersion();

			Test.startTest();
			Document result = dr.resolve('contentVersion\t', obj.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Document.TYPE_FILE, result.type);
			System.assertEquals(obj.Title, result.name);
			System.assertEquals(obj.FileExtension, result.extension);
			System.assertEquals(obj.ContentSize, result.size);
			System.assertEquals(obj.Id, result.sourceId);
		}
	}

	static testMethod void test_resolve_Attachment() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Attachment obj = TestUtils.createAttachment();

			Test.startTest();
			Document result = dr.resolve(' Attachment ', obj.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Document.TYPE_ATTACHMENT, result.type);
			System.assertEquals(obj.Name, result.name);
			System.assertEquals(Document.getFileExtension(obj.Name), result.extension);
			System.assertEquals(obj.BodyLength, result.size);
			System.assertEquals(obj.Id, result.sourceId);
		}
	}

	static testMethod void test_resolve_Document() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Document obj = TestUtils.createDocument();

			Test.startTest();
			Document result = dr.resolve('\nDOCUMENT', obj.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Document.TYPE_DOCUMENT, result.type);
			System.assertEquals(obj.Name, result.name);
			System.assertEquals(obj.Type, result.extension);
			System.assertEquals(obj.BodyLength, result.size);
			System.assertEquals(obj.Id, result.sourceId);
		}
	}

	static testMethod void test_resolve_invalid() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			try {
				dr.resolve('User', UserInfo.getUserId());
				throw new AssertException('Expected resolve to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveDocument_2,
					new List<String> { UserInfo.getUserId(), 'User' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_getBytes_ContentVersion() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			ContentVersion obj = TestUtils.createContentVersion();

			Test.startTest();
			Blob result = dr.getBytes('ContentVersion', obj.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(obj.VersionData.toString(), result.toString());
		}
	}

	static testMethod void test_getBytes_Attachment() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Attachment obj = TestUtils.createAttachment();

			Test.startTest();
			Blob result = dr.getBytes('Attachment', obj.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(obj.Body.toString(), result.toString());
		}
	}

	static testMethod void test_getBytes_Document() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();
			Schema.Document obj = TestUtils.createDocument();

			Test.startTest();
			Blob result = dr.getBytes('Document', obj.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(obj.Body.toString(), result.toString());
		}
	}

	static testMethod void test_getBytes_invalid() {
		System.runAs(TestUtils.createUser()) {
			DefaultDocumentResolver dr = new DefaultDocumentResolver();

			Test.startTest();
			try {
				dr.getBytes('User', UserInfo.getUserId());
				throw new AssertException('Expected getBytes to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveDocument_2,
					new List<String> { UserInfo.getUserId(), 'User' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
