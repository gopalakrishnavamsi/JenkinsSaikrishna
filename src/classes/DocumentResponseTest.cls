@IsTest
private class DocumentResponseTest {

	static testMethod void test_success() {
		Envelope__c dse = TestUtils.createEnvelope();
		List<Document> ds = new List<Document> {
			Document.convert(TestUtils.createEnvelopeDocument(dse.Id)),
			Document.convert(TestUtils.createEnvelopeDocument(dse.Id))
		};
		List<CustomField> cfs = new List<CustomField> {
			new CustomField('n1', 'v1', true, true),
			new CustomField('n2', 'v2', true, true)
		};
		List<Document.Folder> fs = new List<Document.Folder> {
			new Document.Folder(UserInfo.getUserId(), 'f1'),
			new Document.Folder(UserInfo.getOrganizationId(), 'f2')
		};

		Test.startTest();
		DocumentResponse result1 = DocumentResponse.success(new Document.Folders(fs, ds));
		DocumentResponse result2 = DocumentResponse.success(ds);
		DocumentResponse result3 = DocumentResponse.success(ds, cfs);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.success);
		System.assert(Collection.isEmpty(result1.messages));
		System.assertEquals(fs, result1.folders);
		System.assertEquals(ds, result1.documents);
		System.assertEquals(null, result1.customFields);

		System.assertNotEquals(null, result2);
		System.assert(result2.success);
		System.assert(Collection.isEmpty(result2.messages));
		System.assertEquals(null, result2.folders);
		System.assertEquals(ds, result2.documents);
		System.assertEquals(null, result2.customFields);

		System.assertNotEquals(null, result3);
		System.assert(result3.success);
		System.assert(Collection.isEmpty(result3.messages));
		System.assertEquals(null, result3.folders);
		System.assertEquals(ds, result3.documents);
		System.assertEquals(cfs, result3.customFields);
	}

	static testMethod void test_failure() {
		Test.startTest();
		DocumentResponse result1 = DocumentResponse.failure(new DocuSignException('fail'));
		DocumentResponse result2 = DocumentResponse.failure(new List<APIError> {
			new APIError(APIErrorCode.BAD_REQUEST, 'fail1'),
			new APIError(APIErrorCode.FAILURE, 'fail2')
		});
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.success);
		System.assert(!Collection.isEmpty(result1.messages));
		System.assertEquals(1, result1.messages.size());
		System.assertEquals('fail', result1.messages[0].description);
		System.assertEquals(null, result1.folders);
		System.assertEquals(null, result1.documents);
		System.assertEquals(null, result1.customFields);

		System.assertNotEquals(null, result2);
		System.assert(!result2.success);
		System.assert(!Collection.isEmpty(result2.messages));
		System.assertEquals(2, result2.messages.size());
		System.assertEquals('fail1', result2.messages[0].description);
		System.assertEquals('fail2', result2.messages[1].description);
		System.assertEquals(null, result2.folders);
		System.assertEquals(null, result2.documents);
		System.assertEquals(null, result2.customFields);
	}
}
