/**
 * Contains tests mostly corresponding to code examples on Developer Center. If these tests break or change, so must the
 * examples at https://developers.docusign.com/salesforce/code-examples.
 */
@IsTest
private class CodeExampleTest {

	@IsTest
	static void test_send_with_template() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Id mySourceId = TestUtils.createContact().Id;

			Test.startTest();

			Envelope myEnvelope = EnvelopeService.getEmptyEnvelope(new Entity(mySourceId));

			Contact myContact = [SELECT Id, Name, Email FROM Contact LIMIT 1];

			Recipient myRecipient = Recipient.fromSource(
				myContact.Name,
				myContact.Email,
				null,
				'Signer 1',
				new Entity(myContact.Id));

			myEnvelope = myEnvelope.withRecipients(new List<Recipient> { myRecipient });

			UUID myTemplateId = UUID.parse('01234567-89ab-cdef-0123-456789abcdef');

			Document myDocument = Document.fromTemplate(
				myTemplateId,
				'myTemplate');

			myEnvelope = myEnvelope.withDocuments(new List<Document> { myDocument });

			myEnvelope = EnvelopeService.sendEnvelope(
				myEnvelope,
				true);
			System.assertNotEquals(null, myEnvelope);
			System.assert(!UUID.isEmpty(myEnvelope.docuSignId));

			List<Envelope.Status> myStatus = StatusService.getStatus(
				new Set<Id> {
					mySourceId
				},
				5);
			System.assertEquals(1, Collection.size(myStatus));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_embedded_signing_1() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
		User u = UserMock.createDocuSignSender();
		Opportunity o;
		Schema.Document d;
		UUID myEnvelopeId;

		System.runAs(u) {
			o = TestUtils.createOpportunity();
			d = TestUtils.createDocument();
		}

		Test.startTest();
		System.runAs(u) {
			Id mySourceId = o.Id;
			Id myDocumentId = d.Id;

			Envelope myEnvelope = EnvelopeService.getEmptyEnvelope(new Entity(mySourceId))
				.withDocuments(DocumentService.getDocuments(
					Schema.Document.getSObjectType(),
					new Set<Id> {
						myDocumentId
					}))
				.withRecipients(new List<Recipient> {
					Recipient.newEmbeddedSigner()
				});

			myEnvelope = EnvelopeService.sendEnvelope(
				myEnvelope,
				true);
			System.assertNotEquals(null, myEnvelope);
			System.assert(!UUID.isEmpty(myEnvelope.docuSignId));

			myEnvelopeId = myEnvelope.docuSignId;
		}
		Test.stopTest();
	}

	@IsTest
	static void test_embedded_signing_2() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
		UUID myEnvelopeId = UUID.randomUUID();

		System.runAs(UserMock.createDocuSignSender()) {
			Test.startTest();
			Url result = SigningService.getEmbeddedSigningUrl(
				myEnvelopeId,
				new Url('https://my.return.url'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_bulk_send_1() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Id myGroupId = UserInfo.getOrganizationId();

			Test.startTest();
			List<Envelope> myBulkCopies = new List<Envelope>();
			for (Integer i = 0; i < 3; i++) {
				myBulkCopies.add(Envelope.newBulkCopy(
					Recipient.newBulkRecipient(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						new Entity(UserInfo.getOrganizationId()))));
			}

			BulkList myList = BulkSendService.createLists(new List<BulkList> {
				BulkList.newList(
					'My bulk list',
					myBulkCopies,
					new Entity(myGroupId))
			})[0];
			Test.stopTest();

			System.assertNotEquals(null, myList);
		}
	}

	@IsTest
	static void test_bulk_send_2() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Id myFileId = TestUtils.createContentVersion().Id;
			BulkList__c bl = new BulkList__c(
				Name = UUID.randomUUID().toString(),
				DocuSignId__c = UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getUserId());
			insert bl;

			Test.startTest();
			Envelope myEnvelope = BulkSendService.getDraftEnvelope(
				DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id> { myFileId }),
				null);
			System.assertNotEquals(null, myEnvelope);

			BulkList.Result myResult = BulkSendService.sendEnvelope(bl.Id, myEnvelope);
			System.assertNotEquals(null, myResult);

			Id myStatusId = myResult.bulkStatusId;

			BulkList.Status myStatus = BulkSendService.getStatus(new Set<Id> { myStatusId })[0];
			System.assertNotEquals(null, myStatus);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_unit_testing() {
		// Set the HTTP callout test mock to the DocuSign eSignature REST API mock.
		TestUtils.setMock(new ESignatureAPIMock());

		// Do something that requires DocuSign Sender permissions
		System.runAs(UserMock.createDocuSignSender()) { // or createDocuSignUser, or createDocuSignAdministrator
			Test.startTest();
			Url myUrl = SigningService.getEmbeddedSigningUrl(
				UUID.randomUUID(), // Random envelope ID for testing
				new Url('https://my.return.url')); // The return URL
			System.assertNotEquals(null, myUrl, 'Expected returned URL to be non-null');
			Test.stopTest();
		}
	}
}
