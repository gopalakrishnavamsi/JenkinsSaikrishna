@IsTest
private class SendingControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(UserMock.createUser()) {
			SObject a = TestUtils.createAccount();

			Test.startTest();
			SendingController result = new SendingController(new ApexPages.StandardController(a));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Application.lightningNamespace, result.namespace);
			System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
			System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
		}
	}

	@IsTest
	static void test_getReturnUrl() {
		System.runAs(UserMock.createUser()) {
			Id sId = UserInfo.getUserId();
			Id eId = UserInfo.getOrganizationId();

			Test.startTest();
			Url result = SendingController.getReturnUrl(sId, eId);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Salesforce.baseUrl.getHost(), result.getHost());
			QueryString params = QueryString.parse(result.getQuery());
			System.assertEquals(sId, params.getId(QueryString.PARAM_SOURCE_ID));
			System.assertEquals(eId, params.getId(QueryString.PARAM_ENVELOPE_ID));
			System.assertEquals('tag', params.getString(QueryString.PARAM_DOCUSIGN_ACTION));
		}
	}

	@IsTest
	static void test_createDraftEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			TestUtils.createContentVersion(l.Id);
			TestUtils.createContentVersion(l.Id);

			Test.startTest();
			SendingController.DraftEnvelope result = SendingController.createDraftEnvelope(l.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(AccountFeatures.getInstance() === result.accountFeatures);
			System.assertNotEquals(null, result.envelope);
			System.assertNotEquals(null, result.templates);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(1, result.recipients.size());
			EnvelopeSettings es = EnvelopeSettings.getInstance();
			System.assertEquals(es.defaultRoles, result.defaultRoles);
			System.assertEquals(es.allowRecipientLanguageSelection
				? es.emailLocalizations : new List<Recipient.EmailSettings>(), result.emailLocalizations);
		}
	}

	@IsTest
	static void test_createDraftEnvelope_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
		UserMock.createDocuSignAdministrator();

		System.runAs(UserMock.createUser()) { // Unauthorized
			Case c = TestUtils.createCase();

			Test.startTest();
			try {
				SendingController.createDraftEnvelope(c.Id);
				throw new AssertException('Expected createDraftEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLinkedDocuments_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Case c = TestUtils.createCase();
			TestUtils.createContentDocumentLink(c.Id);
			TestUtils.createContentDocumentLink(c.Id);

			Test.startTest();
			List<Document> result = SendingController.getLinkedDocuments(c.Id);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_getLinkedDocuments_error() {
		System.runAs(UserMock.createUser()) { // Unauthorized
			Test.startTest();
			try {
				SendingController.getLinkedDocuments(UserInfo.getUserId());
				throw new AssertException('Expected getLinkedDocuments to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveRecipient_user() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Recipient result = SendingController.resolveRecipient(UserInfo.getUserId());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.source);
			System.assertEquals(UserInfo.getUserId(), result.source.id);
		}
	}

	@IsTest
	static void test_resolveRecipient_contact() {
		System.runAs(UserMock.createDocuSignUser()) {
			Contact c = TestUtils.createContact();

			Test.startTest();
			Recipient result = SendingController.resolveRecipient(c.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.source);
			System.assertEquals(c.Id, result.source.id);
		}
	}

	@IsTest
	static void test_resolveRecipient_lead() {
		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();

			Test.startTest();
			Recipient result = SendingController.resolveRecipient(l.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.source);
			System.assertEquals(l.Id, result.source.id);
		}
	}

	@IsTest
	static void test_resolveRecipient_error() {
		System.runAs(UserMock.createUser()) { // Unauthorized
			Test.startTest();
			try {
				SendingController.resolveRecipient(UserInfo.getUserId());
				throw new AssertException('Expected resolveRecipient to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateEnvelope_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope())
				.withRecipients(new List<Recipient> {
					Recipient.newInPersonSigner(1, null, 'Recipient One', 'r1@unit.test', null, null, null, null, false)
				});

			Test.startTest();
			Envelope result = SendingController.updateEnvelope(JSON.serialize(e));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, Collection.size(result.recipients));
			System.assertEquals(UserInfo.getName(), result.recipients[0].hostName);
			System.assertEquals(UserInfo.getUserEmail(), result.recipients[0].hostEmail);
			System.assert(result.recipients[0].signNow);
		}
	}

	@IsTest
	static void test_updateEnvelope_error() {
		Envelope e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SendingController.updateEnvelope(JSON.serialize(e));
				throw new AssertException('Expected updateEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope())
				.withDocuments(new List<Document> {
					DocumentService.convert(TestUtils.createContentVersion())
				})
				.withRecipients(new List<Recipient> {
					Recipient.newInPersonSigner(1, null, 'Recipient One', 'r1@unit.test', null, null, null, null, false)
				});

			Test.startTest();
			Envelope result = SendingController.sendEnvelope(JSON.serialize(e));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendEnvelope_error() {
		Envelope e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SendingController.sendEnvelope(JSON.serialize(e));
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTaggerUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope(UserInfo.getUserId()));

			Test.startTest();
			String result = SendingController.getTaggerUrl(JSON.serialize(e));
			Test.stopTest();

			System.assert(String.isNotBlank(result));
		}
	}

	@IsTest
	static void test_getTaggerUrl_invalid() {
		Envelope e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = EnvelopeService.DB.convert(TestUtils.createEnvelope(null, null));
		}

		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SendingController.getTaggerUrl(JSON.serialize(e));
				throw new AssertException('Expected getTaggerUrl to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.InvalidEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTaggerUrl_error() {
		Envelope e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = EnvelopeService.DB.convert(TestUtils.createEnvelope(UserInfo.getUserId()));
		}

		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SendingController.getTaggerUrl(JSON.serialize(e));
				throw new AssertException('Expected getTaggerUrl to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelope_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();

			Test.startTest();
			SendingController.deleteEnvelope(e.Id);
			Test.stopTest();

			System.assert(Collection.isEmpty([SELECT Id FROM Envelope__c WHERE Id = :e.Id]));
		}
	}

	@IsTest
	static void test_deleteEnvelope_error() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SendingController.deleteEnvelope(e.Id);
				throw new AssertException('Expected deleteEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
