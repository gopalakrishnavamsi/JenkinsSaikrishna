@IsTest
private class EnvelopeServiceTest {

	@IsTest
	static void test_validate_valid() {
		Envelope e = new Envelope(null, null, null, null,
			new List<Document> {
				new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
			},
			new List<Recipient> {
				Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
			},
			new List<CustomField> {
				CustomField.newTextField('n1', 'v1', true, true)
			},
			new Notifications(true, 1, 1, true, 10, 5),
			'subject', 'message', null, null);

		Test.startTest();
		ValidationResult result1 = EnvelopeService.validate(e, false);
		ValidationResult result2 = EnvelopeService.validate(e, true);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertNotEquals(null, result2);
		System.assert(result2.isValid);
	}

	@IsTest
	static void test_validate_documents() {
		Envelope e = new Envelope(null, null, null, null,
			null,
			new List<Recipient> {
				Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
			},
			new List<CustomField> {
				CustomField.newTextField('n1', 'v1', true, true)
			},
			new Notifications(true, 1, 1, true, 10, 5),
			'subject', 'message', null, null);

		Test.startTest();
		ValidationResult result1 = EnvelopeService.validate(e, false);
		ValidationResult result2 = EnvelopeService.validate(e, true);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(new List<String> { Label.AtLeastOneDocumentIsRequired }, result2.messages);
	}

	@IsTest
	static void test_validate_recipients() {
		Envelope e = new Envelope(null, null, null, null,
			new List<Document> {
				new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
			},
			null,
			new List<CustomField> {
				CustomField.newTextField('n1', 'v1', true, true)
			},
			new Notifications(true, 1, 1, true, 10, 5),
			'subject', 'message', null, null);

		Test.startTest();
		ValidationResult result1 = EnvelopeService.validate(e, false);
		ValidationResult result2 = EnvelopeService.validate(e, true);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(new List<String> { Label.AtLeastOneRecipientIsRequired }, result2.messages);
	}

	@IsTest
	static void test_validate_custom_fields() {
		Envelope e = new Envelope(null, null, null, null,
			new List<Document> {
				new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
			},
			new List<Recipient> {
				Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
			},
			new List<CustomField> {
				CustomField.newTextField('n1', '', true, true),
				CustomField.newListField('n2', null, new List<String> { 'v1', 'v2' }, true, true),
				CustomField.newListField('n3', 'v1', null, true, true)
			},
			new Notifications(true, 1, 1, true, 10, 5),
			'subject', 'message', null, null);
		String m1 = String.format(Label.RequiredCustomField_1, new List<String> { 'n1' });
		String m2 = String.format(Label.RequiredCustomField_1, new List<String> { 'n2' });
		String m3 = String.format(Label.RequiredEmptyList_1, new List<String> { 'n3' });

		Test.startTest();
		ValidationResult result1 = EnvelopeService.validate(e, false);
		ValidationResult result2 = EnvelopeService.validate(e, true);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(new List<String> { m1, m2, m3 }, result1.messages);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(new List<String> { m1, m2, m3 }, result2.messages);
	}

	@IsTest
	static void test_validate_notifications() {
		Envelope e = new Envelope(null, null, null, null,
			new List<Document> {
				new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
			},
			new List<Recipient> {
				Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
			},
			new List<CustomField> {
				CustomField.newTextField('n1', 'v1', true, true)
			},
			new Notifications(true, -1, 1, true, 10, 5),
			'subject', 'message', null, null);

		Test.startTest();
		ValidationResult result1 = EnvelopeService.validate(e, false);
		ValidationResult result2 = EnvelopeService.validate(e, true);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(new List<String> { Label.InvalidNotificationSettings }, result1.messages);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(new List<String> { Label.InvalidNotificationSettings }, result2.messages);
	}

	@IsTest
	static void test_validate_email() {
		Envelope e = new Envelope(null, null, null, null,
			new List<Document> {
				new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
			},
			new List<Recipient> {
				Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
			},
			new List<CustomField> {
				CustomField.newTextField('n1', 'v1', true, true)
			},
			new Notifications(true, 1, 1, true, 10, 5),
			null,
			'012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ '012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789012345678901234567891023456789'
				+ 'too big', null, null);

		Test.startTest();
		ValidationResult result1 = EnvelopeService.validate(e, false);
		ValidationResult result2 = EnvelopeService.validate(e, true);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(new List<String> { Label.EmailSubjectRequired, Label.EmailMessageTooLarge }, result1.messages);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(new List<String> { Label.EmailSubjectRequired, Label.EmailMessageTooLarge }, result2.messages);
	}

