@IsTest
private class TemplateAPITest {

	@IsTest
	static void test_addGroupShare_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			System.assert(client.addGroupShare(UUID.randomUUID(), 1234L, 1000));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addGroupShare_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.addGroupShare(UUID.randomUUID(), 1234L, 1000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			CustomField cf1 = CustomField.newListField('lf', 'v1', new List<String> { 'v1', 'v2', 'v3' }, false, true);
			CustomField cf2 = CustomField.newTextField('tf', 'v1', true, true);
			Notifications n = new Notifications(true, 10, 2, true, 20, 18);
			Document d1 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(1);
			Document d2 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(2);
			Contact c1 = TestUtils.createContact();
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				String.valueOf(TestUtils.randomInteger(1000000)),
				UUID.randomUUID().toString(),
				new Entity(c1.Id))
				.withSequence(1)
				.withRoutingOrder(1);
			Recipient r2 = Recipient.newInPersonSigner(
				2,
				new Recipient.Role(UUID.randomUUID().toString()),
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				UUID.randomUUID().toString(),
				true)
				.withSequence(2);
			Template t = new Template(
				null,
				UUID.randomUUID().toString(),
				new List<CustomField> { cf1, cf2 },
				n,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Document> { d1, d2 },
				new List<Recipient> { r1, r2 },
				null);

