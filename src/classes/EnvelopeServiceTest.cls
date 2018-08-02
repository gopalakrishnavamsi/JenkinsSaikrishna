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
			new Notifications(true, 1, 1, true, 10, 5, true),
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
			new Notifications(true, 1, 1, true, 10, 5, true),
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
			new Notifications(true, 1, 1, true, 10, 5, true),
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
			new Notifications(true, 1, 1, true, 10, 5, true),
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
			new Notifications(true, -1, 1, true, 10, 5, true),
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
			new Notifications(true, 1, 1, true, 10, 5, true),
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
			System.assertEquals(e.UpdateChatter__c, result.UpdateChatter__c);
			System.assertEquals(e.EmailSubject__c, result.EmailSubject__c);
			System.assertEquals(e.EmailMessage__c, result.EmailMessage__c);
			System.assertEquals(e.SourceId__c, result.SourceId__c);
			System.assertEquals(e.Sent__c, result.Sent__c);
		}
	}

	@IsTest
	static void test_Database_queryEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			Document__c d1 = TestUtils.createEnvelopeDocument(e.Id, 1);
			Document__c d2 = TestUtils.createEnvelopeDocument(e.Id, 2);
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);

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
			System.assertEquals(e.UpdateChatter__c, result.notifications.updateChatter);
			System.assertEquals(e.EmailSubject__c, result.emailSubject);
			System.assertEquals(e.EmailMessage__c, result.emailMessage);
			System.assertNotEquals(null, result.source);
			System.assertEquals(e.SourceId__c, result.source.id);
			System.assertEquals(e.Sent__c, result.sent);
		}
	}

	@IsTest
	static void test_Database_insertEnvelope() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(new Notifications(true, 1, 2, true, 3, 4, true), 'subject', 'message',
				new Entity(a.Id));

			Test.startTest();
			Envelope result = EnvelopeService.DB.insertEnvelope(e);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(e.docuSignId, result.docuSignId);
			System.assertEquals(e.envelopeConfigurationId, result.envelopeConfigurationId);
			System.assertEquals(null, result.documents);
			System.assertEquals(null, result.recipients);
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(e.notifications.remind, result.notifications.remind);
			System.assertEquals(e.notifications.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(e.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(e.notifications.expires, result.notifications.expires);
			System.assertEquals(e.notifications.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(e.notifications.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(e.notifications.updateChatter, result.notifications.updateChatter);
			System.assertEquals(e.emailSubject, result.emailSubject);
			System.assertEquals(e.emailMessage, result.emailMessage);
			System.assertNotEquals(null, result.source);
			System.assertEquals(e.source.id, result.source.id);
			System.assertEquals(e.sent, result.sent);
		}
	}

	@IsTest
	static void test_Database_updateEnvelope2() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c ee = TestUtils.createEnvelope(a.Id);
			ee.Sent__c = null;
			update ee;
			Envelope e = EnvelopeService.DB.convert(ee)
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4, true))
				.withEmail('subject2', 'message2');
			UUID docuSignId = UUID.randomUUID();

			Test.startTest();
			Envelope result1 = EnvelopeService.DB.updateEnvelope2(e, false);
			Envelope result2 = EnvelopeService.DB.updateEnvelope2(e.copy().withId(result1.Id).withDocuSignId(docuSignId), true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.id);
			System.assertEquals(e.docuSignId, result1.docuSignId);
			System.assertEquals(e.envelopeConfigurationId, result1.envelopeConfigurationId);
			System.assert(Collection.isEmpty(result1.documents));
			System.assert(Collection.isEmpty(result1.recipients));
			System.assertNotEquals(null, result1.notifications);
			System.assertEquals(e.notifications.remind, result1.notifications.remind);
			System.assertEquals(e.notifications.remindAfterDays, result1.notifications.remindAfterDays);
			System.assertEquals(e.notifications.remindFrequencyDays, result1.notifications.remindFrequencyDays);
			System.assertEquals(e.notifications.expires, result1.notifications.expires);
			System.assertEquals(e.notifications.expireAfterDays, result1.notifications.expireAfterDays);
			System.assertEquals(e.notifications.expireWarnDays, result1.notifications.expireWarnDays);
			System.assertEquals(e.notifications.updateChatter, result1.notifications.updateChatter);
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			UUID docuSignId = UUID.randomUUID();

			Test.startTest();
			Boolean result = EnvelopeService.DB.updateEnvelopeSent(e.Id, docuSignId, 'subject2', 'message2', true);
			Test.stopTest();

			System.assert(result);

			Envelope__c e2 = [SELECT Id, DocuSignId__c, EmailSubject__c, EmailMessage__c, Sent__c FROM Envelope__c WHERE Id = :e.Id];
			System.assertNotEquals(null, e2);
			System.assertEquals(docuSignId.toString(), e2.DocuSignId__c);
			System.assertEquals('subject2', e2.EmailSubject__c);
			System.assertEquals('message2', e2.EmailMessage__c);
			System.assertNotEquals(null, e2.Sent__c);
		}
	}

	@IsTest
	static void test_Database_deleteEnvelope2() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			Document__c d1 = TestUtils.createEnvelopeDocument(e.Id, 1);
			Document__c d2 = TestUtils.createEnvelopeDocument(e.Id, 2);
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);

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
		System.runAs(TestUtils.createDocuSignUser()) {
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
	static void test_replaceUserTags() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope e = new Envelope(null, '[FirstName][LastName]', '[Email]', null);

			Test.startTest();
			Envelope result = EnvelopeService.replaceUserTags(e);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(UserInfo.getFirstName() + UserInfo.getLastName(), result.emailSubject);
			System.assertEquals(UserInfo.getUserEmail(), result.emailMessage);
		}
	}

	@IsTest
	static void test_saveEnvelope() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
			Envelope result = EnvelopeService.saveEnvelope(e, null);
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
	static void test_addNotifications() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
			Notifications n = new Notifications(true, 1, 2, true, 3, 4, true);

			Test.startTest();
			Envelope result = EnvelopeService.addNotifications(e, n);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(e.documents.size(), result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(e.recipients.size(), result.recipients.size());
			System.assertNotEquals(null, result.customFields);
			System.assertEquals(e.customFields, result.customFields);
			System.assertEquals(n, e.notifications);
		}
	}

	@IsTest
	static void test_addEmail() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
			String es = 'subject2';
			String em = 'message2';

			Test.startTest();
			Envelope result = EnvelopeService.addEmail(e, es, em);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(e.documents.size(), result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(e.recipients.size(), result.recipients.size());
			System.assertNotEquals(null, result.customFields);
			System.assertEquals(e.customFields, result.customFields);
			System.assertEquals(es, e.emailSubject);
			System.assertEquals(em, e.emailMessage);
		}
	}

	@IsTest
	static void test_addFiles() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

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
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();

			Test.startTest();
			Envelope result = EnvelopeService.addFiles(e, new Set<Id> { cv1.Id, cv2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(3, result.documents.size());
			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(cv1.Id, result.documents[1].sourceId);
			System.assertNotEquals(null, result.documents[2]);
			System.assertEquals(cv2.Id, result.documents[2].sourceId);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(e.recipients.size(), result.recipients.size());
			System.assertNotEquals(null, result.customFields);
			System.assertEquals(e.customFields, result.customFields);
		}
	}

	@IsTest
	static void test_addTemplates() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

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
			Envelope result = EnvelopeService.addTemplates(e, new Set<UUID> { UUID.randomUUID(), UUID.randomUUID() });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(3, result.documents.size());
			System.assertNotEquals(null, result.documents[1]);
			System.assertNotEquals(null, result.documents[1].sourceId);
			System.assertNotEquals(null, result.documents[2]);
			System.assertNotEquals(null, result.documents[2].sourceId);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(e.recipients.size(), result.recipients.size());
			System.assertNotEquals(null, result.customFields);
			System.assertEquals(e.customFields, result.customFields);
		}
	}

	@IsTest
	static void test_addSourceDocuments() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

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
	static void test_addRelatedContacts() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a1.Id));
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			EnvelopeConfiguration.RelatedContacts rc1 = new EnvelopeConfiguration.RelatedContacts(
				new Map<String, String> {
					'firstname' => 'FirstName',
					'lastname' => 'LastName',
					'email' => 'Email',
					'role' => 'Phone'
				},
				'Contacts',
				null); // parseErrors

			Test.startTest();
			Envelope result = EnvelopeService.addRelatedContacts(e, new Entity(a1.Id),
				new List<EnvelopeConfiguration.RelatedContacts> { rc1, rc1 },
				new Map<String, Recipient.SigningGroup>());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(4, result.recipients.size()); // 2x2
		}
	}

	@IsTest
	static void test_addSourceRecipients() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id));
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
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
	static void test_addCustomRecipients() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope e = new Envelope(null, 's', 'm', null);
			List<EnvelopeConfiguration.CustomRecipient> crs = new List<EnvelopeConfiguration.CustomRecipient> {
				// Normal signer
				new EnvelopeConfiguration.CustomRecipient('r1@unit.test', 'Recipient', 'One', Recipient.TYPE_SIGNER,
					'r1', 1, '1111', '5551111', 'n1', null, null, false, null),
				// In-person signer, sign now
				new EnvelopeConfiguration.CustomRecipient('r2@unit.test', 'Recipient', 'Two', Recipient.TYPE_IN_PERSON_SIGNER,
					'r2', 2, '2222', '5552222', 'n2', 'Signer One', null, true, null),
				// Signing group
				new EnvelopeConfiguration.CustomRecipient(null, null, null, Recipient.TYPE_SIGNER,
					'r3', 3, '3333', '5553333', 'n3', null, 'sg3', false, null)
			};
			Map<String, Recipient.SigningGroup> sgs = new Map<String, Recipient.SigningGroup> {
				'sg3' => new Recipient.SigningGroup(3333, 'sg3')
			};
			Recipient.EmailSettings es = new Recipient.EmailSettings(
				Localization.NL,
				Localization.getLabel(Localization.NL),
				'nl subject',
				'nl message');

			Test.startTest();
			Envelope result = EnvelopeService.addCustomRecipients(e, crs, sgs, es);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(3, result.recipients.size());
		}
	}

	@IsTest
	static void test_createEnvelope_unauthorized() {
		System.runAs(TestUtils.createUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id))
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', true, false)
				});
			Contact c = TestUtils.createContact(a.Id);
			ContentVersion cv = TestUtils.createContentVersion(a.Id);

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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a = TestUtils.createAccount();
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id))
				.withCustomFields(new List<CustomField> {
					CustomField.newTextField('n1', 'v1', true, false)
				});
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			Contact c3 = TestUtils.createContact(a.Id);
			ContentVersion cv1 = TestUtils.createContentVersion(a.Id);
			ContentVersion cv2 = TestUtils.createContentVersion(a.Id);

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
	static void test_createEnvelope_custom() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a = TestUtils.createAccount();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Envelope e = new Envelope(null, 's', 'm', new Entity(a.Id));
			EnvelopeConfiguration ec = new EnvelopeConfiguration(
				null,
				new Entity(a.Id),
				EnvelopeConfiguration.ClickAction.Send,
				null, // visibility ignored on create envelope
				new Notifications(true, 1, 2, true, 3, 4, true),
				new Recipient.EmailSettings(
					Localization.ZH_CN,
					Localization.getLabel(Localization.ZH_CN),
					'zh-CN subject',
					'zh-CN message'),
				new EnvelopeConfiguration.DocumentSettings(true, true, null, new Set<Id> { cv1.Id }),
				new EnvelopeConfiguration.RecipientSettings(
					new List<EnvelopeConfiguration.RelatedContacts>(),
					new List<EnvelopeConfiguration.CustomRecipient> {
						new EnvelopeConfiguration.CustomRecipient('cr1@unit.test', 'CR', 'One', Recipient.TYPE_SIGNER,
							'Signer 1', 1, null, null, 'n1', null, null, false, null),
						new EnvelopeConfiguration.CustomRecipient('cr2@unit.test', 'CR', 'Two', Recipient.TYPE_SIGNER,
							'Signer 2', 2, null, null, 'n2', null, null, false, null)
					},
					true,
					10,
					true,
					1,
					new List<EnvelopeConfiguration.RecipientRoleType>(),
					new Map<String, String>(),
					new Map<String, EnvelopeConfiguration.RecipientType>(),
					new Map<String, String>()));

			Test.startTest();
			Envelope result = EnvelopeService.createEnvelope(e, ec, false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('zh-CN subject', result.emailSubject);
			System.assertEquals('zh-CN message', result.emailMessage);

			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(cv1.Id, result.documents[0].sourceId);
			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(cv2.Id, result.documents[1].sourceId);

			System.assertNotEquals(null, result.recipients);
			System.assertEquals(3, result.recipients.size());
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals('cr1@unit.test', result.recipients[0].email);
			System.assertNotEquals(null, result.recipients[1]);
			System.assertEquals('cr2@unit.test', result.recipients[1].email);
			System.assertNotEquals(null, result.recipients[2]);
			System.assertEquals(c1.Email, result.recipients[2].email);

			System.assertNotEquals(null, result.notifications);
			System.assert(result.notifications.remind);
			System.assertEquals(1, result.notifications.remindAfterDays);
			System.assertEquals(2, result.notifications.remindFrequencyDays);
			System.assert(result.notifications.expires);
			System.assertEquals(3, result.notifications.expireAfterDays);
			System.assertEquals(4, result.notifications.expireWarnDays);
			System.assert(result.notifications.updateChatter);
		}
	}

	@IsTest
	static void test_getEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Document__c d1 = TestUtils.createEnvelopeDocument(e.Id);
			Document__c d2 = TestUtils.createEnvelopeDocument(e.Id);
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id);

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
	static void test_copyEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeService.copyEnvelope(e.Id);
				throw new AssertException('Expected copyEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_copyEnvelope_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Document__c d1 = TestUtils.createEnvelopeDocument(e.Id);
			Document__c d2 = TestUtils.createEnvelopeDocument(e.Id);
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id);

			Test.startTest();
			Envelope result = EnvelopeService.copyEnvelope(e.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(e.Id, result.id);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(2, result.recipients.size());
		}
	}

	@IsTest
	static void test_updateEnvelopeNotifications_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeService.updateEnvelopeNotifications(EnvelopeService.DB.convert(e));
				throw new AssertException('Expected updateEnvelopeNotifications to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateEnvelopeNotifications_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.Id));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.Id));
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));
			Recipient r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));

			Test.startTest();
			Envelope result = EnvelopeService.updateEnvelopeNotifications(e
				.withDocuments(new List<Document> { d1, d2 })
				.withRecipients(new List<Recipient> { r1, r2 })
				.withEmail('s2', 'm2')
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4, true)));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.documents);
			System.assertEquals(2, result.documents.size());
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(2, result.recipients.size());
			System.assertNotEquals(null, result.notifications);
			System.assert(result.notifications.remind);
			System.assertEquals(1, result.notifications.remindAfterDays);
			System.assertEquals(2, result.notifications.remindFrequencyDays);
			System.assert(result.notifications.expires);
			System.assertEquals(3, result.notifications.expireAfterDays);
			System.assertEquals(4, result.notifications.expireWarnDays);
			System.assert(result.notifications.updateChatter);
			System.assertEquals('s2', result.emailSubject);
			System.assertEquals('m2', result.emailMessage);
		}
	}

	@IsTest
	static void test_updateEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Document d1 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.Id));
			Document d2 = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e.Id));
			Document d3 = d2.copy();
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));
			Recipient r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));
			Recipient r3 = r2.copy();

			Test.startTest();
			Envelope result = EnvelopeService.updateEnvelope(e
				.withDocuments(new List<Document> { d1, d2, d3 })
				.withRecipients(new List<Recipient> { r1, r2, r3 })
				.withEmail('s2', 'm2')
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4, true)));
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
			System.assert(result.notifications.updateChatter);
			System.assertEquals('s2', result.emailSubject);
			System.assertEquals('m2', result.emailMessage);
		}
	}

	@IsTest
	static void test_sendEnvelope_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeService.sendEnvelope(EnvelopeService.DB.convert(e), true, true);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_update_later() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

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
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4, true));
			update new List<Envelope__c> { ee1, ee2 };

			Test.startTest();
			Envelope result1 = EnvelopeService.sendEnvelope(e1, false, false);
			Envelope result2 = EnvelopeService.sendEnvelope(e2, true, false);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result1.docuSignId);
			System.assert(!result1.isSent);
			System.assertNotEquals(null, result1.documents);
			System.assertEquals(1, result1.documents.size());
			System.assertNotEquals(null, result1.recipients);
			System.assertEquals(1, result1.recipients.size());
			List<EnvelopeStatus__c> statuses = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :result1.docusignId.toString()];
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
			System.assert(result2.notifications.updateChatter);
			System.assertEquals('s2', result2.emailSubject);
			System.assertEquals('m2', result2.emailMessage);
			statuses = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :result2.docusignId.toString()];
			System.assert(Collection.isEmpty(statuses));

			Set<Id> ids = new Set<Id> { ee1.Id, ee2.Id };
			for (Envelope__c e : [SELECT DocuSignId__c, Sent__c FROM Envelope__c WHERE Id IN :ids]) {
				System.assertEquals(null, e.DocuSignId__c);
				System.assertEquals(null, e.Sent__c);
			}
		}
	}

	@IsTest
	static void test_sendEnvelope_update_now() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

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
				.withNotifications(new Notifications(true, 1, 2, true, 3, 4, true));

			Test.startTest();
			Envelope result = EnvelopeService.sendEnvelope(e1, true, true);
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
			System.assert(result.notifications.updateChatter);
			System.assertEquals('s2', result.emailSubject);
			System.assertEquals('m2', result.emailMessage);

			Envelope__c e = [SELECT DocuSignId__c, Sent__c FROM Envelope__c WHERE Id = :ee1.Id];
			System.assertNotEquals(null, e.DocuSignId__c);
			System.assertNotEquals(null, e.Sent__c);

			List<EnvelopeStatus__c> statuses = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :result.docusignId.toString()];
			System.assertNotEquals(null, statuses);
			System.assertEquals(1, statuses.size());
		}
	}

	@IsTest
	static void test_markEnvelopeSent_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Contact c = TestUtils.createContact();
			Envelope__c e = TestUtils.createEnvelope(c.Id);
			Document__c d = TestUtils.createEnvelopeDocument(e.Id);
			Recipient__c r = TestUtils.createEnvelopeRecipient(e.Id);

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
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				EnvelopeService.getEmptyEnvelope(null);
				throw new AssertException('Expected getEmptyEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEmptyEnvelope_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			EnvelopeSettings__c s = EnvelopeSettings__c.getOrgDefaults();
			s.RemindAfterDays__c = 1;
			s.RemindFrequencyDays__c = 2;
			s.ExpireAfterDays__c = 3;
			s.ExpireWarnDays__c = 4;
			s.Chatter__c = EnvelopeSettings.CHATTER_ENABLED_DEFAULT_ON;
			insert s;
			Lead l = TestUtils.createLead();

			Test.startTest();
			Envelope result = EnvelopeService.getEmptyEnvelope(new Entity(l.Id));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.notifications);
			System.assert(result.notifications.remind);
			System.assertEquals(1, result.notifications.remindAfterDays);
			System.assertEquals(2, result.notifications.remindFrequencyDays);
			System.assert(result.notifications.expires);
			System.assertEquals(3, result.notifications.expireAfterDays);
			System.assertEquals(4, result.notifications.expireWarnDays);
			System.assert(result.notifications.updateChatter);
			Recipient.EmailSettings es = Localization.getEmailSettingsForCurrentLanguage();
			System.assertEquals(es.subject, result.emailSubject);
			System.assertEquals(es.message, result.emailMessage);
			System.assertNotEquals(null, result.source);
			System.assertEquals(l.Id, result.source.id);
		}
	}

	static testMethod void test_applyRecipientLimit() {
		Envelope e = new Envelope(null, null, null, null);
		Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', null, null, null);
		Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', null, null, null);
		List<Recipient> rs = new List<Recipient> { r1, r2 };

		Test.startTest();
		Envelope result1 = EnvelopeService.applyRecipientLimit(null, null); // null
		Envelope result2 = EnvelopeService.applyRecipientLimit(e.copy().withRecipients(null), null); // null
		Envelope result3 = EnvelopeService.applyRecipientLimit(e.copy().withRecipients(rs), null); // { r1, r2  }
		Envelope result4 = EnvelopeService.applyRecipientLimit(e.copy().withRecipients(rs), -1); // { r1, r2  }
		Envelope result5 = EnvelopeService.applyRecipientLimit(e.copy().withRecipients(rs), 0); // { r1, r2  }
		Envelope result6 = EnvelopeService.applyRecipientLimit(e.copy().withRecipients(rs), 1); // { r1 }
		Envelope result7 = EnvelopeService.applyRecipientLimit(e.copy().withRecipients(rs), 2); // { r1, r2  }
		Test.stopTest();

		System.assertEquals(null, result1);

		System.assertNotEquals(null, result2);
		System.assert(Collection.isEmpty(result2.recipients));

		System.assertNotEquals(null, result3);
		System.assertNotEquals(null, result3.recipients);
		System.assertEquals(2, result3.recipients.size());

		System.assertNotEquals(null, result4);
		System.assertNotEquals(null, result4.recipients);
		System.assertEquals(2, result4.recipients.size());

		System.assertNotEquals(null, result5);
		System.assertNotEquals(null, result5.recipients);
		System.assertEquals(2, result5.recipients.size());

		System.assertNotEquals(null, result6);
		System.assertNotEquals(null, result6.recipients);
		System.assertEquals(1, result6.recipients.size());

		System.assertNotEquals(null, result7);
		System.assertNotEquals(null, result7.recipients);
		System.assertEquals(2, result7.recipients.size());
	}

	@IsTest
	static void test_getSenderViewUrl_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e = TestUtils.createEnvelope();

			Test.startTest();
			Url result = EnvelopeService.getSenderViewUrl(UUID.parse(e.DocuSignId__c),
				new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}
}