	@IsTest
	static void test_Database_convert() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			Document__c d1 = TestUtils.createEnvelopeDocument(e.Id, 1);
			Document__c d2 = TestUtils.createEnvelopeDocument(e.Id, 2);
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);
			e.Documents__r.addAll(new List<Document__c> { d1, d2 });
			e.Recipients__r.addAll(new List<Recipient__c> { r1, r2 });

			Test.startTest();
			Envelope__c result = EnvelopeService.DB.convert(EnvelopeService.DB.convert(e));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(e.Id, result.Id);
			System.assertEquals(e.Name, result.Name);
			System.assertEquals(e.DocuSignId__c, result.DocuSignId__c);
			System.assertEquals(e.EnvelopeConfiguration__c, result.EnvelopeConfiguration__c);
			System.assertEquals(e.Remind__c, result.Remind__c);
			System.assertEquals(e.RemindAfterDays__c, result.RemindAfterDays__c);
			System.assertEquals(e.RemindFrequencyDays__c, result.RemindFrequencyDays__c);
			System.assertEquals(e.Expires__c, result.Expires__c);
			System.assertEquals(e.ExpireAfterDays__c, result.ExpireAfterDays__c);
			System.assertEquals(e.ExpireWarnDays__c, result.ExpireWarnDays__c);
			System.assertEquals(e.EmailSubject__c, result.EmailSubject__c);
			System.assertEquals(e.EmailMessage__c, result.EmailMessage__c);
			System.assertEquals(e.SourceId__c, result.SourceId__c);
			System.assertEquals(e.Sent__c, result.Sent__c);
		}
	}

	@IsTest
	static void test_Database_queryEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.DB.queryEnvelope(e.Id);
				throw new AssertException('Expected queryEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_queryEnvelope_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			TestUtils.createEnvelopeDocument(e.Id, 1);
			TestUtils.createEnvelopeDocument(e.Id, 2);
			TestUtils.createEnvelopeRecipient(e.Id, 1);
			TestUtils.createEnvelopeRecipient(e.Id, 2);

			Test.startTest();
			Envelope result = EnvelopeService.DB.queryEnvelope(e.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(e.Id, result.id);
			System.assertNotEquals(null, result.name);
			System.assertEquals(e.DocuSignId__c, UUID.toString(result.docuSignId));
			System.assertEquals(e.EnvelopeConfiguration__c, result.envelopeConfigurationId);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(2, result.recipients.size());
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(e.Remind__c, result.notifications.remind);
			System.assertEquals(e.RemindAfterDays__c, result.notifications.remindAfterDays);
			System.assertEquals(e.RemindFrequencyDays__c, result.notifications.remindFrequencyDays);
			System.assertEquals(e.Expires__c, result.notifications.expires);
			System.assertEquals(e.ExpireAfterDays__c, result.notifications.expireAfterDays);
			System.assertEquals(e.ExpireWarnDays__c, result.notifications.expireWarnDays);
			System.assertEquals(e.EmailSubject__c, result.emailSubject);
			System.assertEquals(e.EmailMessage__c, result.emailMessage);
			System.assertNotEquals(null, result.source);
			System.assertEquals(e.SourceId__c, result.source.id);
			System.assertEquals(e.Sent__c, result.sent);
		}
	}

	@IsTest
	static void test_Database_insertEnvelope() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(
				new Notifications(true, 1, 2, true, 3, 4),
				'subject',
				'message',
				new Entity(a.Id));

			Test.startTest();
			Envelope result = EnvelopeService.DB.insertEnvelope(e);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(e.docuSignId, result.docuSignId);
			System.assertEquals(e.envelopeConfigurationId, result.envelopeConfigurationId);
			System.assertEquals(0, Collection.size(result.documents));
			System.assertEquals(0, Collection.size(result.recipients));
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(e.notifications.remind, result.notifications.remind);
			System.assertEquals(e.notifications.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(e.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(e.notifications.expires, result.notifications.expires);
			System.assertEquals(e.notifications.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(e.notifications.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(e.emailSubject, result.emailSubject);
			System.assertEquals(e.emailMessage, result.emailMessage);
			System.assertNotEquals(null, result.source);
			System.assertEquals(e.source.id, result.source.id);
			System.assertEquals(e.sent, result.sent);
		}
	}

	@IsTest
	static void test_Database_updateEnvelope2() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c ee = TestUtils.createEnvelope(a.Id);
			ee.Sent__c = null;
			update ee;
			Envelope e = EnvelopeService.DB.convert(ee)
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('tf1', 'tv1', false, true)
				})
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4))
				.withEmail('subject2', 'message2');
			UUID docuSignId = UUID.randomUUID();

			Test.startTest();
			Envelope result1 = EnvelopeService.DB.updateEnvelope2(e, false);
			Envelope result2 = EnvelopeService.DB.updateEnvelope2(e.copy().withId(result1.id).withDocuSignId(docuSignId), true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.id);
			System.assertEquals(e.docuSignId, result1.docuSignId);
			System.assertEquals(e.envelopeConfigurationId, result1.envelopeConfigurationId);
			System.assert(Collection.isEmpty(result1.documents));
			System.assert(Collection.isEmpty(result1.recipients));
			System.assertEquals(1, Collection.size(result1.customFields));
			System.assertEquals('tf1', result1.customFields[0].name);
			System.assertEquals('tv1', result1.customFields[0].value);
			System.assert(!result1.customFields[0].required);
			System.assert(result1.customFields[0].show);
			System.assertNotEquals(null, result1.notifications);
			System.assertEquals(e.notifications.remind, result1.notifications.remind);
			System.assertEquals(e.notifications.remindAfterDays, result1.notifications.remindAfterDays);
			System.assertEquals(e.notifications.remindFrequencyDays, result1.notifications.remindFrequencyDays);
			System.assertEquals(e.notifications.expires, result1.notifications.expires);
			System.assertEquals(e.notifications.expireAfterDays, result1.notifications.expireAfterDays);
			System.assertEquals(e.notifications.expireWarnDays, result1.notifications.expireWarnDays);
			System.assertEquals(e.emailSubject, result1.emailSubject);
			System.assertEquals(e.emailMessage, result1.emailMessage);
			System.assertNotEquals(null, result1.source);
			System.assertEquals(e.source.id, result1.source.id);
			System.assertEquals(null, result1.sent);

			System.assertNotEquals(null, result2);
			System.assert(result2.isSent);
			System.assertNotEquals(null, result2.sent);
			System.assertEquals(docuSignId, result2.docuSignId);
		}
	}

	@IsTest
	static void test_Database_updateEnvelopeSent() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			UUID docuSignId = UUID.randomUUID();

			Test.startTest();
			Boolean result = EnvelopeService.DB.updateEnvelopeSent(e.Id, docuSignId, true);
			Test.stopTest();

			System.assert(result);

			Envelope__c e2 = [SELECT Id, DocuSignId__c, EmailSubject__c, EmailMessage__c, Sent__c FROM Envelope__c WHERE Id = :e.Id];
			System.assertNotEquals(null, e2);
			System.assertEquals(docuSignId.toString(), e2.DocuSignId__c);
			System.assertNotEquals(null, e2.Sent__c);
		}
	}

	@IsTest
	static void test_Database_deleteEnvelope2() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			TestUtils.createEnvelopeDocument(e.Id, 1);
			TestUtils.createEnvelopeDocument(e.Id, 2);
			TestUtils.createEnvelopeRecipient(e.Id, 1);
			TestUtils.createEnvelopeRecipient(e.Id, 2);

			Test.startTest();
			Id result = EnvelopeService.DB.deleteEnvelope2(e.Id);
			Test.stopTest();

			System.assertEquals(a.Id, result);
			List<Envelope__c> es = [SELECT Id FROM Envelope__c WHERE Id = :e.Id];
			System.assert(Collection.isEmpty(es));
		}
	}

	@IsTest
	static void test_Database_deleteEnvelope2_invalid_SourceId() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			e.SourceId__c = 'bad';
			update e;

			Test.startTest();
			Id result = EnvelopeService.DB.deleteEnvelope2(e.Id);
			Test.stopTest();

			System.assertEquals(null, result);
		}
	}

	@IsTest
	static void test_saveEnvelope() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Lead l = TestUtils.createLead();
			Envelope e = new Envelope(null, 'subject', 'message', new Entity(l.Id))
				.withDocuments(new List<Document> {
					new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
				})
				.withRecipients(new List<Recipient> {
					Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
				})
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', false, false)
				});

			Test.startTest();
			Envelope result = EnvelopeService.saveEnvelope(e);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(e.documents.size(), result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(e.recipients.size(), result.recipients.size());
			System.assertNotEquals(null, result.customFields);
			System.assertEquals(e.customFields, result.customFields);
		}
	}

	@IsTest
	static void test_addSourceDocuments() {
		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			Envelope e = new Envelope(null, 'subject', 'message', new Entity(l.Id))
				.withDocuments(new List<Document> {
					new Document(null, Document.TYPE_FILE, 1, 'd1', 'pdf', 1234, Datetime.now(), null)
				})
				.withRecipients(new List<Recipient> {
					Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, 'n1', false)
				})
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', false, false)
				});
			ContentVersion cv1 = TestUtils.createContentVersion(l.Id);
			ContentVersion cv2 = TestUtils.createContentVersion(l.Id);

			Test.startTest();
			Envelope result = EnvelopeService.addSourceDocuments(e, new Entity(l.Id), false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(3, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(e.recipients.size(), result.recipients.size());
			System.assertNotEquals(null, result.customFields);
			System.assertEquals(e.customFields, result.customFields);

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
	static void test_addSourceRecipients() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id));
			TestUtils.createContact(a.Id);
			TestUtils.createContact(a.Id);
			Recipient.EmailSettings es = new Recipient.EmailSettings(
				Localization.NL,
				Localization.getLabel(Localization.NL),
				'nl subject',
				'nl message');

			Test.startTest();
			Envelope result = EnvelopeService.addSourceRecipients(e, new Entity(a.Id), es);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(2, result.recipients.size());
		}
	}

	@IsTest
	static void test_createEnvelope_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				EnvelopeService.createEnvelope(null, null, false);
				throw new AssertException('Expected createEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createEnvelope_no_source() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id))
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', true, false)
				});
			TestUtils.createContact(a.Id);
			TestUtils.createContentVersion(a.Id);

			Test.startTest();
			Envelope result = EnvelopeService.createEnvelope(e, null, false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assert(Collection.isEmpty(result.documents));
			System.assert(Collection.isEmpty(result.recipients));
			System.assertEquals(e.customFields, result.customFields);
		}
	}

	@IsTest
	static void test_createEnvelope_add_from_source() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id))
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', true, false)
				});
			TestUtils.createContact(a.Id);
			TestUtils.createContact(a.Id);
			TestUtils.createContact(a.Id);
			TestUtils.createContentVersion(a.Id);
			TestUtils.createContentVersion(a.Id);

			Test.startTest();
			Envelope result = EnvelopeService.createEnvelope(e, null, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(3, result.recipients.size());
			System.assertEquals(e.customFields, result.customFields);
		}
	}

	@IsTest
	static void test_getEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.getEnvelope(e.Id);
				throw new AssertException('Expected getEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelope_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			TestUtils.createEnvelopeDocument(e.Id);
			TestUtils.createEnvelopeDocument(e.Id);
			TestUtils.createEnvelopeRecipient(e.Id);
			TestUtils.createEnvelopeRecipient(e.Id);

			Test.startTest();
			Envelope result = EnvelopeService.getEnvelope(e.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(2, result.recipients.size());
		}
	}

	@IsTest
	static void test_updateEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.updateEnvelope(EnvelopeService.DB.convert(e));
				throw new AssertException('Expected updateEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateEnvelope_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.id));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.id));
			Document d3 = d2.copy();
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.id));
			Recipient r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.id));
			Recipient r3 = r2.copy();

			Test.startTest();
			Envelope result = EnvelopeService.updateEnvelope(e
				.withDocuments(new List<Document> { d1, d2, d3 })
				.withRecipients(new List<Recipient> { r1, r2, r3 })
				.withEmail('s2', 'm2')
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4)));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(3, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(3, result.recipients.size());
			System.assertNotEquals(null, result.notifications);
			System.assert(result.notifications.remind);
			System.assertEquals(1, result.notifications.remindAfterDays);
			System.assertEquals(2, result.notifications.remindFrequencyDays);
			System.assert(result.notifications.expires);
			System.assertEquals(3, result.notifications.expireAfterDays);
			System.assertEquals(4, result.notifications.expireWarnDays);
			System.assertEquals('s2', result.emailSubject);
			System.assertEquals('m2', result.emailMessage);
		}
	}

	@IsTest
	static void test_sendEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.sendEnvelope(EnvelopeService.DB.convert(e), true);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_update_later() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignSender()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.CreateConnectConfiguration__c = true;
			update s;
			Envelope__c ee1 = TestUtils.createEnvelope();
			ee1.DocuSignId__c = null;
			ee1.Sent__c = null;
			Envelope e1 = EnvelopeService.DB.convert(ee1)
				.withDocuments(new List<Document> {
					DocumentService.DB.convert(TestUtils.createEnvelopeDocument(ee1.Id))
				})
				.withRecipients(new List<Recipient> {
					RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(ee1.Id))
				});
			Envelope__c ee2 = TestUtils.createEnvelope();
			ee2.DocuSignId__c = null;
			ee2.Sent__c = null;
			Envelope e2 = EnvelopeService.DB.convert(ee2)
				.withDocuments(new List<Document> {
					DocumentService.DB.convert(TestUtils.createEnvelopeDocument(ee2.Id))
				})
				.withRecipients(new List<Recipient> {
					RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(ee2.Id))
				})
				.withEmail('s2', 'm2')
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4));
			update new List<Envelope__c> { ee1, ee2 };

			Test.startTest();
			Envelope result1 = EnvelopeService.sendEnvelope(e1, false, false, 'Unit Test');
			Envelope result2 = EnvelopeService.sendEnvelope(e2, true, false, 'Unit Test');
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.docuSignId);
			System.assert(!result1.isSent);
			System.assertNotEquals(null, result1.documents);
			System.assertEquals(1, result1.documents.size());
			System.assertNotEquals(null, result1.recipients);
			System.assertEquals(1, result1.recipients.size());
			List<EnvelopeStatus__c> statuses = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :result1.docuSignId.toString()];
			System.assert(Collection.isEmpty(statuses));

			System.assertNotEquals(null, result2);
			System.assertNotEquals(null, result2.docuSignId);
			System.assert(result2.isSent);
			System.assertNotEquals(null, result2.documents);
			System.assertEquals(1, result2.documents.size());
			System.assertNotEquals(null, result2.recipients);
			System.assertEquals(1, result2.recipients.size());
			System.assertNotEquals(null, result2.notifications);
			System.assert(result2.notifications.remind);
			System.assertEquals(1, result2.notifications.remindAfterDays);
			System.assertEquals(2, result2.notifications.remindFrequencyDays);
			System.assert(result2.notifications.expires);
			System.assertEquals(3, result2.notifications.expireAfterDays);
			System.assertEquals(4, result2.notifications.expireWarnDays);
			System.assertEquals('s2', result2.emailSubject);
			System.assertEquals('m2', result2.emailMessage);
			statuses = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :result2.docuSignId.toString()];
			System.assert(Collection.isEmpty(statuses));

			Set<Id> ids = new Set<Id> { ee1.Id, ee2.Id };
			for (Envelope__c e : [SELECT DocuSignId__c, Sent__c FROM Envelope__c WHERE Id IN :ids]) {
				System.assertEquals(null, e.DocuSignId__c);
				System.assertEquals(null, e.Sent__c);
			}

			System.assertEquals(true, AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c);
		}
	}

	@IsTest
	static void test_sendEnvelope_update_now() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignSender()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.CreateConnectConfiguration__c = true;
			update s;
			Envelope__c ee1 = TestUtils.createEnvelope();
			ee1.DocuSignId__c = null;
			update ee1;
			Envelope e1 = EnvelopeService.DB.convert(ee1)
				.withDocuments(new List<Document> {
					DocumentService.DB.convert(TestUtils.createEnvelopeDocument(ee1.Id))
				})
				.withRecipients(new List<Recipient> {
					RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(ee1.Id))
				})
				.withEmail('s2', 'm2')
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4));

			Test.startTest();
			Envelope result = EnvelopeService.sendEnvelope(e1, true, true, 'Unit Test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.docuSignId);
			System.assert(result.isSent);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(1, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(1, result.recipients.size());
			System.assertNotEquals(null, result.notifications);
			System.assert(result.notifications.remind);
			System.assertEquals(1, result.notifications.remindAfterDays);
			System.assertEquals(2, result.notifications.remindFrequencyDays);
			System.assert(result.notifications.expires);
			System.assertEquals(3, result.notifications.expireAfterDays);
			System.assertEquals(4, result.notifications.expireWarnDays);
			System.assertEquals('s2', result.emailSubject);
			System.assertEquals('m2', result.emailMessage);

			Envelope__c e = [SELECT DocuSignId__c, Sent__c FROM Envelope__c WHERE Id = :ee1.Id];
			System.assertNotEquals(null, e.DocuSignId__c);
			System.assertNotEquals(null, e.Sent__c);

			List<EnvelopeStatus__c> statuses = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :result.docuSignId.toString()];
			System.assertNotEquals(null, statuses);
			System.assertEquals(1, statuses.size());

			System.assertEquals(false, AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c);
		}
	}

	@IsTest
	static void test_sendEnvelope_with_create_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				EnvelopeService.sendEnvelope(new Envelope(null, null, null, null), true);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_with_create() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignSender()) {
			Lead l = TestUtils.createLead();
			Envelope e = EnvelopeService.getEmptyEnvelope(new Entity(l.Id))
				.withDocuments(new List<Document> {
					Document.fromFile(TestUtils.createContentVersion(l.Id))
				})
				.withRecipients(new List<Recipient> {
					Recipient.fromSource(l.Name, l.Email, l.Phone, null, new Entity(l.Id))
				})
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', true, true)
				});

			Test.startTest();
			Envelope result = EnvelopeService.sendEnvelope(e, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assert(!UUID.isEmpty(result.docuSignId));
			System.assertEquals(1, Collection.size(result.documents));
			System.assertEquals(1, Collection.size(result.recipients));
			System.assertEquals(1, Collection.size(result.customFields));

			List<Envelope__c> es = [SELECT DocuSignId__c, Sent__c FROM Envelope__c WHERE Id = :result.id];
			System.assertEquals(1, Collection.size(es));
			System.assertNotEquals(null, es[0]);
			System.assertNotEquals(null, es[0].DocuSignId__c);
			System.assertNotEquals(null, es[0].Sent__c);
			System.assertEquals(1, Collection.size([SELECT Id FROM Document__c WHERE Envelope__c = :result.id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM Recipient__c WHERE Envelope__c = :result.id]));
		}
	}

	@IsTest
	static void test_markEnvelopeSent_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.markEnvelopeSent(EnvelopeService.DB.convert(e), true);
				throw new AssertException('Expected markEnvelopeSent to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_markEnvelopeSent_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Envelope e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			Boolean result1 = EnvelopeService.markEnvelopeSent(e1, false);
			Boolean result2 = EnvelopeService.markEnvelopeSent(e2, true);
			Test.stopTest();

			System.assert(result1);
			System.assert(result2);

			Set<Id> ids = new Set<Id> { e1.id, e2.id };
			for (Envelope__c e : [SELECT DocuSignId__c, Sent__c FROM Envelope__c WHERE Id IN :ids]) {
				System.assertNotEquals(null, e.DocuSignId__c);
				if (e.Id == e1.id) {
					System.assertEquals(null, e.Sent__c);
				} else {
					System.assertNotEquals(null, e.Sent__c);
				}
			}

			Set<String> dsIds = new Set<String> { String.valueOf(e1.docuSignId), String.valueOf(e2.docuSignId) };
			List<EnvelopeStatus__c> ess = [SELECT DocuSignId__c, Sent__c FROM EnvelopeStatus__c WHERE DocuSignId__c IN :dsIds];
			System.assertNotEquals(null, ess);
			System.assertEquals(1, ess.size());
			System.assertEquals(String.valueOf(e2.docuSignId), ess[0].DocuSignId__c);
			System.assertNotEquals(null, ess[0].Sent__c);
		}
	}

	@IsTest
	static void test_deleteEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.deleteEnvelope(e.Id);
				throw new AssertException('Expected deleteEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelope_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Contact c = TestUtils.createContact();
			Envelope__c e = TestUtils.createEnvelope(c.Id);
			TestUtils.createEnvelopeDocument(e.Id);
			TestUtils.createEnvelopeRecipient(e.Id);

			Test.startTest();
			Id result = EnvelopeService.deleteEnvelope(e.Id);
			Test.stopTest();

			System.assertEquals(c.Id, result);

			List<Envelope__c> es = [SELECT Id FROM Envelope__c WHERE Id = :e.Id];
			System.assert(Collection.isEmpty(es));
		}
	}

	@IsTest
	static void test_getEmptyEnvelope_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				EnvelopeService.getEmptyEnvelope(null);
				throw new AssertException('Expected getEmptyEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEmptyEnvelope_success() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Lead l = TestUtils.createLead();

			Test.startTest();
			Envelope result = EnvelopeService.getEmptyEnvelope(new Entity(l.Id));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.notifications);
			Recipient.EmailSettings es = Localization.getEmailSettingsForCurrentLanguage();
			System.assertEquals(es.subject, result.emailSubject);
			System.assertEquals(es.message, result.emailMessage);
			System.assertNotEquals(null, result.source);
			System.assertEquals(l.Id, result.source.id);
		}
	}

	@IsTest
	static void test_getSenderViewUrl_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeService.getSenderViewUrl(UUID.parse(e.DocuSignId__c), null);
				throw new AssertException('Expected getSenderViewUrl to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSenderViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();

			Test.startTest();
			Url result = EnvelopeService.getSenderViewUrl(UUID.parse(e.DocuSignId__c),
				new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_sendEnvelopes_unauthorized() {
		System.runAs(UserMock.createAdministrator()) {
			Test.startTest();
			try {
				EnvelopeService.sendEnvelopes(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelopes_undefined_argument() {
		System.runAs(UserMock.createDocuSignSender()) {
			Test.startTest();
			try {
				EnvelopeService.sendEnvelopes(null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				EnvelopeService.sendEnvelopes(new List<Envelope>());
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelopes_limit_exceeded() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			List<Envelope> es = new List<Envelope>();
			for (Integer i = 0; i <= EnvelopeService.MULTI_SEND_ENVELOPE_LIMIT; i++) {
				es.add(new Envelope(null, null, null, null));
			}

			Test.startTest();
			try {
				EnvelopeService.sendEnvelopes(es);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.MultiSendEnvelopeLimitExceeded, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelopes_invalid() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			List<Envelope> es = new List<Envelope> {
				new Envelope(null, 's1', 'm1', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e1d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e1d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null)
					}),
				null,
				new Envelope(null, 's3', 'm3', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e3d1')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e3r1', 'e3r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e3r2', 'e3r2@unit.test', '2222222', 'r2', null)
					})
			};

			Test.startTest();
			try {
				EnvelopeService.sendEnvelopes(es);
				throw new AssertException('Expected failure');
			} catch (ValidationException ex) {
				System.assertNotEquals(null, ex.getMessage());
				System.assert(ex.getMessage().startsWith(Label.InvalidEnvelope));
				System.assertNotEquals(null, ex.details);
			}
			Test.stopTest();
		}
	}

	private class PartialSuccessMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			EnvelopeAPI.APIEnvelope e = (EnvelopeAPI.APIEnvelope)JSON.deserialize(request.getBody(), EnvelopeAPI.APIEnvelope.class);
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json');
			if (e.emailSubject == 's2') {
				response.setStatusCode(400);
				response.setStatus('BAD_REQUEST');
				response.setBody('{"errorCode":"UNIT_TEST","message":"trialexpired"}');
			} else {
				response.setStatusCode(201);
				response.setStatus('CREATED');
				e.envelopeId = UUID.randomUUID().toString();
				response.setBody(JSON.serialize(e));
			}
			return response;
		}
	}

	@IsTest
	static void test_sendEnvelopes_partial_success() {
		Test.setMock(HttpCalloutMock.class, new PartialSuccessMock());
		System.runAs(UserMock.createDocuSignSender()) {
			List<Envelope> es = new List<Envelope> {
				new Envelope(null, 's1', 'm1', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e1d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e1d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null)
					}),
				new Envelope(null, 's2', 'm2', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e2d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e2d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e2r1', 'e2r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e2r2', 'e2r2@unit.test', '2222222', 'r2', null)
					}),
				new Envelope(null, 's3', 'm3', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e3d1')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e3r1', 'e3r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e3r2', 'e3r2@unit.test', '2222222', 'r2', null)
					})
			};

			Test.startTest();
			List<Envelope> result = EnvelopeService.sendEnvelopes(es);
			Test.stopTest();

			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].docuSignId);
			System.assertNotEquals(null, result[0].sent);
			System.assertEquals(null, result[0].error);
			System.assertEquals(2, Collection.size(result[0].documents));
			System.assertEquals(1, Collection.size(result[0].recipients));
			System.assertNotEquals(null, result[1]);
			System.assertEquals(null, result[1].docuSignId);
			System.assertEquals(null, result[1].sent);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.TRIAL_ACCOUNT_EXPIRED, result[1].error.code);
			System.assertEquals(2, Collection.size(result[1].documents));
			System.assertEquals(2, Collection.size(result[1].recipients));
			System.assertNotEquals(null, result[2]);
			System.assertNotEquals(null, result[2].docuSignId);
			System.assertNotEquals(null, result[2].sent);
			System.assertEquals(null, result[2].error);
			System.assertEquals(1, Collection.size(result[2].documents));
			System.assertEquals(2, Collection.size(result[2].recipients));
		}
	}

	@IsTest
	static void test_sendEnvelopes_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignSender()) {
			List<Envelope> es = new List<Envelope> {
				new Envelope(null, 's1', 'm1', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e1d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e1d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null)
					}),
				new Envelope(null, 's2', 'm2', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e2d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e2d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e2r1', 'e2r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e2r2', 'e2r2@unit.test', '2222222', 'r2', null)
					}),
				new Envelope(null, 's3', 'm3', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e3d1')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e3r1', 'e3r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e3r2', 'e3r2@unit.test', '2222222', 'r2', null)
					})
			};

			Test.startTest();
			List<Envelope> result = EnvelopeService.sendEnvelopes(es);
			Test.stopTest();

			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].docuSignId);
			System.assertNotEquals(null, result[0].sent);
			System.assertEquals(null, result[0].error);
			System.assertEquals(2, Collection.size(result[0].documents));
			System.assertEquals(1, Collection.size(result[0].recipients));
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].docuSignId);
			System.assertNotEquals(null, result[1].sent);
			System.assertEquals(null, result[1].error);
			System.assertEquals(2, Collection.size(result[1].documents));
			System.assertEquals(2, Collection.size(result[1].recipients));
			System.assertNotEquals(null, result[2]);
			System.assertNotEquals(null, result[2].docuSignId);
			System.assertNotEquals(null, result[2].sent);
			System.assertEquals(null, result[2].error);
			System.assertEquals(1, Collection.size(result[2].documents));
			System.assertEquals(2, Collection.size(result[2].recipients));
		}
	}

	@IsTest
	static void test_sendEnvelopes_limit() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignSender()) {
			List<Envelope> es = new List<Envelope>();
			for (Integer i = 0; i < EnvelopeService.MULTI_SEND_ENVELOPE_LIMIT; i++) {
				es.add(new Envelope(null, 's' + i, 'm' + i, null)
					.withDocuments(new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 't' + i)
					})
					.withRecipients(new List<Recipient> {
						Recipient.fromSource('r' + i, 'r' + i + '@unit.test', null, 'Signer 1', null)
					}));
			}

			Test.startTest();
			List<Envelope> result = EnvelopeService.sendEnvelopes(es);
			Test.stopTest();

			System.assertEquals(EnvelopeService.MULTI_SEND_ENVELOPE_LIMIT, Collection.size(result));
			for (Envelope e : result) {
				System.assertNotEquals(null, e);
				System.assertEquals(null, e.error);
				System.assertNotEquals(null, e.docuSignId);
				System.assertNotEquals(null, e.sent);
			}
		}
	}

	private class ApiLimitExceededMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"errorCode":"HOURLY_APIINVOCATION_LIMIT_EXCEEDED","message":"Hourly API limit exceeded"}');
			return response;
		}
	}

	@IsTest
	static void test_sendEnvelopes_api_limit_exceeded() {
		Test.setMock(HttpCalloutMock.class, new ApiLimitExceededMock());
		System.runAs(UserMock.createDocuSignSender()) {
			List<Envelope> es = new List<Envelope>();
			for (Integer i = 0; i < 3; i++) {
				es.add(new Envelope(null, 's' + i, 'm' + i, null)
					.withDocuments(new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 't' + i)
					})
					.withRecipients(new List<Recipient> {
						Recipient.fromSource('r' + i, 'r' + i + '@unit.test', null, 'Signer 1', null)
					}));
			}

			Test.startTest();
			List<Envelope> result = EnvelopeService.sendEnvelopes(es);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			for (Envelope e : result) {
				System.assertNotEquals(null, e);
				System.assertNotEquals(null, e.error);
				System.assertEquals(APIErrorCode.HOURLY_API_LIMIT_EXCEEDED, e.error.code);
			}
		}
	}

	@IsTest
	static void test_saveSentEnvelopes_unauthorized() {
		System.runAs(UserMock.createAdministrator()) {
			Test.startTest();
			try {
				EnvelopeService.saveSentEnvelopes(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSentEnvelopes_undefined_argument() {
		System.runAs(UserMock.createDocuSignSender()) {
			Test.startTest();
			try {
				EnvelopeService.saveSentEnvelopes(null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				EnvelopeService.saveSentEnvelopes(new List<Envelope>());
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSentEnvelopes_invalid() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			List<Envelope> es = new List<Envelope> {
				new Envelope(null, 's1', 'm1', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e1d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e1d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null)
					})
					.withDocuSignId(UUID.randomUUID())
					.withSent(Datetime.now()),
				new Envelope(null, 's2', 'm2', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e2d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e2d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e2r1', 'e2r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e2r2', 'e2r2@unit.test', '2222222', 'r2', null)
					})
					.withError(new APIError(APIErrorCode.BAD_REQUEST, 'test error')),
				new Envelope(null, 's3', 'm3', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e3d1')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e3r1', 'e3r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e3r2', 'e3r2@unit.test', '2222222', 'r2', null)
					})
					.withDocuSignId(UUID.randomUUID())
					.withSent(Datetime.now())
			};

			Test.startTest();
			try {
				EnvelopeService.saveSentEnvelopes(es);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidSentEnvelopes, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSentEnvelopes_success() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			UUID id1 = UUID.randomUUID(), id2 = UUID.randomUUID(), id3 = UUID.randomUUID();
			List<Envelope> es = new List<Envelope> {
				new Envelope(null, 's1', 'm1', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e1d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e1d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null)
					})
					.withDocuSignId(id1)
					.withSent(Datetime.now()),
				new Envelope(null, 's2', 'm2', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e2d1'),
						Document.fromTemplate(UUID.randomUUID(), 'e2d2')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e2r1', 'e2r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e2r2', 'e2r2@unit.test', '2222222', 'r2', null)
					})
					.withDocuSignId(id2)
					.withSent(Datetime.now()),
				new Envelope(null, 's3', 'm3', null)
					.withDocuments(
					new List<Document> {
						Document.fromTemplate(UUID.randomUUID(), 'e3d1')
					})
					.withRecipients(
					new List<Recipient> {
						Recipient.fromSource('e3r1', 'e3r1@unit.test', '1111111', 'r1', null),
						Recipient.fromSource('e3r2', 'e3r2@unit.test', '2222222', 'r2', null)
					})
					.withDocuSignId(id3)
					.withSent(Datetime.now())
			};

			Test.startTest();
			List<Envelope> result = EnvelopeService.saveSentEnvelopes(es);
			Test.stopTest();

			Set<Id> eIds = new Set<Id>();
			System.assertEquals(3, result.size());
			for (Envelope e : result) {
				System.assertNotEquals(null, e);
				System.assertNotEquals(null, e.id);
				eIds.add(e.id);
				if (e.docuSignId == id1) {
					System.assertEquals('s1', e.emailSubject);
					System.assertEquals('m1', e.emailMessage);
					System.assertEquals(2, Collection.size(e.documents));
					System.assertEquals(1, Collection.size(e.recipients));
				} else if (e.docuSignId == id2) {
					System.assertEquals('s2', e.emailSubject);
					System.assertEquals('m2', e.emailMessage);
					System.assertEquals(2, Collection.size(e.documents));
					System.assertEquals(2, Collection.size(e.recipients));
				} else if (e.docuSignId == id3) {
					System.assertEquals('s3', e.emailSubject);
					System.assertEquals('m3', e.emailMessage);
					System.assertEquals(1, Collection.size(e.documents));
					System.assertEquals(2, Collection.size(e.recipients));
				} else {
					throw new AssertException('Unexpected result: ' + e);
				}

				for (Document d : e.documents) {
					System.assertNotEquals(null, d);
					System.assertNotEquals(null, d.id);
				}

				for (Recipient r : e.recipients) {
					System.assertNotEquals(null, r);
					System.assertNotEquals(null, r.id);
				}
			}

			List<Envelope__c> dses = [SELECT DocuSignId__c, Sent__c, EmailSubject__c, EmailMessage__c FROM Envelope__c WHERE Id IN :eIds];
			System.assertEquals(3, Collection.size(dses));
			for (Envelope__c e : dses) {
				System.assertNotEquals(null, e);
				System.assert(String.isNotBlank(e.DocuSignId__c));
				System.assertNotEquals(null, e.Sent__c);
				UUID dsId = UUID.parse(e.DocuSignId__c);
				if (dsId == id1) {
					System.assertEquals('s1', e.EmailSubject__c);
					System.assertEquals('m1', e.EmailMessage__c);
					System.assertEquals(2, Collection.size([SELECT Id FROM Document__c WHERE Envelope__c = :e.Id]));
					System.assertEquals(1, Collection.size([SELECT Id FROM Recipient__c WHERE Envelope__c = :e.Id]));
				} else if (dsId == id2) {
					System.assertEquals('s2', e.EmailSubject__c);
					System.assertEquals('m2', e.EmailMessage__c);
					System.assertEquals(2, Collection.size([SELECT Id FROM Document__c WHERE Envelope__c = :e.Id]));
					System.assertEquals(2, Collection.size([SELECT Id FROM Recipient__c WHERE Envelope__c = :e.Id]));
				} else if (dsId == id3) {
					System.assertEquals('s3', e.EmailSubject__c);
					System.assertEquals('m3', e.EmailMessage__c);
					System.assertEquals(1, Collection.size([SELECT Id FROM Document__c WHERE Envelope__c = :e.Id]));
					System.assertEquals(2, Collection.size([SELECT Id FROM Recipient__c WHERE Envelope__c = :e.Id]));
				}
			}
		}
	}
}