			Test.startTest();
			Template result = TemplateAPI.getInstance().createTemplate(t, 1234L);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(t.name, result.name);
			System.assertEquals(2, Collection.size(result.customFields));
			System.assertNotEquals(null, result.customFields[0]);
			System.assertEquals(cf1.type, result.customFields[0].type);
			System.assertEquals(cf1.name, result.customFields[0].name);
			System.assertEquals(cf1.value, result.customFields[0].value);
			System.assertEquals(cf1.items, result.customFields[0].items);
			System.assertEquals(cf1.required, result.customFields[0].required);
			System.assertEquals(cf1.show, result.customFields[0].show);
			System.assertNotEquals(null, result.customFields[1]);
			System.assertEquals(cf2.type, result.customFields[1].type);
			System.assertEquals(cf2.name, result.customFields[1].name);
			System.assertEquals(cf2.value, result.customFields[1].value);
			System.assertEquals(cf2.items, result.customFields[1].items);
			System.assertEquals(cf2.required, result.customFields[1].required);
			System.assertEquals(cf2.show, result.customFields[1].show);
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(n.remind, result.notifications.remind);
			System.assertEquals(n.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(n.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(n.expires, result.notifications.expires);
			System.assertEquals(n.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(n.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(t.emailSubject, result.emailSubject);
			System.assertEquals(t.emailMessage, result.emailMessage);
			System.assertEquals(2, Collection.size(result.documents));
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(d1.type, result.documents[0].type);
			System.assertEquals(d1.sequence, result.documents[0].sequence);
			System.assertEquals(d1.name, result.documents[0].name);
			System.assertEquals(d1.extension, result.documents[0].extension);
			System.assertEquals(d1.size, result.documents[0].size);
			System.assertEquals(d1.lastModified, result.documents[0].lastModified);
			System.assertEquals(d1.sourceId, result.documents[0].sourceId);
			System.assertEquals(d1.readOnly, result.documents[0].readOnly);
			System.assertEquals(d1.required, result.documents[0].required);
			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(d2.type, result.documents[1].type);
			System.assertEquals(d2.sequence, result.documents[1].sequence);
			System.assertEquals(d2.name, result.documents[1].name);
			System.assertEquals(d2.extension, result.documents[1].extension);
			System.assertEquals(d2.size, result.documents[1].size);
			System.assertEquals(d2.lastModified, result.documents[1].lastModified);
			System.assertEquals(d2.sourceId, result.documents[1].sourceId);
			System.assertEquals(d2.readOnly, result.documents[1].readOnly);
			System.assertEquals(d2.required, result.documents[1].required);
			System.assertEquals(2, Collection.size(result.recipients));
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals(r1.envelopeRecipientId, result.recipients[0].envelopeRecipientId);
			System.assertEquals(r1.type, result.recipients[0].type);
			System.assertEquals(r1.sequence, result.recipients[0].sequence);
			System.assertEquals(r1.routingOrder, result.recipients[0].routingOrder);
			System.assertNotEquals(null, result.recipients[0].role);
			System.assertEquals(r1.role.name, result.recipients[0].role.name);
			System.assertEquals(r1.name, result.recipients[0].name);
			System.assertEquals(r1.email, result.recipients[0].email);
			System.assertEquals(null, result.recipients[0].signingGroup);
			System.assertEquals(r1.phone, result.recipients[0].phone);
			System.assertEquals(null, result.recipients[0].authentication);
			System.assertEquals(r1.note, result.recipients[0].note);
			System.assertEquals(null, result.recipients[0].emailSettings);
			System.assertEquals(r1.hostName, result.recipients[0].hostName);
			System.assertEquals(r1.hostEmail, result.recipients[0].hostEmail);
			System.assertEquals(r1.signNow, result.recipients[0].signNow);
			System.assertEquals(r1.tabs, result.recipients[0].tabs);
			System.assertEquals(r1.source, result.recipients[0].source);
			System.assertEquals(r1.readOnly, result.recipients[0].readOnly);
			System.assertEquals(r1.required, result.recipients[0].required);
			System.assertNotEquals(null, result.recipients[1]);
			System.assertEquals(r2.envelopeRecipientId, result.recipients[1].envelopeRecipientId);
			System.assertEquals(r2.type, result.recipients[1].type);
			System.assertEquals(r2.sequence, result.recipients[1].sequence);
			System.assertEquals(r2.routingOrder, result.recipients[1].routingOrder);
			System.assertNotEquals(null, result.recipients[1].role);
			System.assertEquals(r2.role.name, result.recipients[1].role.name);
			System.assertEquals(r2.name, result.recipients[1].name);
			System.assertEquals(r2.email, result.recipients[1].email);
			System.assertEquals(null, result.recipients[1].signingGroup);
			System.assertEquals(r2.phone, result.recipients[1].phone);
			System.assertEquals(null, result.recipients[1].authentication);
			System.assertEquals(r2.note, result.recipients[1].note);
			System.assertEquals(null, result.recipients[1].emailSettings);
			System.assertEquals(r2.hostName, result.recipients[1].hostName);
			System.assertEquals(r2.hostEmail, result.recipients[1].hostEmail);
			System.assertEquals(r2.signNow, result.recipients[1].signNow);
			System.assertEquals(r2.tabs, result.recipients[1].tabs);
			System.assertEquals(r2.source, result.recipients[1].source);
			System.assertEquals(r2.readOnly, result.recipients[1].readOnly);
			System.assertEquals(r2.required, result.recipients[1].required);
			System.assertNotEquals(null, result.lastModified);
		}
	}

	@IsTest
	static void test_createTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Template t = new Template(
				UUID.randomUUID(),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);

			Test.startTest();
			try {
				TemplateAPI.getInstance().createTemplate(t, 1234L);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			TemplateAPI client = TemplateAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getTemplate(UUID.randomUUID());
				throw new AssertException('Expected getTemplate to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_getTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			final Template t = client.getTemplate(UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, t);
			System.assertNotEquals(null, t.id);
			System.assertNotEquals(null, t.name);
			System.assertNotEquals(null, t.lastModified);
			System.assertNotEquals(null, t.customFields);
			System.assertEquals(3, t.customFields.size());
			System.assertEquals('textField1', t.customFields[0].name);
			System.assertEquals('textValue1', t.customFields[0].value);
			System.assert(!t.customFields[0].required);
			System.assert(t.customFields[0].show);
			System.assertEquals('listField1', t.customFields[2].name);
			System.assertEquals('listField1Value2', t.customFields[2].value);
			System.assertEquals(new List<String> { 'listField1Value1', 'listField1Value2', 'listField1Value3' }, t.customFields[2].items);
			System.assert(t.customFields[2].required);
			System.assert(t.customFields[2].show);
			System.assertNotEquals(null, t.notifications);
			System.assert(t.notifications.remind);
			System.assertEquals(10, t.notifications.remindAfterDays);
			System.assertEquals(5, t.notifications.remindFrequencyDays);
			System.assert(t.notifications.expires);
			System.assertEquals(11, t.notifications.expireAfterDays);
			System.assertEquals(6, t.notifications.expireWarnDays);
			System.assertNotEquals(null, t.emailSubject);
			System.assertNotEquals(null, t.emailMessage);
			System.assertNotEquals(null, t.recipients);
			System.assertEquals(9, t.recipients.size());
			Integer sequence = 1;
			for (Recipient r : t.recipients) {
				System.assertNotEquals(null, r);
				System.assertEquals(sequence, r.sequence);
				System.assertEquals(sequence, r.routingOrder);
				if (sequence == 1) {
					System.assertEquals(Recipient.TYPE_INTERMEDIARY, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('INTERMEDIARY', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertNotEquals(null, r.authentication);
					System.assertEquals('1234', r.authentication.accessCode);
					System.assert(!r.authentication.idCheckRequired);
					System.assertEquals(null, r.authentication.smsPhoneNumbers);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 2) {
					System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, r.type);
					System.assertEquals('In-Person Signer', r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals('h1@unit.test', r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('IN_PERSON_SIGNER', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 3) {
					System.assertEquals(Recipient.TYPE_CARBON_COPY, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('CARBON_COPY', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertNotEquals(null, r.authentication);
					System.assertEquals(null, r.authentication.accessCode);
					System.assert(r.authentication.idCheckRequired);
					System.assertNotEquals(null, r.authentication.smsPhoneNumbers);
					System.assertEquals(1, r.authentication.smsPhoneNumbers.size());
					System.assertEquals('+1 415-555-5555', r.authentication.smsPhoneNumbers[0]);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 4) {
					System.assertEquals(Recipient.TYPE_CERTIFIED_DELIVERY, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('CERTIFIED_DELIVERY', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals('unit test', r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 5) {
					System.assertEquals(Recipient.TYPE_AGENT, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('AGENT', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertNotEquals(null, r.emailSettings);
					// "Unsupported" language Bulgarian
					System.assertEquals('bg', r.emailSettings.language);
					System.assertEquals('', r.emailSettings.languageLabel);
					System.assertEquals('bg subject', r.emailSettings.subject);
					System.assertEquals('bg message', r.emailSettings.message);
					System.assert(!r.readOnly);
				} else if (sequence == 6) {
					System.assertEquals(Recipient.TYPE_EDITOR, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('EDITOR', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 7) {
					System.assertEquals(Recipient.TYPE_SIGNER, r.type);
					System.assertEquals('SG1', r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('SIGNER', r.role.name);
					System.assertNotEquals(null, r.signingGroup);
					System.assertNotEquals(null, r.signingGroup.id);
					System.assertEquals('SG1', r.signingGroup.name);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertNotEquals(null, r.emailSettings);
					// "Supported" language French
					System.assertEquals('fr', r.emailSettings.language);
					System.assertEquals(Label.French, r.emailSettings.languageLabel);
					System.assertEquals('fr subject', r.emailSettings.subject);
					System.assertEquals('fr message', r.emailSettings.message);
					System.assert(r.readOnly);
					System.assert(r.required);
				} else if (sequence == 8) {
					System.assertEquals(Recipient.TYPE_SEAL, r.type);
				} else if (sequence == 9) {
					System.assertEquals(Recipient.TYPE_WITNESS, r.type);
				}
				sequence++;
			}
		}
	}

	@IsTest
	static void test_getTemplates_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Template> templates = client.getTemplates();
			Test.stopTest();

			System.assertNotEquals(null, templates);
			System.assertEquals(3, templates.size());

			System.assertNotEquals(null, templates[0].id);
			System.assertNotEquals(null, templates[0].name);
			System.assertNotEquals(null, templates[0].lastModified);
			System.assert(Collection.isEmpty(templates[0].customFields));

			System.assertNotEquals(null, templates[1].id);
			System.assertNotEquals(null, templates[1].name);
			System.assertNotEquals(null, templates[1].lastModified);
			System.assert(Collection.isEmpty(templates[1].customFields));

			System.assertNotEquals(null, templates[2].id);
			System.assertNotEquals(null, templates[2].name);
			System.assertNotEquals(null, templates[2].lastModified);
			System.assert(Collection.isEmpty(templates[2].customFields));
		}
	}

	@IsTest
	static void test_getTemplates_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			TemplateAPI client = TemplateAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getTemplates();
				throw new AssertException('Expected getTemplates to fail');
			} catch (APIException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Url result = TemplateAPI.getInstance().getTemplateEditUrl(
				UUID.randomUUID(),
				new Url('https://return.unit.test'));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.toExternalForm().contains('send=1'));
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				TemplateAPI.getInstance().getTemplateEditUrl(
					UUID.randomUUID(),
					new Url('https://return.unit.test'));
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	static Tab newMergeField(final String type) {
		return Tab.newMergeField(
			type,
			'Account.Name',
			false,
			false)
			.withAutoPlaceText(UUID.randomUUID().toString());
	}

	@IsTest
	static void test_APIRecipients_new() {
		List<Tab> tabs = new List<Tab> {
			newMergeField(Tab.TYPE_APPROVE),
			newMergeField(Tab.TYPE_CHECKBOX),
			newMergeField(Tab.TYPE_COMPANY),
			newMergeField(Tab.TYPE_DATE_SIGNED),
			newMergeField(Tab.TYPE_DATE),
			newMergeField(Tab.TYPE_DECLINE),
			newMergeField(Tab.TYPE_EMAIL_ADDRESS),
			newMergeField(Tab.TYPE_EMAIL),
			newMergeField(Tab.TYPE_ENVELOPE_ID),
			newMergeField(Tab.TYPE_FIRST_NAME),
			newMergeField(Tab.TYPE_FORMULA),
			newMergeField(Tab.TYPE_FULL_NAME),
			newMergeField(Tab.TYPE_INITIAL_HERE),
			newMergeField(Tab.TYPE_LAST_NAME),
			newMergeField(Tab.TYPE_LIST),
			newMergeField(Tab.TYPE_NOTARIZE),
			newMergeField(Tab.TYPE_NOTE),
			newMergeField(Tab.TYPE_NUMBER),
			newMergeField(Tab.TYPE_RADIO_GROUP),
			newMergeField(Tab.TYPE_SIGNER_ATTACHMENT),
			newMergeField(Tab.TYPE_SIGN_HERE),
			newMergeField(Tab.TYPE_SMART_SECTION),
			newMergeField(Tab.TYPE_SSN),
			newMergeField(Tab.TYPE_TEXT),
			newMergeField(Tab.TYPE_TITLE),
			newMergeField(Tab.TYPE_VIEW),
			newMergeField(Tab.TYPE_ZIP)
		};

		List<Recipient> recipients = new List<Recipient> {
			Recipient.fromSource('s1', 's1@unit.test', null, null, null)
				.withType(Recipient.TYPE_SEAL, false)
				.withSequence(1)
				.withTabs(tabs),
			Recipient.fromSource('w1', 'w1@unit.test', null, null, null)
				.withType(Recipient.TYPE_WITNESS, false)
				.withSequence(2),
			Recipient.fromSource('a1', 'a1@unit.test', null, null, null)
				.withType(Recipient.TYPE_AGENT, false)
				.withSequence(3),
			Recipient.fromSource('cc1', 'cc1@unit.test', null, null, null)
				.withType(Recipient.TYPE_CARBON_COPY, false)
				.withSequence(4),
			Recipient.fromSource('cd1', 'cd1@unit.test', null, null, null)
				.withType(Recipient.TYPE_CERTIFIED_DELIVERY, false)
				.withSequence(5),
			Recipient.fromSource('e1', 'e1@unit.test', null, null, null)
				.withType(Recipient.TYPE_EDITOR, false)
				.withSequence(6),
			Recipient.fromSource('i1', 'i1@unit.test', null, null, null)
				.withType(Recipient.TYPE_INTERMEDIARY, false)
				.withSequence(7),
			Recipient.fromSource('ips1', 'ips1@unit.test', null, null, null)
				.withType(Recipient.TYPE_IN_PERSON_SIGNER, false)
				.withSequence(8),
			Recipient.fromSource('sn1', 'sn1@unit.test', null, null, null)
				.withType(Recipient.TYPE_SIGNER, false)
				.withSequence(9)
				.withEmailSettings(new Recipient.EmailSettings(
				'zh_CN',
				'Chinese',
				's1',
				'm1'))
				.withAuthentication(new Recipient.Authentication(
				'1234',
				true,
				new List<String> { '5555555' })),
			Recipient.fromSource('es1', 'es1@unit.test', null, null, null)
				.withType(Recipient.TYPE_EMBEDDED_SIGNER, false)
				.withSequence(10)
		};
		TemplateAPI.APIRecipients apiRecipients = new TemplateAPI.APIRecipients(
			recipients,
			'1');

		Test.startTest();
		List<Recipient> result = apiRecipients.toRecipients(null);
		Test.stopTest();

		System.assertEquals(10, Collection.size(result));
		System.assertNotEquals(null, result[0]);
		System.assertEquals(Recipient.TYPE_SEAL, result[0].type);
		System.assertEquals(27, Collection.size(result[0].tabs));
		System.assertNotEquals(null, result[1]);
		System.assertEquals(Recipient.TYPE_WITNESS, result[1].type);
		System.assertEquals(0, Collection.size(result[1].tabs));
	}

	@IsTest
	static void test_addOrUpdateTemplateDocuments_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.addOrUpdateTemplateDocuments(
					UUID.randomUUID(),
					new List<TemplateAPI.APIDocument>(),
					new Map<String, Document>(),
					1000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addOrUpdateTemplateDocuments_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Document d1 = new Document(
				UserInfo.getUserId(),
				Document.TYPE_FILE,
				1,
				UUID.randomUUID().toString(),
				'pdf',
				1234,
				Datetime.now().addDays(-2),
				UserInfo.getUserId(),
				true,
				false,
				null);
			TemplateAPI.APIDocument ad1 = new TemplateAPI.APIDocument(d1, Blob.valueOf('ad1'));
			Document d2 = new Document(
				UserInfo.getOrganizationId(),
				Document.TYPE_FILE,
				2,
				UUID.randomUUID().toString(),
				'html',
				5678,
				Datetime.now().addDays(-1),
				UserInfo.getOrganizationId(),
				false,
				true,
				null);
			TemplateAPI.APIDocument ad2 = new TemplateAPI.APIDocument(d2, Blob.valueOf('ad2'));
			List<TemplateAPI.APIDocument> documents = new List<TemplateAPI.APIDocument> {
				ad1, ad2
			};
			Map<String, Document> documentMap = new Map<String, Document> {
				ad1.documentId => d1,
				ad2.documentId => d2
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Document> result = client.addOrUpdateTemplateDocuments(
				UUID.randomUUID(),
				documents,
				documentMap,
				1000);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));

			Document d = result[0];
			System.assertNotEquals(null, d);
			System.assertEquals(APIError.none, d.error);
			Document expected = d1;
			System.assertEquals(expected.id, d.id);
			System.assertEquals(expected.type, d.type);
			System.assertEquals(expected.sequence, d.sequence);
			System.assertEquals(expected.name, d.name);
			System.assertEquals(expected.extension, d.extension);
			System.assertEquals(expected.size, d.size);
			System.assertEquals(expected.lastModified, d.lastModified);
			System.assertEquals(expected.sourceId, d.sourceId);
			System.assertEquals(expected.readOnly, d.readOnly);
			System.assertEquals(expected.required, d.required);

			d = result[1];
			System.assertNotEquals(null, d);
			System.assertEquals(APIError.none, d.error);
			expected = d2;
			System.assertEquals(expected.id, d.id);
			System.assertEquals(expected.type, d.type);
			System.assertEquals(expected.sequence, d.sequence);
			System.assertEquals(expected.name, d.name);
			System.assertEquals(expected.extension, d.extension);
			System.assertEquals(expected.size, d.size);
			System.assertEquals(expected.lastModified, d.lastModified);
			System.assertEquals(expected.sourceId, d.sourceId);
			System.assertEquals(expected.readOnly, d.readOnly);
			System.assertEquals(expected.required, d.required);
		}
	}

	class TemplateDocumentPartialSuccessMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			TemplateAPI.APIDocument du1 = new TemplateAPI.APIDocument(null, null);
			du1.errorDetails = new ESignatureAPI.ErrorDetails();
			du1.errorDetails.errorCode = 'SUCCESS';
			du1.errorDetails.message = '';
			du1.documentId = '1';
			TemplateAPI.APIDocument du2 = new TemplateAPI.APIDocument(null, null);
			du2.errorDetails = new ESignatureAPI.ErrorDetails();
			du2.errorDetails.errorCode = 'UNIT_TEST';
			du2.errorDetails.message = 'Unit test error.';
			du2.documentId = '3';
			TemplateAPI.APIDocument du3 = new TemplateAPI.APIDocument(null, null);
			du3.errorDetails = new ESignatureAPI.ErrorDetails();
			du3.errorDetails.errorCode = 'SUCCESS';
			du3.errorDetails.message = '';
			du3.documentId = '3';
			TemplateAPI.APIDocumentsUpdate result = new TemplateAPI.APIDocumentsUpdate();
			result.templateId = UUID.randomUUID().toString();
			result.templateDocuments = new List<TemplateAPI.APIDocument> { du1, du2, du3 };
			response.setBody(JSON.serialize(result));
			return response;
		}
	}

	@IsTest
	static void test_addOrUpdateTemplateDocuments_partial_success() {
		Test.setMock(HttpCalloutMock.class, new TemplateDocumentPartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Document> result = client.addOrUpdateTemplateDocuments(
				UUID.randomUUID(),
				new List<TemplateAPI.APIDocument>(),
				new Map<String, Document>(),
				1000);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('Unit test error.', result[1].error.description);
			System.assert(result[1].error instanceof ESignatureAPI.Error);
			System.assertEquals('UNIT_TEST', ((ESignatureAPI.Error)result[1].error).docuSignCode);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
		}
	}

	@IsTest
	static void test_removeTemplateDocuments_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.removeTemplateDocuments(
					UUID.randomUUID(),
					new List<TemplateAPI.APIDocument>(),
					new Map<String, Document>(),
					1000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeTemplateDocuments_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Document d1 = new Document(
				UserInfo.getUserId(),
				Document.TYPE_FILE,
				1,
				UUID.randomUUID().toString(),
				'pdf',
				1234,
				Datetime.now().addDays(-2),
				UserInfo.getUserId(),
				true,
				false,
				null);
			TemplateAPI.APIDocument ad1 = new TemplateAPI.APIDocument(d1, null);
			Document d2 = new Document(
				UserInfo.getOrganizationId(),
				Document.TYPE_FILE,
				2,
				UUID.randomUUID().toString(),
				'docx',
				5678,
				Datetime.now().addDays(-1),
				UserInfo.getOrganizationId(),
				false,
				true,
				null);
			TemplateAPI.APIDocument ad2 = new TemplateAPI.APIDocument(d2, null);
			List<TemplateAPI.APIDocument> documents = new List<TemplateAPI.APIDocument> {
				ad1, ad2
			};
			Map<String, Document> documentMap = new Map<String, Document> {
				ad1.documentId => d1,
				ad2.documentId => d2
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Document> result = client.addOrUpdateTemplateDocuments(
				UUID.randomUUID(),
				documents,
				documentMap,
				1000);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIError.none, result[1].error);
		}
	}

	@IsTest
	static void test_removeTemplateDocuments_partial_success() {
		Test.setMock(HttpCalloutMock.class, new TemplateDocumentPartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Document> result = client.removeTemplateDocuments(
				UUID.randomUUID(),
				new List<TemplateAPI.APIDocument>(),
				new Map<String, Document>(),
				1000);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('Unit test error.', result[1].error.description);
			System.assert(result[1].error instanceof ESignatureAPI.Error);
			System.assertEquals('UNIT_TEST', ((ESignatureAPI.Error)result[1].error).docuSignCode);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
		}
	}

	@IsTest
	static void test_addOrUpdateTemplateRecipients_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.addOrUpdateTemplateRecipients(
					UUID.randomUUID(),
					new TemplateAPI.APIRecipients(null),
					new Map<String, Recipient>(),
					1000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addOrUpdateTemplateRecipients_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(1)
				.withType(Recipient.TYPE_AGENT, false);
			Recipient r2 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(2)
				.withType(Recipient.TYPE_CARBON_COPY, false);
			Recipient r3 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(3)
				.withType(Recipient.TYPE_CERTIFIED_DELIVERY, false);
			Recipient r4 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(4)
				.withType(Recipient.TYPE_EDITOR, false);
			Recipient r5 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(5)
				.withType(Recipient.TYPE_IN_PERSON_SIGNER, false);
			Recipient r6 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(6)
				.withType(Recipient.TYPE_INTERMEDIARY, false);
			Recipient r7 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(7)
				.withType(Recipient.TYPE_SIGNER, false);
			Recipient r8 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(8)
				.withType(Recipient.TYPE_SEAL, false);
			Recipient r9 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(9)
				.withType(Recipient.TYPE_WITNESS, false);
			TemplateAPI.APIRecipients recipients = new TemplateAPI.APIRecipients(
				new List<TemplateAPI.APIRecipientWrapper> {
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_AGENT,
						new TemplateAPI.APIRecipient(
							r1,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_CARBON_COPY,
						new TemplateAPI.APIRecipient(
							r2,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_CERTIFIED_DELIVERY,
						new TemplateAPI.APIRecipient(
							r3,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_EDITOR,
						new TemplateAPI.APIRecipient(
							r4,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_IN_PERSON_SIGNER,
						new TemplateAPI.APIRecipient(
							r5,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_INTERMEDIARY,
						new TemplateAPI.APIRecipient(
							r6,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_SIGNER,
						new TemplateAPI.APIRecipient(
							r7,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_SEAL,
						new TemplateAPI.APIRecipient(
							r8,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_WITNESS,
						new TemplateAPI.APIRecipient(
							r9,
							'1'))
				});
			Map<String, Recipient> recipientMap = new Map<String, Recipient> {
				r1.getEnvelopeRecipientId() => r1,
				r2.getEnvelopeRecipientId() => r2,
				r3.getEnvelopeRecipientId() => r3,
				r4.getEnvelopeRecipientId() => r4,
				r5.getEnvelopeRecipientId() => r5,
				r6.getEnvelopeRecipientId() => r6,
				r7.getEnvelopeRecipientId() => r7,
				r8.getEnvelopeRecipientId() => r8,
				r9.getEnvelopeRecipientId() => r9
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Recipient> result = client.addOrUpdateTemplateRecipients(
				UUID.randomUUID(),
				recipients,
				recipientMap,
				1000);
			Test.stopTest();

			System.assertEquals(9, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIError.none, result[1].error);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
			System.assertNotEquals(null, result[3]);
			System.assertEquals(APIError.none, result[3].error);
			System.assertNotEquals(null, result[4]);
			System.assertEquals(APIError.none, result[4].error);
			System.assertNotEquals(null, result[5]);
			System.assertEquals(APIError.none, result[5].error);
			System.assertNotEquals(null, result[6]);
			System.assertEquals(APIError.none, result[6].error);
			System.assertNotEquals(null, result[7]);
			System.assertEquals(APIError.none, result[7].error);
			System.assertNotEquals(null, result[8]);
			System.assertEquals(APIError.none, result[8].error);
		}
	}

	class TemplateRecipientUpdatePartialSuccessMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			TemplateAPI.APIRecipientUpdate ru1 = new TemplateAPI.APIRecipientUpdate();
			ru1.errorDetails = new ESignatureAPI.ErrorDetails();
			ru1.errorDetails.errorCode = 'SUCCESS';
			ru1.errorDetails.message = '';
			ru1.recipientId = '1';
			TemplateAPI.APIRecipientUpdate ru2 = new TemplateAPI.APIRecipientUpdate();
			ru2.errorDetails = new ESignatureAPI.ErrorDetails();
			ru2.errorDetails.errorCode = 'UNIT_TEST';
			ru2.errorDetails.message = 'Unit test error.';
			ru2.recipientId = '2';
			TemplateAPI.APIRecipientUpdate ru3 = new TemplateAPI.APIRecipientUpdate();
			ru3.errorDetails = new ESignatureAPI.ErrorDetails();
			ru3.errorDetails.errorCode = 'SUCCESS';
			ru3.errorDetails.message = '';
			ru3.recipientId = '3';
			TemplateAPI.APIRecipientUpdates result = new TemplateAPI.APIRecipientUpdates();
			result.recipientUpdateResults = new List<TemplateAPI.APIRecipientUpdate> { ru1, ru2, ru3 };
			response.setBody(JSON.serialize(result));
			return response;
		}
	}

	@IsTest
	static void test_addOrUpdateTemplateRecipients_partial_success() {
		Test.setMock(HttpCalloutMock.class, new TemplateRecipientUpdatePartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Recipient> result = client.addOrUpdateTemplateRecipients(
				UUID.randomUUID(),
				new TemplateAPI.APIRecipients(null),
				new Map<String, Recipient>(),
				1000);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('Unit test error.', result[1].error.description);
			System.assert(result[1].error instanceof ESignatureAPI.Error);
			System.assertEquals('UNIT_TEST', ((ESignatureAPI.Error)result[1].error).docuSignCode);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
		}
	}

	@IsTest
	static void test_removeTemplateRecipients_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.removeTemplateRecipients(
					UUID.randomUUID(),
					new TemplateAPI.APIRecipients(null),
					new Map<String, Recipient>(),
					1000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeTemplateRecipients_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_AGENT, false);
			Recipient r2 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_CARBON_COPY, false);
			Recipient r3 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_CERTIFIED_DELIVERY, false);
			Recipient r4 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_EDITOR, false);
			Recipient r5 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_IN_PERSON_SIGNER, false);
			Recipient r6 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_INTERMEDIARY, false);
			Recipient r7 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_SIGNER, false);
			Recipient r8 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_SEAL, false);
			Recipient r9 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withType(Recipient.TYPE_WITNESS, false);
			TemplateAPI.APIRecipients recipients = new TemplateAPI.APIRecipients(
				new List<TemplateAPI.APIRecipientWrapper> {
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_AGENT,
						new TemplateAPI.APIRecipient(
							r1,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_CARBON_COPY,
						new TemplateAPI.APIRecipient(
							r2,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_CERTIFIED_DELIVERY,
						new TemplateAPI.APIRecipient(
							r3,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_EDITOR,
						new TemplateAPI.APIRecipient(
							r4,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_IN_PERSON_SIGNER,
						new TemplateAPI.APIRecipient(
							r5,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_INTERMEDIARY,
						new TemplateAPI.APIRecipient(
							r6,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_SIGNER,
						new TemplateAPI.APIRecipient(
							r7,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_SEAL,
						new TemplateAPI.APIRecipient(
							r8,
							'1')),
					new TemplateAPI.APIRecipientWrapper(
						Recipient.TYPE_WITNESS,
						new TemplateAPI.APIRecipient(
							r9,
							'1'))
				});
			Map<String, Recipient> recipientMap = new Map<String, Recipient> {
				r1.getEnvelopeRecipientId() => r1,
				r2.getEnvelopeRecipientId() => r2,
				r3.getEnvelopeRecipientId() => r3,
				r4.getEnvelopeRecipientId() => r4,
				r5.getEnvelopeRecipientId() => r5,
				r6.getEnvelopeRecipientId() => r6,
				r7.getEnvelopeRecipientId() => r7,
				r8.getEnvelopeRecipientId() => r8,
				r9.getEnvelopeRecipientId() => r9
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Recipient> result = client.removeTemplateRecipients(
				UUID.randomUUID(),
				recipients,
				recipientMap,
				1000);
			Test.stopTest();

			System.assertEquals(9, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIError.none, result[1].error);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
			System.assertNotEquals(null, result[3]);
			System.assertEquals(APIError.none, result[3].error);
			System.assertNotEquals(null, result[4]);
			System.assertEquals(APIError.none, result[4].error);
			System.assertNotEquals(null, result[5]);
			System.assertEquals(APIError.none, result[5].error);
			System.assertNotEquals(null, result[6]);
			System.assertEquals(APIError.none, result[6].error);
			System.assertNotEquals(null, result[7]);
			System.assertEquals(APIError.none, result[7].error);
			System.assertNotEquals(null, result[8]);
			System.assertEquals(APIError.none, result[8].error);
		}
	}

	class TemplateRecipientDeletePartialSuccessMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			TemplateAPI.APIRecipient r1 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_AGENT, false),
				'1');
			TemplateAPI.APIRecipient r2 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_CARBON_COPY, false),
				'1');
			TemplateAPI.APIRecipient r3 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_CERTIFIED_DELIVERY, false),
				'1');
			TemplateAPI.APIRecipient r4 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_EDITOR, false),
				'1');
			r4.errorDetails = new ESignatureAPI.ErrorDetails();
			r4.errorDetails.errorCode = 'UNIT_TEST_1';
			r4.errorDetails.message = 'Unit test error 1.';
			TemplateAPI.APIRecipient r5 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_IN_PERSON_SIGNER, false),
				'1');
			TemplateAPI.APIRecipient r6 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_INTERMEDIARY, false),
				'1');
			TemplateAPI.APIRecipient r7 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_SIGNER, false),
				'1');
			TemplateAPI.APIRecipient r8 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_SEAL, false),
				'1');
			r8.errorDetails = new ESignatureAPI.ErrorDetails();
			r8.errorDetails.errorCode = 'UNIT_TEST_2';
			r8.errorDetails.message = 'Unit test error 2.';
			TemplateAPI.APIRecipient r9 = new TemplateAPI.APIRecipient(
				Recipient.fromSource(
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					null,
					null,
					null)
					.withType(Recipient.TYPE_WITNESS, false),
				'1');
			TemplateAPI.APIRecipients result = new TemplateAPI.APIRecipients(null);
			result.agents = new List<TemplateAPI.APIRecipient> { r1 };
			result.carbonCopies = new List<TemplateAPI.APIRecipient> { r2 };
			result.certifiedDeliveries = new List<TemplateAPI.APIRecipient> { r3 };
			result.editors = new List<TemplateAPI.APIRecipient> { r4 };
			result.inPersonSigners = new List<TemplateAPI.APIRecipient> { r5 };
			result.intermediaries = new List<TemplateAPI.APIRecipient> { r6 };
			result.signers = new List<TemplateAPI.APIRecipient> { r7 };
			result.seals = new List<TemplateAPI.APIRecipient> { r8 };
			result.witnesses = new List<TemplateAPI.APIRecipient> { r9 };
			response.setBody(JSON.serialize(result));
			return response;
		}
	}

	@IsTest
	static void test_removeTemplateRecipients_partial_success() {
		Test.setMock(HttpCalloutMock.class, new TemplateRecipientDeletePartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Recipient> result = client.removeTemplateRecipients(
				UUID.randomUUID(),
				new TemplateAPI.APIRecipients(null),
				new Map<String, Recipient>(),
				1000);
			Test.stopTest();

			System.assertEquals(9, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIError.none, result[1].error);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
			System.assertNotEquals(null, result[3]);
			System.assertNotEquals(null, result[3].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[3].error.code);
			System.assertEquals('Unit test error 1.', result[3].error.description);
			System.assert(result[3].error instanceof ESignatureAPI.Error);
			System.assertEquals('UNIT_TEST_1', ((ESignatureAPI.Error)result[3].error).docuSignCode);
			System.assertNotEquals(null, result[4]);
			System.assertEquals(APIError.none, result[4].error);
			System.assertNotEquals(null, result[5]);
			System.assertEquals(APIError.none, result[5].error);
			System.assertNotEquals(null, result[6]);
			System.assertEquals(APIError.none, result[6].error);
			System.assertNotEquals(null, result[7]);
			System.assertNotEquals(null, result[7].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[7].error.code);
			System.assertEquals('Unit test error 2.', result[7].error.description);
			System.assert(result[7].error instanceof ESignatureAPI.Error);
			System.assertEquals('UNIT_TEST_2', ((ESignatureAPI.Error)result[7].error).docuSignCode);
			System.assertNotEquals(null, result[8]);
			System.assertEquals(APIError.none, result[8].error);
		}
	}

	@IsTest
	static void test_mapTemplateDocuments() {
		Document d1 = new Document(
			null,
			Document.TYPE_FILE,
			1,
			UUID.randomUUID().toString(),
			'pdf',
			1234,
			Datetime.now().addDays(-2),
			null,
			true,
			false,
			null);
		Document d2 = new Document(
			null,
			Document.TYPE_FILE,
			2,
			UUID.randomUUID().toString(),
			'docx',
			5678,
			Datetime.now().addDays(-1),
			null,
			false,
			true,
			null);
		List<TemplateAPI.APIDocument> documents = new List<TemplateAPI.APIDocument> {
			new TemplateAPI.APIDocument(d1, null),
			new TemplateAPI.APIDocument(d2, null)
		};

		Test.startTest();
		Map<String, TemplateAPI.APIDocument> result = TemplateAPI.mapTemplateDocuments(documents);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<String> { '1', '2' }, result.keySet());
		System.assertNotEquals(null, result.get('1'));
		System.assertNotEquals(null, result.get('2'));
	}

	@IsTest
	static void test_updateTemplateDocuments_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			// 1 add, 1 delete, 1 update
			Document d1 = new Document( // add
				UserInfo.getUserId(),
				Document.TYPE_FILE,
				1,
				UUID.randomUUID().toString(),
				'pdf',
				1234,
				Datetime.now().addDays(-2),
				UserInfo.getUserId(),
				true,
				false,
				null);
			Document d2 = new Document( // update
				UserInfo.getOrganizationId(),
				Document.TYPE_FILE,
				2,
				UUID.randomUUID().toString(),
				'docx',
				5678,
				Datetime.now().addDays(-1),
				UserInfo.getOrganizationId(),
				false,
				true,
				null);
			Document d3 = new Document( // remove
				UserInfo.getProfileId(),
				Document.TYPE_FILE,
				3,
				UUID.randomUUID().toString(),
				'docx',
				9012,
				Datetime.now(),
				UserInfo.getProfileId(),
				false,
				true,
				null);
			List<Document> newDocuments = new List<Document> { d1, d2 };
			Map<String, Blob> documentContent = new Map<String, Blob> {
				'1' => Blob.valueOf('d1'),
				'2' => Blob.valueOf('d2')
			};
			Map<String, TemplateAPI.APIDocument> oldDocuments = new Map<String, TemplateAPI.APIDocument> {
				'2' => new TemplateAPI.APIDocument(d2, Blob.valueOf('d2')),
				'3' => new TemplateAPI.APIDocument(d3, Blob.valueOf('d3'))
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Document> result = client.updateTemplateDocuments(
				UUID.randomUUID(),
				newDocuments,
				documentContent,
				oldDocuments,
				1000);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIError.none, result[1].error);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
		}
	}

	@IsTest
	static void test_updateTemplateDocuments_failure() {
		Test.setMock(HttpCalloutMock.class, new TemplateDocumentPartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Document d1 = new Document(
				null,
				Document.TYPE_FILE,
				1,
				UUID.randomUUID().toString(),
				'pdf',
				1234,
				Datetime.now(),
				null);
			Document d2 = new Document(
				null,
				Document.TYPE_FILE,
				2,
				UUID.randomUUID().toString(),
				'pdf',
				1234,
				Datetime.now(),
				null);
			List<Document> newDocuments = new List<Document> { d1 };
			Map<String, Blob> documentContent = new Map<String, Blob>();
			Map<String, TemplateAPI.APIDocument> oldDocuments = new Map<String, TemplateAPI.APIDocument> {
				'2' => new TemplateAPI.APIDocument(d2, null)
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.updateTemplateDocuments(
					UUID.randomUUID(),
					newDocuments,
					documentContent,
					oldDocuments,
					1000);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assert(ex.getMessage().contains(Label.TemplateDocumentError));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_mapTemplateRecipients() {
		TemplateAPI.APIRecipient r1 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(1)
				.withType(Recipient.TYPE_AGENT, false),
			'1');
		TemplateAPI.APIRecipient r2 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(2)
				.withType(Recipient.TYPE_CARBON_COPY, false),
			'1');
		TemplateAPI.APIRecipient r3 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(3)
				.withType(Recipient.TYPE_CERTIFIED_DELIVERY, false),
			'1');
		TemplateAPI.APIRecipient r4 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(4)
				.withType(Recipient.TYPE_EDITOR, false),
			'1');
		r4.errorDetails = new ESignatureAPI.ErrorDetails();
		r4.errorDetails.errorCode = 'UNIT_TEST_1';
		r4.errorDetails.message = 'Unit test error 1.';
		TemplateAPI.APIRecipient r5 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(5)
				.withType(Recipient.TYPE_IN_PERSON_SIGNER, false),
			'1');
		TemplateAPI.APIRecipient r6 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(6)
				.withType(Recipient.TYPE_INTERMEDIARY, false),
			'1');
		TemplateAPI.APIRecipient r7 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(7)
				.withType(Recipient.TYPE_SIGNER, false),
			'1');
		TemplateAPI.APIRecipient r8 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(8)
				.withType(Recipient.TYPE_SEAL, false),
			'1');
		r8.errorDetails = new ESignatureAPI.ErrorDetails();
		r8.errorDetails.errorCode = 'UNIT_TEST_2';
		r8.errorDetails.message = 'Unit test error 2.';
		TemplateAPI.APIRecipient r9 = new TemplateAPI.APIRecipient(
			Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(9)
				.withType(Recipient.TYPE_WITNESS, false),
			'1');
		TemplateAPI.APIRecipients recipients = new TemplateAPI.APIRecipients(null);
		recipients.agents = new List<TemplateAPI.APIRecipient> { r1 };
		recipients.carbonCopies = new List<TemplateAPI.APIRecipient> { r2 };
		recipients.certifiedDeliveries = new List<TemplateAPI.APIRecipient> { r3 };
		recipients.editors = new List<TemplateAPI.APIRecipient> { r4 };
		recipients.inPersonSigners = new List<TemplateAPI.APIRecipient> { r5 };
		recipients.intermediaries = new List<TemplateAPI.APIRecipient> { r6 };
		recipients.signers = new List<TemplateAPI.APIRecipient> { r7 };
		recipients.seals = new List<TemplateAPI.APIRecipient> { r8 };
		recipients.witnesses = new List<TemplateAPI.APIRecipient> { r9 };

		Test.startTest();
		Map<String, TemplateAPI.APIRecipientWrapper> result = TemplateAPI.mapTemplateRecipients(recipients);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(9, result.size());
		TemplateAPI.APIRecipientWrapper r = result.get(r1.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_AGENT, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r2.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_CARBON_COPY, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r3.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_CERTIFIED_DELIVERY, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r4.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_EDITOR, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r5.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r6.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_INTERMEDIARY, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r7.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_SIGNER, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r8.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_SEAL, r.type);
		System.assertNotEquals(null, r.recipient);
		r = result.get(r9.recipientId);
		System.assertNotEquals(null, r);
		System.assertEquals(Recipient.TYPE_WITNESS, r.type);
		System.assertNotEquals(null, r.recipient);
	}

	@IsTest
	static void test_updateTemplateRecipients_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			// 1 add, 1 delete, 1 update
			Recipient r1 = Recipient.fromSource( // add
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(1);
			Recipient r2 = Recipient.fromSource( // update
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(2);
			Recipient r3 = Recipient.fromSource( // remove
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(3);
			List<Recipient> newRecipients = new List<Recipient> { r1, r2 };
			Map<String, TemplateAPI.APIRecipientWrapper> oldRecipients = new Map<String, TemplateAPI.APIRecipientWrapper> {
				'2' => new TemplateAPI.APIRecipientWrapper(
					Recipient.TYPE_SIGNER,
					new TemplateAPI.APIRecipient(
						r2,
						'1')),
				'3' => new TemplateAPI.APIRecipientWrapper(
					Recipient.TYPE_SIGNER,
					new TemplateAPI.APIRecipient(
						r3,
						'1'))
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			List<Recipient> result = client.updateTemplateRecipients(
				UUID.randomUUID(),
				newRecipients,
				oldRecipients,
				1000);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(APIError.none, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(APIError.none, result[1].error);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(APIError.none, result[2].error);
		}
	}

	@IsTest
	static void test_updateTemplateRecipients_failure() {
		Test.setMock(HttpCalloutMock.class, new TemplateRecipientDeletePartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(1);
			Recipient r2 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(2);
			Recipient r3 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				null,
				null)
				.withSequence(3);
			List<Recipient> newRecipients = new List<Recipient>();
			Map<String, TemplateAPI.APIRecipientWrapper> oldRecipients = new Map<String, TemplateAPI.APIRecipientWrapper> {
				'1' => new TemplateAPI.APIRecipientWrapper(
					Recipient.TYPE_SIGNER,
					new TemplateAPI.APIRecipient(
						r1,
						'1')),
				'2' => new TemplateAPI.APIRecipientWrapper(
					Recipient.TYPE_SIGNER,
					new TemplateAPI.APIRecipient(
						r2,
						'1')),
				'3' => new TemplateAPI.APIRecipientWrapper(
					Recipient.TYPE_SIGNER,
					new TemplateAPI.APIRecipient(
						r3,
						'1'))
			};
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.updateTemplateRecipients(
					UUID.randomUUID(),
					newRecipients,
					oldRecipients,
					1000);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assert(ex.getMessage().contains(Label.TemplateRecipientError));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			CustomField cf1 = CustomField.newListField('lf', 'v1', new List<String> { 'v1', 'v2', 'v3' }, false, true);
			CustomField cf2 = CustomField.newTextField('tf', 'v1', true, true);
			Notifications n = new Notifications(true, 10, 2, true, 20, 18);
			Document d1 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(1);
			Document d2 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(2);
			Contact c1 = TestUtils.createContact();
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				String.valueOf(TestUtils.randomInteger(1000000)),
				UUID.randomUUID().toString(),
				new Entity(c1.Id))
				.withSequence(1)
				.withRoutingOrder(1);
			Recipient r2 = Recipient.newInPersonSigner(
				2,
				new Recipient.Role(UUID.randomUUID().toString()),
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				UUID.randomUUID().toString(),
				true)
				.withSequence(2);
			Datetime lm = Datetime.now().addDays(-1);
			Template t = new Template(
				UUID.randomUUID(),
				UUID.randomUUID().toString(),
				new List<CustomField> { cf1, cf2 },
				n,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Document> { d1, d2 },
				new List<Recipient> { r1, r2 },
				lm);

			//Delete and add recipient/document

			Document d3 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(2);
			Document d4 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(3);

			Recipient r3 = Recipient.newInPersonSigner(
				2,
				new Recipient.Role(UUID.randomUUID().toString()),
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				UUID.randomUUID().toString(),
				true)
				.withSequence(2);

			Contact c2 = TestUtils.createContact();
			Recipient r4 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				String.valueOf(TestUtils.randomInteger(1000000)),
				UUID.randomUUID().toString(),
				new Entity(c2.Id))
				.withSequence(3)
				.withRoutingOrder(3);

			Template t2 = new Template(
				UUID.randomUUID(),
				UUID.randomUUID().toString(),
				new List<CustomField> { cf1, cf2 },
				n,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Document> { d1, d3, d4 },
				new List<Recipient> { r1, r3, r4 },
				lm);

			Test.startTest();

			//create template api call
			Template result = TemplateAPI.getInstance().createTemplate(t, 1234L);
			//update template api call
			Template result2 = TemplateAPI.getInstance().updateTemplate(t2);

			Test.stopTest();

			//validate create result
			System.assertNotEquals(null, result);
			System.assertEquals(t.id, result.id);
			System.assertEquals(t2.id, result2.id);
			System.assertEquals(t.name, result.name);
			System.assertEquals(t2.name, result2.name);
			System.assertEquals(2, Collection.size(result.customFields));
			System.assertNotEquals(null, result.customFields[0]);
			System.assertEquals(cf1.type, result.customFields[0].type);
			System.assertEquals(cf1.name, result.customFields[0].name);
			System.assertEquals(cf1.value, result.customFields[0].value);
			System.assertEquals(cf1.items, result.customFields[0].items);
			System.assertEquals(cf1.required, result.customFields[0].required);
			System.assertEquals(cf1.show, result.customFields[0].show);
			System.assertNotEquals(null, result.customFields[1]);
			System.assertEquals(cf2.type, result.customFields[1].type);
			System.assertEquals(cf2.name, result.customFields[1].name);
			System.assertEquals(cf2.value, result.customFields[1].value);
			System.assertEquals(cf2.items, result.customFields[1].items);
			System.assertEquals(cf2.required, result.customFields[1].required);
			System.assertEquals(cf2.show, result.customFields[1].show);
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(n.remind, result.notifications.remind);
			System.assertEquals(n.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(n.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(n.expires, result.notifications.expires);
			System.assertEquals(n.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(n.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(t.emailSubject, result.emailSubject);
			System.assertEquals(t.emailMessage, result.emailMessage);
			System.assertEquals(2, Collection.size(result.documents));
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(d1.type, result.documents[0].type);
			System.assertEquals(d1.sequence, result.documents[0].sequence);
			System.assertEquals(d1.name, result.documents[0].name);
			System.assertEquals(d1.extension, result.documents[0].extension);
			System.assertEquals(d1.size, result.documents[0].size);
			System.assertEquals(d1.lastModified, result.documents[0].lastModified);
			System.assertEquals(d1.sourceId, result.documents[0].sourceId);
			System.assertEquals(d1.readOnly, result.documents[0].readOnly);
			System.assertEquals(d1.required, result.documents[0].required);
			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(d2.type, result.documents[1].type);
			System.assertEquals(d2.sequence, result.documents[1].sequence);
			System.assertEquals(d2.name, result.documents[1].name);
			System.assertEquals(d2.extension, result.documents[1].extension);
			System.assertEquals(d2.size, result.documents[1].size);
			System.assertEquals(d2.lastModified, result.documents[1].lastModified);
			System.assertEquals(d2.sourceId, result.documents[1].sourceId);
			System.assertEquals(d2.readOnly, result.documents[1].readOnly);
			System.assertEquals(d2.required, result.documents[1].required);
			System.assertEquals(2, Collection.size(result.recipients));
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals(r1.envelopeRecipientId, result.recipients[0].envelopeRecipientId);
			System.assertEquals(r1.type, result.recipients[0].type);
			System.assertEquals(r1.sequence, result.recipients[0].sequence);
			System.assertEquals(r1.routingOrder, result.recipients[0].routingOrder);
			System.assertNotEquals(null, result.recipients[0].role);
			System.assertEquals(r1.role.name, result.recipients[0].role.name);
			System.assertEquals(r1.name, result.recipients[0].name);
			System.assertEquals(r1.email, result.recipients[0].email);
			System.assertEquals(null, result.recipients[0].signingGroup);
			System.assertEquals(r1.phone, result.recipients[0].phone);
			System.assertEquals(null, result.recipients[0].authentication);
			System.assertEquals(r1.note, result.recipients[0].note);
			System.assertEquals(null, result.recipients[0].emailSettings);
			System.assertEquals(r1.hostName, result.recipients[0].hostName);
			System.assertEquals(r1.hostEmail, result.recipients[0].hostEmail);
			System.assertEquals(r1.signNow, result.recipients[0].signNow);
			System.assertEquals(r1.tabs, result.recipients[0].tabs);
			System.assertEquals(r1.source, result.recipients[0].source);
			System.assertEquals(r1.readOnly, result.recipients[0].readOnly);
			System.assertEquals(r1.required, result.recipients[0].required);
			System.assertNotEquals(null, result.recipients[1]);
			System.assertEquals(r2.envelopeRecipientId, result.recipients[1].envelopeRecipientId);
			System.assertEquals(r2.type, result.recipients[1].type);
			System.assertEquals(r2.sequence, result.recipients[1].sequence);
			System.assertEquals(r2.routingOrder, result.recipients[1].routingOrder);
			System.assertNotEquals(null, result.recipients[1].role);
			System.assertEquals(r2.role.name, result.recipients[1].role.name);
			System.assertEquals(r2.name, result.recipients[1].name);
			System.assertEquals(r2.email, result.recipients[1].email);
			System.assertEquals(null, result.recipients[1].signingGroup);
			System.assertEquals(r2.phone, result.recipients[1].phone);
			System.assertEquals(null, result.recipients[1].authentication);
			System.assertEquals(r2.note, result.recipients[1].note);
			System.assertEquals(null, result.recipients[1].emailSettings);
			System.assertEquals(r2.hostName, result.recipients[1].hostName);
			System.assertEquals(r2.hostEmail, result.recipients[1].hostEmail);
			System.assertEquals(r2.signNow, result.recipients[1].signNow);
			System.assertEquals(r2.tabs, result.recipients[1].tabs);
			System.assertEquals(r2.source, result.recipients[1].source);
			System.assertEquals(r2.readOnly, result.recipients[1].readOnly);
			System.assertEquals(r2.required, result.recipients[1].required);
			System.assertNotEquals(lm, result.lastModified);

			//validate update result
			System.assertNotEquals(null, result2);
			System.assertEquals(t2.id, result2.id);
			System.assertEquals(t2.name, result2.name);
			System.assertEquals(2, Collection.size(result2.customFields));
			System.assertNotEquals(null, result2.customFields[0]);
			System.assertEquals(cf1.type, result2.customFields[0].type);
			System.assertEquals(cf1.name, result2.customFields[0].name);
			System.assertEquals(cf1.value, result2.customFields[0].value);
			System.assertEquals(cf1.items, result2.customFields[0].items);
			System.assertEquals(cf1.required, result2.customFields[0].required);
			System.assertEquals(cf1.show, result2.customFields[0].show);
			System.assertNotEquals(null, result2.customFields[1]);
			System.assertEquals(cf2.type, result2.customFields[1].type);
			System.assertEquals(cf2.name, result2.customFields[1].name);
			System.assertEquals(cf2.value, result2.customFields[1].value);
			System.assertEquals(cf2.items, result2.customFields[1].items);
			System.assertEquals(cf2.required, result2.customFields[1].required);
			System.assertEquals(cf2.show, result2.customFields[1].show);
			System.assertNotEquals(null, result2.notifications);
			System.assertEquals(n.remind, result2.notifications.remind);
			System.assertEquals(n.remindAfterDays, result2.notifications.remindAfterDays);
			System.assertEquals(n.remindFrequencyDays, result2.notifications.remindFrequencyDays);
			System.assertEquals(n.expires, result2.notifications.expires);
			System.assertEquals(n.expireAfterDays, result2.notifications.expireAfterDays);
			System.assertEquals(n.expireWarnDays, result2.notifications.expireWarnDays);
			System.assertEquals(t2.emailSubject, result2.emailSubject);
			System.assertEquals(t2.emailMessage, result2.emailMessage);
			System.assertEquals(3, Collection.size(result2.documents));
			System.assertNotEquals(null, result2.documents[0]);
			System.assertEquals(d1.type, result2.documents[0].type);
			System.assertEquals(d1.sequence, result2.documents[0].sequence);
			System.assertEquals(d1.name, result2.documents[0].name);
			System.assertEquals(d1.extension, result2.documents[0].extension);
			System.assertEquals(d1.size, result2.documents[0].size);
			System.assertEquals(d1.lastModified, result2.documents[0].lastModified);
			System.assertEquals(d1.sourceId, result2.documents[0].sourceId);
			System.assertEquals(d1.readOnly, result2.documents[0].readOnly);
			System.assertEquals(d1.required, result2.documents[0].required);
			System.assertNotEquals(null, result2.documents[1]);
			System.assertEquals(d3.type, result2.documents[1].type);
			System.assertEquals(d3.sequence, result2.documents[1].sequence);
			System.assertEquals(d3.name, result2.documents[1].name);
			System.assertEquals(d3.extension, result2.documents[1].extension);
			System.assertEquals(d3.size, result2.documents[1].size);
			System.assertEquals(d3.lastModified, result2.documents[1].lastModified);
			System.assertEquals(d3.sourceId, result2.documents[1].sourceId);
			System.assertEquals(d3.readOnly, result2.documents[1].readOnly);
			System.assertEquals(d3.required, result2.documents[1].required);
			System.assertNotEquals(null, result2.documents[2]);
			System.assertEquals(d4.type, result2.documents[2].type);
			System.assertEquals(d4.sequence, result2.documents[2].sequence);
			System.assertEquals(d4.name, result2.documents[2].name);
			System.assertEquals(d4.extension, result2.documents[2].extension);
			System.assertEquals(d4.size, result2.documents[2].size);
			System.assertEquals(d4.lastModified, result2.documents[2].lastModified);
			System.assertEquals(d4.sourceId, result2.documents[2].sourceId);
			System.assertEquals(d4.readOnly, result2.documents[2].readOnly);
			System.assertEquals(d4.required, result2.documents[2].required);
			System.assertEquals(3, Collection.size(result2.recipients));
			System.assertNotEquals(null, result2.recipients[0]);
			System.assertEquals(r1.envelopeRecipientId, result2.recipients[0].envelopeRecipientId);
			System.assertEquals(r1.type, result2.recipients[0].type);
			System.assertEquals(r1.sequence, result2.recipients[0].sequence);
			System.assertEquals(r1.routingOrder, result2.recipients[0].routingOrder);
			System.assertNotEquals(null, result2.recipients[0].role);
			System.assertEquals(r1.role.name, result.recipients[0].role.name);
			System.assertEquals(r1.name, result2.recipients[0].name);
			System.assertEquals(r1.email, result2.recipients[0].email);
			System.assertEquals(null, result2.recipients[0].signingGroup);
			System.assertEquals(r1.phone, result2.recipients[0].phone);
			System.assertEquals(null, result2.recipients[0].authentication);
			System.assertEquals(r1.note, result2.recipients[0].note);
			System.assertEquals(null, result2.recipients[0].emailSettings);
			System.assertEquals(r1.hostName, result2.recipients[0].hostName);
			System.assertEquals(r1.hostEmail, result2.recipients[0].hostEmail);
			System.assertEquals(r1.signNow, result2.recipients[0].signNow);
			System.assertEquals(r1.tabs, result2.recipients[0].tabs);
			System.assertEquals(r1.source, result2.recipients[0].source);
			System.assertEquals(r1.readOnly, result2.recipients[0].readOnly);
			System.assertEquals(r1.required, result2.recipients[0].required);
			System.assertNotEquals(null, result2.recipients[1]);
			System.assertEquals(r3.envelopeRecipientId, result2.recipients[1].envelopeRecipientId);
			System.assertEquals(r3.type, result2.recipients[1].type);
			System.assertEquals(r3.sequence, result2.recipients[1].sequence);
			System.assertEquals(r3.routingOrder, result2.recipients[1].routingOrder);
			System.assertNotEquals(null, result2.recipients[1].role);
			System.assertEquals(r3.role.name, result2.recipients[1].role.name);
			System.assertEquals(r3.name, result2.recipients[1].name);
			System.assertEquals(r3.email, result2.recipients[1].email);
			System.assertEquals(null, result2.recipients[1].signingGroup);
			System.assertEquals(r3.phone, result2.recipients[1].phone);
			System.assertEquals(null, result2.recipients[1].authentication);
			System.assertEquals(r3.note, result2.recipients[1].note);
			System.assertEquals(null, result2.recipients[1].emailSettings);
			System.assertEquals(r3.hostName, result2.recipients[1].hostName);
			System.assertEquals(r3.hostEmail, result2.recipients[1].hostEmail);
			System.assertEquals(r3.signNow, result2.recipients[1].signNow);
			System.assertEquals(r3.tabs, result2.recipients[1].tabs);
			System.assertEquals(r3.source, result2.recipients[1].source);
			System.assertEquals(r3.readOnly, result2.recipients[1].readOnly);
			System.assertEquals(r3.required, result2.recipients[1].required);
			System.assertNotEquals(null, result2.recipients[2]);
			System.assertEquals(r4.envelopeRecipientId, result2.recipients[2].envelopeRecipientId);
			System.assertEquals(r4.type, result2.recipients[2].type);
			System.assertEquals(r4.sequence, result2.recipients[2].sequence);
			System.assertEquals(r4.routingOrder, result2.recipients[2].routingOrder);
			System.assertNotEquals(null, result2.recipients[2].role);
			System.assertEquals(r4.role.name, result2.recipients[2].role.name);
			System.assertEquals(r4.name, result2.recipients[2].name);
			System.assertEquals(r4.email, result2.recipients[2].email);
			System.assertEquals(null, result2.recipients[2].signingGroup);
			System.assertEquals(r4.phone, result2.recipients[2].phone);
			System.assertEquals(null, result2.recipients[2].authentication);
			System.assertEquals(r4.note, result2.recipients[2].note);
			System.assertEquals(null, result2.recipients[2].emailSettings);
			System.assertEquals(r4.hostName, result2.recipients[2].hostName);
			System.assertEquals(r4.hostEmail, result2.recipients[2].hostEmail);
			System.assertEquals(r4.signNow, result2.recipients[2].signNow);
			System.assertEquals(r4.tabs, result2.recipients[2].tabs);
			System.assertEquals(r4.source, result2.recipients[2].source);
			System.assertEquals(r4.readOnly, result2.recipients[2].readOnly);
			System.assertEquals(r4.required, result2.recipients[2].required);
			System.assertNotEquals(lm, result2.lastModified);
		}
	}

	@IsTest
	static void test_updateTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Template t = new Template(
				UUID.randomUUID(),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);

			Test.startTest();
			try {
				TemplateAPI.getInstance().updateTemplate(t);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	class TemplateUpdatePartialSuccessMock extends OAuthTokenMock {

		private ESignatureAPIMock eSignMock;

		public TemplateUpdatePartialSuccessMock() {
			this.eSignMock = new ESignatureAPIMock(true);
		}

		override public HttpResponse getResponse(final HttpRequest request) {
			if (request.getMethod() != 'PUT') return this.eSignMock.getResponse(request);

			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			TemplateAPI.APITemplateUpdate result = new TemplateAPI.APITemplateUpdate();
			result.errorDetails = new ESignatureAPI.ErrorDetails();
			result.errorDetails.errorCode = 'TEMPLATE_ERROR';
			result.errorDetails.message = 'Template update error.';
			TemplateAPI.APIListCustomField lcf1 = new TemplateAPI.APIListCustomField(null);
			lcf1.name = 'listField1';
			TemplateAPI.APIListCustomField lcf2 = new TemplateAPI.APIListCustomField(null);
			lcf2.name = 'listField2';
			lcf2.errorDetails = new ESignatureAPI.ErrorDetails();
			lcf2.errorDetails.errorCode = 'LCF2_ERROR';
			lcf2.errorDetails.message = 'List custom field error.';
			TemplateAPI.APIListCustomField lcf3 = new TemplateAPI.APIListCustomField(null);
			lcf3.name = 'listField3';
			result.listCustomFieldUpdateResults = new List<TemplateAPI.APIListCustomField> {
				lcf1, lcf2, lcf3
			};
			TemplateAPI.APITextCustomField tcf1 = new TemplateAPI.APITextCustomField(null);
			tcf1.name = 'textField1';
			tcf1.errorDetails = new ESignatureAPI.ErrorDetails();
			tcf1.errorDetails.errorCode = 'TCF1_ERROR';
			tcf1.errorDetails.message = 'Text custom field error.';
			TemplateAPI.APITextCustomField tcf2 = new TemplateAPI.APITextCustomField(null);
			tcf2.name = 'textField2';
			tcf2.errorDetails = new ESignatureAPI.ErrorDetails();
			tcf2.errorDetails.errorCode = 'SUCCESS';
			TemplateAPI.APITextCustomField tcf3 = new TemplateAPI.APITextCustomField(null);
			tcf3.name = 'textField3';
			tcf3.errorDetails = new ESignatureAPI.ErrorDetails();
			tcf3.errorDetails.errorCode = 'TCF3_ERROR';
			tcf3.errorDetails.message = 'Text custom field error.';
			result.textCustomFieldUpdateResults = new List<TemplateAPI.APITextCustomField> {
				tcf1, tcf2, tcf3
			};
			response.setBody(JSON.serialize(result));
			return response;
		}
	}

	@IsTest
	static void test_updateTemplate_partial_success() {
		Test.setMock(HttpCalloutMock.class, new TemplateUpdatePartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Template template = new Template(
				UUID.randomUUID(),
				UUID.randomUUID().toString(),
				new List<CustomField> {
					CustomField.newTextField('textField2', 'textField2.value', false, false),
					CustomField.newListField('listField1', 'listField1.value', new List<String>(), false, false)
				},
				null,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				null,
				Datetime.now().addDays(-1));
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			try {
				client.updateTemplate(
					template,
					1000);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assert(ex.getMessage().startsWith(Label.TemplateError));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplate_template_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Template t = new Template(
				UUID.randomUUID(),
				UUID.randomUUID().toString(),
				new List<CustomField>(),
				new Notifications(
					true,
					1,
					2,
					true,
					3,
					4),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Recipient>(),
				Datetime.now().addDays(-1));
			TemplateAPI.APITemplate template = new TemplateAPI.APITemplate(t, new Map<String, Blob>(), true);
			TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			System.assert(client.updateTemplate(t.id, template, 100));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplate_template_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				TemplateAPI.getInstance().updateTemplate(UUID.randomUUID(), null, 100);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assert(TemplateAPI.getInstance().deleteTemplate(UUID.randomUUID()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				TemplateAPI.getInstance().deleteTemplate(UUID.randomUUID());
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}
}
