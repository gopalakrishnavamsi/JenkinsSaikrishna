@IsTest
private class SendingControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(UserMock.createUser()) {
			SObject a = TestUtils.createAccount();

			Test.startTest();
			SendingController result1 = new SendingController();
			SendingController result2 = new SendingController(new ApexPages.StandardController(a));
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result2);
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
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			TestUtils.createContentVersion(l.Id);
			TestUtils.createContentVersion(l.Id);

			Test.startTest();
			SendingController.DraftEnvelope result = SendingController.createDraftEnvelope(l.Id, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.envelope);
			System.assertNotEquals(null, result.templates);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(1, result.recipients.size());
			System.assert(Collection.isNotEmpty(result.defaultRoles));
			System.assertEquals(Localization.isEmailLocalizationEnabled()
				? Localization.getEmailSettings() : new List<Recipient.EmailSettings>(), result.emailLocalizations);
		}
	}

	@IsTest
	static void test_createDraftEnvelope_with_files() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			String scmFile1 = 'scm;' + UUID.randomUUID() + ';UnitTestScmFile1;html';
			String scmFile2 = 'scm;' + UUID.randomUUID() + ';UnitTestScmFile2;html';
			Test.startTest();
			SendingController.DraftEnvelope result = SendingController.createDraftEnvelope(
				l.Id,
				new List<String> { cv1.Id, cv2.Id, scmFile1, scmFile2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.envelope);
			System.assertNotEquals(null, result.templates);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(4, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(1, result.recipients.size());
			System.assert(Collection.isNotEmpty(result.defaultRoles));
			System.assertEquals(Localization.isEmailLocalizationEnabled()
				? Localization.getEmailSettings() : new List<Recipient.EmailSettings>(), result.emailLocalizations);
		}
	}

	@IsTest
	static void test_createDraftEnvelope_error() {
		DocuSignAPIMock.success();
		Case c = TestUtils.createCase();

		System.runAs(UserMock.createDocuSignSender()) { // Unauthorized
			Test.startTest();
			try {
				SendingController.createDraftEnvelope(c.Id, null);
				throw new AssertException('Expected createDraftEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class UnauthorizedTemplateMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"errorCode":"USER_LACKS_PERMISSIONS","message":"This user lacks sufficient permissions to access this resource."}');
			return response;
		}
	}

	@IsTest
	static void test_createDraftEnvelope_templates_unauthorized() {
		Test.setMock(HttpCalloutMock.class, new UnauthorizedTemplateMock());

		System.runAs(UserMock.createDocuSignUser()) { // Unauthorized
			Lead l = TestUtils.createLead();

			Test.startTest();
			SendingController.DraftEnvelope result = SendingController.createDraftEnvelope(l.Id, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.templates);
		}
	}

	class ConsentRequiredMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"error":"consent_required","error_message":"Consent is required."}');
			return response;
		}
	}

	@IsTest
	static void test_createDraftEnvelope_consent_required() {
		Test.setMock(HttpCalloutMock.class, new ConsentRequiredMock());
		System.runAs(UserMock.createDocuSignUser()) {
			delete UserSettings__c.getInstance();
			Lead l = TestUtils.createLead();

			Test.startTest();
			try {
				SendingController.createDraftEnvelope(l.Id, null);
				throw new AssertException('Expected createDraftEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.ConsentRequired, ex.getMessage());
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
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope())
				.withDocuments(new List<Document> {
					Document.fromFile(TestUtils.createContentVersion())
				})
				.withRecipients(new List<Recipient> {
					Recipient.newInPersonSigner(1, null, 'Recipient One', 'r1@unit.test', null, null, null, null, false)
				});

			Test.startTest();
			Envelope result = SendingController.sendEnvelope(JSON.serialize(e), false, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendEnvelope_trial_expired() {
		System.runAs(UserMock.createDocuSignUser(true)) {
			ProductSettings__c ps = ProductSettings__c.getAll().get(Product.ESIGNATURE);
			System.assertNotEquals(null, ps);
			ps.IsTrial__c = true;
			ps.TrialExpires__c = Date.today().addDays(-1);
			update ps;

			Test.startTest();
			try {
				SendingController.sendEnvelope(null, false, false);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.ExpiredTrialAccount, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_error() {
		Envelope e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(true)) { // Unauthorized
			Test.startTest();
			try {
				SendingController.sendEnvelope(JSON.serialize(e), false, false);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTaggerUrl_success() {
		DocuSignAPIMock.success();

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

	@IsTest
	static void test_deleteAttachment_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			ContentVersion cv = TestUtils.createContentVersion();
			System.assertNotEquals(null, cv.ContentDocumentId);
			Test.startTest();
			SendingController.deleteAttachment(cv.Id);
			Test.stopTest();
			System.assert(Collection.isEmpty([SELECT Id FROM ContentVersion WHERE Id = :cv.Id]));
			System.assert(Collection.isEmpty([SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId]));
		}
	}
}
