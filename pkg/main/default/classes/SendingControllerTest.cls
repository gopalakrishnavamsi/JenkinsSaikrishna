@IsTest
private class SendingControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(UserMock.createUser()) {
			SObject a = TestUtils.createAccount();
			PageReference pg = Page.Sending;
			pg.getParameters().put('sId', a.Id);
			Test.setCurrentPage(pg);

			Test.startTest();
			SendingController result1 = new SendingController();
			SendingController result2 = new SendingController(new ApexPages.StandardController(a));
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(a.getSObjectType().getDescribe().getName(), result1.sObjectName);
			System.assertNotEquals(null, result2);
			System.assertEquals(a.getSObjectType().getDescribe().getName(), result2.sObjectName);
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
	static void test_deleteDocument_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			String scmFile = 'scm;' + ScmAPIMock.DOCUMENT_ID + ';UnitTestScmFile1;html';
			Test.startTest();
			System.assert(SendingController.deleteDocument(scmFile));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteDocument_unAuthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			String scmFile = 'scm;' + ScmAPIMock.DOCUMENT_ID + ';UnitTestScmFile1;html';
			Test.startTest();
			try {
				SendingController.deleteDocument(scmFile);
				throw new AssertException('Expected deleteDocument to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createDraftEnvelopeFromTemplate_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				SendingController.createDraftEnvelopeFromTemplate(UserInfo.getUserId(), UserInfo.getUserId());
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createDraftEnvelopeFromTemplate_undefined_argument() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			try {
				SendingController.createDraftEnvelopeFromTemplate(null, null);
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createDraftEnvelopeFromTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ContentVersion td = TestUtils.createContentVersion();
			EnvelopeConfiguration ec = EnvelopeConfigurationService.DB.insertEnvelopeConfiguration(new EnvelopeConfiguration(
				null,
				UUID.randomUUID().toString(),
				'Opportunity',
				UUID.randomUUID(),
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						td.ContentDocumentId,
						1,
						td.Title,
						td.FileExtension,
						false,
						false),
					new EnvelopeConfiguration.SourceFiles(
						null,
						new Query.Filter(
							'ContentDocument.Title LIKE \'a%\'', // expect cva2
							'ContentDocument.Title DESC',
							1
						),
						2,
						false,
						false)
				},
				new List<Recipient> {
					new EnvelopeConfiguration.LookupRecipient(
						new Query.Relationship(
							true,
							'Owner',
							'Owner',
							'User'),
						Recipient.TYPE_CARBON_COPY,
						1,
						'r1',
						false,
						false)
						.withEmailSettings(new Recipient.EmailSettings(
						Localization.EN,
						null,
						'For account {!Opportunity.Account.Name}',
						'From our company, {!$Organization.Name}')),
					new EnvelopeConfiguration.RelatedRecipients(
						new Query.Relationship(
							false,
							'OpportunityContactRoles',
							'Opportunity Contact Roles',
							'OpportunityContactRole'),
						new Query.Filter(
							'Role IN (\'r2\', \'r3\')',
							null,
							2),
						Recipient.TYPE_SIGNER,
						2,
						true,
						new List<String> { 'r2', 'r3' },
						false,
						false)
						.withNote('Dear {!$Recipient.Name}, check this out'),
					Recipient.fromSource(
						UUID.randomUUID().toString(),
						UUID.randomUUID() + '@unit.test',
						String.valueOf(TestUtils.randomInteger(10000000)),
						'r4',
						new Entity(UserInfo.getUserId()))
				},
				new List<CustomField> {
					CustomField.newTextField('n1', 'v1', true, true),
					CustomField.newListField('n1', 'v1', new List<String> { 'v1', 'v2', 'v3' }, true, true)
				},
				new Notifications(
					true,
					1,
					2,
					true,
					3,
					4),
				'Subject {!Opportunity.Name}',
				'From {!$User.FirstName} {!$User.LastName}',
				new List<Tab> {
					Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', true, true),
					Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
				},
				Envelope.DEFAULT_PERMISSIONS,
				Envelope.DEFAULT_OPTIONS,
				true));
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			TestUtils.createContentVersion(o.Id, 'a1', 'pdf');
			ContentVersion cva2 = TestUtils.createContentVersion(o.Id, 'a2', 'pdf');
			TestUtils.createContentVersion(o.Id, 'b1', 'pdf');
			Contact c1 = TestUtils.createContact(a.Id, 'a1', 'z1', 'a1.z1@unit.test', '11111111');
			TestUtils.createOpportunityContactRole(o.Id, c1.Id, 'r1');
			Contact c2 = TestUtils.createContact(a.Id, 'a2', 'z2', 'a2.z2@unit.test', '22222222');
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id, 'r2');
			Contact c3 = TestUtils.createContact(a.Id, 'b1', 'z3', 'b1.z3@unit.test', '33333333');
			OpportunityContactRole ocr3 = TestUtils.createOpportunityContactRole(o.Id, c3.Id, 'r3');

