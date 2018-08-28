@IsTest
private class TemplateAPITest {

	@IsTest
	static void test_getTemplate_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			final TemplateAPI client = TemplateAPI.getInstance();

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
			System.assertEquals(EnvelopeSettings__c.getOrgDefaults().Chatter__c.endsWith('On'), t.notifications.updateChatter);
			System.assertNotEquals(null, t.emailSubject);
			System.assertNotEquals(null, t.emailMessage);
			System.assertNotEquals(null, t.recipients);
			System.assertEquals(7, t.recipients.size());
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
				}
				sequence++;
			}
		}
	}

	@IsTest
	static void test_getTemplate_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			final TemplateAPI client = TemplateAPI.getInstance();
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
	static void test_getTemplates_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			final TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			final List<Template> templates = client.getTemplates();
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
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			final TemplateAPI client = TemplateAPI.getInstance();
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
}