			Test.startTest();
			SendingController.DraftEnvelope draftEnvelope = SendingController.createDraftEnvelopeFromTemplate(ec.id, o.Id);
			Envelope result = draftEnvelope.envelope;
			Test.stopTest();


			System.assertNotEquals(null, result);
			System.assertEquals(ec.id, result.envelopeConfigurationId);

			System.assertEquals(2, Collection.size(result.documents));
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(Document.TYPE_TEMPLATE, result.documents[0].type);
			System.assertEquals(1, result.documents[0].sequence);
			System.assertEquals(ec.name, result.documents[0].name);
			System.assertEquals(String.valueOf(ec.docuSignId), result.documents[0].sourceId);
			System.assert(result.documents[0].readOnly);
			System.assert(result.documents[0].required);

			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(null, result.documents[1].id);
			System.assertEquals(Document.TYPE_FILE, result.documents[1].type);
			System.assertEquals(2, result.documents[1].sequence);
			System.assertEquals(cva2.Title, result.documents[1].name);
			System.assertEquals(cva2.FileExtension, result.documents[1].extension);
			System.assertEquals(cva2.ContentSize, result.documents[1].size);
			System.assertNotEquals(null, result.documents[1].lastModified);
			System.assertEquals(cva2.Id, result.documents[1].sourceId);
			System.assert(!result.documents[1].readOnly);
			System.assert(!result.documents[1].required);

			System.assertEquals(4, Collection.size(result.recipients));
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals(UserInfo.getName(), result.recipients[0].name);
			System.assertEquals(UserInfo.getUserEmail(), result.recipients[0].email);
			System.assertEquals('r1', result.recipients[0].getRoleName());
			System.assertNotEquals(null, result.recipients[0].emailSettings);
			System.assertEquals('For account ' + a.Name, result.recipients[0].emailSettings.subject);
			System.assertEquals('From our company, ' + UserInfo.getOrganizationName(), result.recipients[0].emailSettings.message);
			System.assertEquals(null, result.recipients[0].note);

			System.assertNotEquals(null, result.recipients[1]);
			System.assertEquals(ocr2.Contact.Name, result.recipients[1].name);
			System.assertEquals(ocr2.Contact.Email, result.recipients[1].email);
			System.assertEquals(ocr2.Role, result.recipients[1].getRoleName());
			System.assertEquals(null, result.recipients[1].emailSettings);
			System.assertEquals('Dear ' + result.recipients[1].name + ', check this out', result.recipients[1].note);

			System.assertNotEquals(null, result.recipients[2]);
			System.assertEquals(ocr3.Contact.Name, result.recipients[2].name);
			System.assertEquals(ocr3.Contact.Email, result.recipients[2].email);
			System.assertEquals(ocr3.Role, result.recipients[2].getRoleName());
			System.assertEquals(null, result.recipients[2].emailSettings);
			System.assertEquals('Dear ' + result.recipients[2].name + ', check this out', result.recipients[2].note);

			System.assertNotEquals(null, result.recipients[3]);
			System.assertEquals(UserInfo.getName(), result.recipients[3].name);
			System.assertEquals(UserInfo.getUserEmail(), result.recipients[3].email);
			System.assertEquals('r4', result.recipients[3].getRoleName());
			System.assertEquals(UserInfo.getUserId(), result.recipients[3].getSourceId());

			System.assertEquals(2, Collection.size(result.customFields));
			System.assertNotEquals(null, result.notifications);
			System.assertNotEquals(null, result.options);
			System.assertEquals('Subject ' + o.Name, result.emailSubject);
			System.assertEquals('From ' + UserInfo.getName(), result.emailMessage);
			System.assertNotEquals(null, result.senderPermissions);
			System.assertNotEquals(null, result.source);
			System.assertEquals(o.Id, result.source.id);
		}
	}
}
