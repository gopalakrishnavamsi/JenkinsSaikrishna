@IsTest
private class StatusServiceTest {

	private static final UUID ID1 = UUID.parse('11111111-1111-1111-1111-111111111111');
	private static final UUID ID2 = UUID.parse('22222222-2222-2222-2222-222222222222');
	private static final UUID ID3 = UUID.parse('33333333-3333-3333-3333-333333333333');
	private static final UUID ID4 = UUID.parse('44444444-4444-4444-4444-444444444444');

	@IsTest
	static void test_validate() {
		// Valid
		Envelope.Status es1 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.randomUUID(),
			Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, Datetime.now().addDays(-1),
			null, Datetime.now(), 's1', null, Datetime.now());
		// Invalid - no DocuSign ID
		Envelope.Status es2 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), null,
			Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, Datetime.now().addDays(-1),
			Datetime.now().addDays(1), Datetime.now(), 's1', null, Datetime.now());
		// Invalid - not created/sent
		Envelope.Status es3 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.randomUUID(),
			Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, null, null,
			null, 's1', null, Datetime.now());

		Test.startTest();
		ValidationResult result1 = StatusService.validate(null);
		ValidationResult result2 = StatusService.validate(new List<Envelope.Status>());
		ValidationResult result3 = StatusService.validate(new List<Envelope.Status> { es1, es2 });
		ValidationResult result4 = StatusService.validate(new List<Envelope.Status> { es1, es3 });
		ValidationResult result5 = StatusService.validate(new List<Envelope.Status> { es1 });
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(Label.AtLeastOneEnvelopeIsRequired, result1.toString());

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(Label.AtLeastOneEnvelopeIsRequired, result2.toString());

		System.assertNotEquals(null, result3);
		System.assert(!result3.isValid);
		System.assertEquals(Label.EnvelopesMustBeSent, result3.toString());

		System.assertNotEquals(null, result4);
		System.assert(!result4.isValid);
		System.assertEquals(Label.EnvelopesMustBeSent, result4.toString());

		System.assertNotEquals(null, result5);
		System.assert(result5.isValid);
	}

	@IsTest
	static void test_Database_convert_EnvelopeStatus() {
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(TestUtils.createEnvelope());
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(TestUtils.createEnvelope());

			Test.startTest();
			List<Envelope.Status> result = StatusService.DB.convert(new List<EnvelopeStatus__c> { es1, es2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Envelope.Status es = result[0];
			System.assertNotEquals(null, es);
			System.assertEquals(es1.Id, es.id);
			System.assertEquals(es1.DocuSignId__c, String.valueOf(es.docuSignId));
			System.assertEquals(es1.SourceId__c, es.source == null ? null : es.source.id);
			System.assertEquals(es1.Status__c, es.status);
			System.assertEquals(es1.SenderName__c, es.senderName);
			System.assertEquals(es1.SenderEmail__c, es.senderEmail);
			System.assertEquals(es1.Sent__c, es.sent);
			System.assertEquals(es1.Expires__c, es.expires);
			System.assertEquals(es1.Completed__c, es.completed);
			System.assertEquals(es1.Reason__c, es.reason);
			System.assertEquals(es1.LastStatusUpdate__c, es.lastStatusUpdate);

			es = result[1];
			System.assertNotEquals(null, es);
			System.assertEquals(es2.Id, es.id);
			System.assertEquals(es2.DocuSignId__c, String.valueOf(es.docuSignId));
			System.assertEquals(es2.SourceId__c, es.source == null ? null : es.source.id);
			System.assertEquals(es2.Status__c, es.status);
			System.assertEquals(es2.SenderName__c, es.senderName);
			System.assertEquals(es2.SenderEmail__c, es.senderEmail);
			System.assertEquals(es2.Sent__c, es.sent);
			System.assertEquals(es1.Expires__c, es.expires);
			System.assertEquals(es2.Completed__c, es.completed);
			System.assertEquals(es2.Reason__c, es.reason);
			System.assertEquals(es2.LastStatusUpdate__c, es.lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_convert_RecipientStatus() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			RecipientStatus__c rs1 = TestUtils.createRecipientStatus(es1.Id, TestUtils.createEnvelopeRecipient(e1.Id));
			RecipientStatus__c rs2 = TestUtils.createRecipientStatus(es1.Id, TestUtils.createEnvelopeRecipient(e1.Id));

			Test.startTest();
			List<Recipient.Status> result = StatusService.DB.convert(new List<RecipientStatus__c> { rs1, rs2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Recipient.Status rs = result[0];
			System.assertNotEquals(null, rs);
			System.assertEquals(rs1.Id, rs.id);
			System.assertEquals(rs1.SourceId__c, rs.source == null ? null : rs.source.id);
			System.assertEquals(rs1.Type__c, rs.type);
			System.assertEquals(rs1.Sequence__c, rs.sequence);
			System.assertEquals(rs1.Status__c, rs.status);
			System.assertEquals(rs1.Name, rs.name);
			System.assertEquals(rs1.Email__c, rs.email);
			System.assertEquals(rs1.RoutingOrder__c, rs.routingOrder);
			System.assertEquals(rs1.Sent__c, rs.sent);
			System.assertEquals(rs1.Completed__c, rs.completed);
			System.assertEquals(rs1.Reason__c, rs.reason);
			System.assertEquals(rs1.LastStatusUpdate__c, rs.lastStatusUpdate);

			rs = result[1];
			System.assertNotEquals(null, rs);
			System.assertEquals(rs2.Id, rs.id);
			System.assertEquals(rs2.SourceId__c, rs.source == null ? null : rs.source.id);
			System.assertEquals(rs2.Type__c, rs.type);
			System.assertEquals(rs2.Sequence__c, rs.sequence);
			System.assertEquals(rs2.Status__c, rs.status);
			System.assertEquals(rs2.Name, rs.name);
			System.assertEquals(rs2.Email__c, rs.email);
			System.assertEquals(rs2.RoutingOrder__c, rs.routingOrder);
			System.assertEquals(rs2.Sent__c, rs.sent);
			System.assertEquals(rs2.Completed__c, rs.completed);
			System.assertEquals(rs2.Reason__c, rs.reason);
			System.assertEquals(rs2.LastStatusUpdate__c, rs.lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_querySourceEnvelopes() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Lead l = TestUtils.createLead();
			UUID e1Id = UUID.randomUUID();
			TestUtils.createEnvelope(a.Id, e1Id);
			UUID e2Id = UUID.randomUUID();
			TestUtils.createEnvelope(a.Id, e2Id);
			UUID e3Id = UUID.randomUUID();
			TestUtils.createEnvelope(l.Id, e3Id);
			UUID e4Id = UUID.randomUUID();
			TestUtils.createEnvelope(l.Id, e4Id);
			Set<UUID> validIds = new Set<UUID> { e1Id, e2Id, e3Id, e4Id };

			Test.startTest();
			Set<UUID> result = StatusService.DB.querySourceEnvelopes(new Set<Id> { a.Id, l.Id }, 3);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			Set<UUID> usedIds = new Set<UUID>();
			for (UUID id : result) {
				System.assertNotEquals(null, id);
				System.assert(validIds.contains(id));
				System.assert(!usedIds.contains(id));
				usedIds.add(id);
			}
		}
	}

	@IsTest
	static void test_Database_queryStatus_by_envelope_id() {
		System.runAs(UserMock.createDocuSignUser()) {
			UUID e1Id = UUID.randomUUID();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1Id);
			RecipientStatus__c es1rs1 = TestUtils.createRecipientStatus(es1.Id, 1);
			RecipientStatus__c es1rs2 = TestUtils.createRecipientStatus(es1.Id, 2);
			UUID e2Id = UUID.randomUUID();
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(e2Id);
			RecipientStatus__c es2rs1 = TestUtils.createRecipientStatus(es2.Id, 1);
			RecipientStatus__c es2rs2 = TestUtils.createRecipientStatus(es2.Id, 2);

			Test.startTest();
			List<Envelope.Status> result = StatusService.DB.queryStatus(new Set<UUID> { e1Id, e2Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Envelope.Status es = result[0];
			System.assertEquals(es1.Id, es.id);
			System.assertEquals(es1.DocuSignId__c, String.valueOf(es.docuSignId));
			System.assertEquals(es1.SourceId__c, es.source == null ? null : es.source.id);
			System.assertEquals(es1.Status__c, es.status);
			System.assertEquals(es1.SenderName__c, es.senderName);
			System.assertEquals(es1.SenderEmail__c, es.senderEmail);
			System.assertEquals(es1.Sent__c, es.sent);
			System.assertEquals(es1.Expires__c, es.expires);
			System.assertEquals(es1.Completed__c, es.completed);
			System.assertEquals(es1.Reason__c, es.reason);
			System.assertEquals(es1.LastStatusUpdate__c, es.lastStatusUpdate);
			System.assertNotEquals(null, es.recipients);
			System.assertEquals(2, es.recipients.size());

			Recipient.Status rs = es.recipients[0];
			System.assertNotEquals(null, rs);
			System.assertEquals(es1rs1.Id, rs.id);
			System.assertEquals(es1rs1.SourceId__c, rs.source == null ? null : rs.source.id);
			System.assertEquals(es1rs1.Type__c, rs.type);
			System.assertEquals(es1rs1.Sequence__c, rs.sequence);
			System.assertEquals(es1rs1.Status__c, rs.status);
			System.assertEquals(es1rs1.Name, rs.name);
			System.assertEquals(es1rs1.Email__c, rs.email);
			System.assertEquals(es1rs1.RoutingOrder__c, rs.routingOrder);
			System.assertEquals(es1rs1.Sent__c, rs.sent);
			System.assertEquals(es1rs1.Completed__c, rs.completed);
			System.assertEquals(es1rs1.Reason__c, rs.reason);
			System.assertEquals(es1rs1.LastStatusUpdate__c, rs.lastStatusUpdate);

			rs = es.recipients[1];
			System.assertNotEquals(null, rs);
			System.assertEquals(es1rs2.Id, rs.id);
			System.assertEquals(es1rs2.SourceId__c, rs.source == null ? null : rs.source.id);
			System.assertEquals(es1rs2.Type__c, rs.type);
			System.assertEquals(es1rs2.Sequence__c, rs.sequence);
			System.assertEquals(es1rs2.Status__c, rs.status);
			System.assertEquals(es1rs2.Name, rs.name);
			System.assertEquals(es1rs2.Email__c, rs.email);
			System.assertEquals(es1rs2.RoutingOrder__c, rs.routingOrder);
			System.assertEquals(es1rs2.Sent__c, rs.sent);
			System.assertEquals(es1rs2.Completed__c, rs.completed);
			System.assertEquals(es1rs2.Reason__c, rs.reason);
			System.assertEquals(es1rs2.LastStatusUpdate__c, rs.lastStatusUpdate);

			es = result[1];
			System.assertNotEquals(null, es);
			System.assertEquals(es2.Id, es.id);
			System.assertEquals(es2.DocuSignId__c, String.valueOf(es.docuSignId));
			System.assertEquals(es2.SourceId__c, es.source == null ? null : es.source.id);
			System.assertEquals(es2.Status__c, es.status);
			System.assertEquals(es2.SenderName__c, es.senderName);
			System.assertEquals(es2.SenderEmail__c, es.senderEmail);
			System.assertEquals(es2.Sent__c, es.sent);
			System.assertEquals(es2.Expires__c, es.expires);
			System.assertEquals(es2.Completed__c, es.completed);
			System.assertEquals(es2.Reason__c, es.reason);
			System.assertEquals(es2.LastStatusUpdate__c, es.lastStatusUpdate);
			System.assertNotEquals(null, es.recipients);
			System.assertEquals(2, es.recipients.size());

			rs = es.recipients[0];
			System.assertNotEquals(null, rs);
			System.assertEquals(es2rs1.Id, rs.id);
			System.assertEquals(es2rs1.SourceId__c, rs.source == null ? null : rs.source.id);
			System.assertEquals(es2rs1.Type__c, rs.type);
			System.assertEquals(es2rs1.Sequence__c, rs.sequence);
			System.assertEquals(es2rs1.Status__c, rs.status);
			System.assertEquals(es2rs1.Name, rs.name);
			System.assertEquals(es2rs1.Email__c, rs.email);
			System.assertEquals(es2rs1.RoutingOrder__c, rs.routingOrder);
			System.assertEquals(es2rs1.Sent__c, rs.sent);
			System.assertEquals(es2rs1.Completed__c, rs.completed);
			System.assertEquals(es2rs1.Reason__c, rs.reason);
			System.assertEquals(es2rs1.LastStatusUpdate__c, rs.lastStatusUpdate);

			rs = es.recipients[1];
			System.assertNotEquals(null, rs);
			System.assertEquals(es2rs2.Id, rs.id);
			System.assertEquals(es2rs2.SourceId__c, rs.source == null ? null : rs.source.id);
			System.assertEquals(es2rs2.Type__c, rs.type);
			System.assertEquals(es2rs2.Sequence__c, rs.sequence);
			System.assertEquals(es2rs2.Status__c, rs.status);
			System.assertEquals(es2rs2.Name, rs.name);
			System.assertEquals(es2rs2.Email__c, rs.email);
			System.assertEquals(es2rs2.RoutingOrder__c, rs.routingOrder);
			System.assertEquals(es2rs2.Sent__c, rs.sent);
			System.assertEquals(es2rs2.Completed__c, rs.completed);
			System.assertEquals(es2rs2.Reason__c, rs.reason);
			System.assertEquals(es2rs2.LastStatusUpdate__c, rs.lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_insertStatus_null_docuSignId() {
		System.runAs(UserMock.createDocuSignUser()) {
			Datetime now = Datetime.now();
			Envelope.Status es = new Envelope.Status(null, null, null,
				Envelope.STATUS_COMPLETED, 'e1', 'e1@unit.test', new List<Recipient.Status>(),
				now.addDays(-10), now.addDays(-1), now.addDays(-2), 'e1', null, now.addDays(-1));

			Test.startTest();
			try {
				StatusService.DB.insertStatus(new List<Envelope.Status> { es });
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedDocuSignEnvelopeId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_insertStatus() {
		System.runAs(UserMock.createDocuSignUser()) {
			Datetime now = Datetime.now();
			Schema.Account a1 = TestUtils.createAccount();
			Contact a1c1 = TestUtils.createContact(a1.Id);
			Contact a1c2 = TestUtils.createContact(a1.Id);
			Recipient.Status e1r1 = new Recipient.Status(null, new Entity(a1c1.Id), Recipient.TYPE_SIGNER, 1,
				Recipient.STATUS_COMPLETED, 'e1r1', 'e1r2@unit.test', 1, now.addDays(-10), now.addDays(-2),
				null, now.addDays(-2));
			Recipient.Status e1r2 = new Recipient.Status(null, new Entity(a1c2.Id), Recipient.TYPE_CARBON_COPY, 2,
				Recipient.STATUS_COMPLETED, 'e1r2', 'e1r2@unit.test', 1, now.addDays(-10), now.addDays(-2),
				null, now.addDays(-2));
			Envelope.Status e1 = new Envelope.Status(null, new Entity(a1.Id), UUID.randomUUID(),
				Envelope.STATUS_COMPLETED, 'e1', 'e1@unit.test', new List<Recipient.Status> { e1r1, e1r2 }, now.addDays(-10),
				now.addDays(-1), now.addDays(-2), 'e1', null, now.addDays(-1));
			Schema.Account a2 = TestUtils.createAccount();
			Contact a2c1 = TestUtils.createContact(a2.Id);
			Contact a2c2 = TestUtils.createContact(a2.Id);
			Recipient.Status e2r1 = new Recipient.Status(null, new Entity(a2c1.Id), Recipient.TYPE_SIGNER, 1,
				Recipient.STATUS_COMPLETED, 'e2r1', 'e2r1@unit.test', 1, now.addDays(-4), now.addDays(-3),
				null, now.addDays(-3));
			Recipient.Status e2r2 = new Recipient.Status(null, new Entity(a2c2.Id), Recipient.TYPE_IN_PERSON_SIGNER, 2,
				Recipient.STATUS_DECLINED, 'e2r2', 'e2r2@unit.test', 1, now.addDays(-2), now.addDays(-2),
				'decline reason', now.addDays(-2));
			Envelope.Status e2 = new Envelope.Status(null, new Entity(a2.Id), UUID.randomUUID(),
				Envelope.STATUS_DECLINED, 'e2', 'e2@unit.test', new List<Recipient.Status> { e2r1, e2r2 }, now.addDays(-4),
				now.addDays(-1), now.addDays(-2), 'e2', null, now.addDays(-2));

			Test.startTest();
			List<Envelope.Status> result = StatusService.DB.insertStatus(new List<Envelope.Status> { e1, e2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Envelope.Status es = result[0];
			System.assertNotEquals(null, es.id);
			System.assertEquals(e1.docuSignId, es.docuSignId);
			System.assertEquals(e1.source, es.source);
			System.assertEquals(e1.status, es.status);
			System.assertEquals(e1.senderName, es.senderName);
			System.assertEquals(e1.senderEmail, es.senderEmail);
			System.assertEquals(e1.sent, es.sent);
			System.assertEquals(e1.expires, es.expires);
			System.assertEquals(e1.completed, es.completed);
			System.assertEquals(e1.reason, es.reason);
			System.assertEquals(e1.lastStatusUpdate, es.lastStatusUpdate);
			System.assertNotEquals(null, es.recipients);
			System.assertEquals(2, es.recipients.size());

			Recipient.Status rs = es.recipients[0];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e1r1.source, rs.source);
			System.assertEquals(e1r1.type, rs.type);
			System.assertEquals(e1r1.sequence, rs.sequence);
			System.assertEquals(e1r1.status, rs.status);
			System.assertEquals(e1r1.name, rs.name);
			System.assertEquals(e1r1.email, rs.email);
			System.assertEquals(e1r1.routingOrder, rs.routingOrder);
			System.assertEquals(e1r1.sent, rs.sent);
			System.assertEquals(e1r1.completed, rs.completed);
			System.assertEquals(e1r1.reason, rs.reason);
			System.assertEquals(e1r1.lastStatusUpdate, rs.lastStatusUpdate);

			rs = es.recipients[1];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e1r2.source, rs.source);
			System.assertEquals(e1r2.type, rs.type);
			System.assertEquals(e1r2.sequence, rs.sequence);
			System.assertEquals(e1r2.status, rs.status);
			System.assertEquals(e1r2.name, rs.name);
			System.assertEquals(e1r2.email, rs.email);
			System.assertEquals(e1r2.routingOrder, rs.routingOrder);
			System.assertEquals(e1r2.sent, rs.sent);
			System.assertEquals(e1r2.completed, rs.completed);
			System.assertEquals(e1r2.reason, rs.reason);
			System.assertEquals(e1r2.lastStatusUpdate, rs.lastStatusUpdate);

			es = result[1];
			System.assertNotEquals(null, es.id);
			System.assertEquals(e2.docuSignId, es.docuSignId);
			System.assertEquals(e2.source, es.source);
			System.assertEquals(e2.status, es.status);
			System.assertEquals(e2.senderName, es.senderName);
			System.assertEquals(e2.senderEmail, es.senderEmail);
			System.assertEquals(e2.sent, es.sent);
			System.assertEquals(e2.expires, es.expires);
			System.assertEquals(e2.completed, es.completed);
			System.assertEquals(e2.reason, es.reason);
			System.assertEquals(e2.lastStatusUpdate, es.lastStatusUpdate);
			System.assertNotEquals(null, es.recipients);
			System.assertEquals(2, es.recipients.size());

			rs = es.recipients[0];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e2r1.source, rs.source);
			System.assertEquals(e2r1.type, rs.type);
			System.assertEquals(e2r1.sequence, rs.sequence);
			System.assertEquals(e2r1.status, rs.status);
			System.assertEquals(e2r1.name, rs.name);
			System.assertEquals(e2r1.email, rs.email);
			System.assertEquals(e2r1.routingOrder, rs.routingOrder);
			System.assertEquals(e2r1.sent, rs.sent);
			System.assertEquals(e2r1.completed, rs.completed);
			System.assertEquals(e2r1.reason, rs.reason);
			System.assertEquals(e2r1.lastStatusUpdate, rs.lastStatusUpdate);

			rs = es.recipients[1];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e2r2.source, rs.source);
			System.assertEquals(e2r2.type, rs.type);
			System.assertEquals(e2r2.sequence, rs.sequence);
			System.assertEquals(e2r2.status, rs.status);
			System.assertEquals(e2r2.name, rs.name);
			System.assertEquals(e2r2.email, rs.email);
			System.assertEquals(e2r2.routingOrder, rs.routingOrder);
			System.assertEquals(e2r2.sent, rs.sent);
			System.assertEquals(e2r2.completed, rs.completed);
			System.assertEquals(e2r2.reason, rs.reason);
			System.assertEquals(e2r2.lastStatusUpdate, rs.lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_upsertStatus() {
		System.runAs(UserMock.createDocuSignUser()) {
			Datetime now = Datetime.now();
			Envelope.Status e1 = StatusService.DB.convert(TestUtils.createEnvelopeStatus());
			Recipient.Status e1r1 = StatusService.DB.convert(TestUtils.createRecipientStatus(e1.id, 1));
			Recipient.Status e1r2 = StatusService.DB.convert(TestUtils.createRecipientStatus(e1.id, 2));
			e1.addRecipients(new List<Recipient.Status> { e1r1, e1r2 });

			Schema.Account a2 = TestUtils.createAccount();
			Contact a2c1 = TestUtils.createContact(a2.Id);
			Contact a2c2 = TestUtils.createContact(a2.Id);
			Recipient.Status e2r1 = new Recipient.Status(null, new Entity(a2c1.Id), Recipient.TYPE_SIGNER, 1,
				Recipient.STATUS_COMPLETED, 'e2r1', 'e2r1@unit.test', 1, now.addDays(-4), now.addDays(-3),
				null, now.addDays(-3));
			Recipient.Status e2r2 = new Recipient.Status(null, new Entity(a2c2.Id), Recipient.TYPE_IN_PERSON_SIGNER, 2,
				Recipient.STATUS_DECLINED, 'e2r2', 'e2r2@unit.test', 1, now.addDays(-2), now.addDays(-2),
				'decline reason', now.addDays(-2));
			Envelope.Status e2 = new Envelope.Status(null, new Entity(a2.Id), UUID.randomUUID(),
				Envelope.STATUS_DECLINED, 'e2', 'e2@unit.test', new List<Recipient.Status> { e2r1, e2r2 }, now.addDays(-4),
				now.addDays(-1), now.addDays(-2), 'e2', null, now.addDays(-2));

			Test.startTest();
			List<Envelope.Status> result = StatusService.DB.upsertStatus(new List<Envelope.Status> { e1, e2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Envelope.Status es = result[0];
			System.assertEquals(e1.id, es.id);
			System.assertEquals(e1.docuSignId, es.docuSignId);
			System.assertEquals(e1.source, es.source);
			System.assertEquals(e1.status, es.status);
			System.assertEquals(e1.senderName, es.senderName);
			System.assertEquals(e1.senderEmail, es.senderEmail);
			System.assertEquals(e1.sent, es.sent);
			System.assertEquals(e1.expires, es.expires);
			System.assertEquals(e1.completed, es.completed);
			System.assertEquals(e1.reason, es.reason);
			System.assertNotEquals(null, es.lastStatusUpdate);
			System.assertNotEquals(null, es.recipients);
			System.assertEquals(2, es.recipients.size());

			Recipient.Status rs = es.recipients[0];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e1r1.source, rs.source);
			System.assertEquals(e1r1.type, rs.type);
			System.assertEquals(e1r1.sequence, rs.sequence);
			System.assertEquals(e1r1.status, rs.status);
			System.assertEquals(e1r1.name, rs.name);
			System.assertEquals(e1r1.email, rs.email);
			System.assertEquals(e1r1.routingOrder, rs.routingOrder);
			System.assertEquals(e1r1.sent, rs.sent);
			System.assertEquals(e1r1.completed, rs.completed);
			System.assertEquals(e1r1.reason, rs.reason);
			System.assertNotEquals(null, rs.lastStatusUpdate);

			rs = es.recipients[1];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e1r2.source, rs.source);
			System.assertEquals(e1r2.type, rs.type);
			System.assertEquals(e1r2.sequence, rs.sequence);
			System.assertEquals(e1r2.status, rs.status);
			System.assertEquals(e1r2.name, rs.name);
			System.assertEquals(e1r2.email, rs.email);
			System.assertEquals(e1r2.routingOrder, rs.routingOrder);
			System.assertEquals(e1r2.sent, rs.sent);
			System.assertEquals(e1r2.completed, rs.completed);
			System.assertEquals(e1r2.reason, rs.reason);
			System.assertNotEquals(null, rs.lastStatusUpdate);

			es = result[1];
			System.assertNotEquals(null, es.id);
			System.assertEquals(e2.docuSignId, es.docuSignId);
			System.assertEquals(e2.source, es.source);
			System.assertEquals(e2.status, es.status);
			System.assertEquals(e2.senderName, es.senderName);
			System.assertEquals(e2.senderEmail, es.senderEmail);
			System.assertEquals(e2.sent, es.sent);
			System.assertEquals(e2.expires, es.expires);
			System.assertEquals(e2.completed, es.completed);
			System.assertEquals(e2.reason, es.reason);
			System.assertNotEquals(null, es.lastStatusUpdate);
			System.assertNotEquals(null, es.recipients);
			System.assertEquals(2, es.recipients.size());

			rs = es.recipients[0];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e2r1.source, rs.source);
			System.assertEquals(e2r1.type, rs.type);
			System.assertEquals(e2r1.sequence, rs.sequence);
			System.assertEquals(e2r1.status, rs.status);
			System.assertEquals(e2r1.name, rs.name);
			System.assertEquals(e2r1.email, rs.email);
			System.assertEquals(e2r1.routingOrder, rs.routingOrder);
			System.assertEquals(e2r1.sent, rs.sent);
			System.assertEquals(e2r1.completed, rs.completed);
			System.assertEquals(e2r1.reason, rs.reason);
			System.assertNotEquals(null, rs.lastStatusUpdate);

			rs = es.recipients[1];
			System.assertNotEquals(null, rs);
			System.assertNotEquals(null, rs.id);
			System.assertEquals(e2r2.source, rs.source);
			System.assertEquals(e2r2.type, rs.type);
			System.assertEquals(e2r2.sequence, rs.sequence);
			System.assertEquals(e2r2.status, rs.status);
			System.assertEquals(e2r2.name, rs.name);
			System.assertEquals(e2r2.email, rs.email);
			System.assertEquals(e2r2.routingOrder, rs.routingOrder);
			System.assertEquals(e2r2.sent, rs.sent);
			System.assertEquals(e2r2.completed, rs.completed);
			System.assertEquals(e2r2.reason, rs.reason);
			System.assertNotEquals(null, rs.lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_deleteStatus_without_envelopes() {
		System.runAs(UserMock.createDocuSignUser()) {
			UUID e1Id = UUID.randomUUID();
			Envelope__c ee1 = TestUtils.createEnvelope(e1Id);
			TestUtils.createEnvelopeDocument(ee1.Id);
			TestUtils.createEnvelopeRecipient(ee1.Id);
			EnvelopeStatus__c e1 = TestUtils.createEnvelopeStatus(e1Id);
			RecipientStatus__c e1r1 = TestUtils.createRecipientStatus(e1.Id, 1);
			RecipientStatus__c e1r2 = TestUtils.createRecipientStatus(e1.Id, 2);
			UUID e2Id = UUID.randomUUID();
			Envelope__c ee2 = TestUtils.createEnvelope(e2Id);
			TestUtils.createEnvelopeDocument(ee2.Id);
			TestUtils.createEnvelopeRecipient(ee2.Id);
			EnvelopeStatus__c e2 = TestUtils.createEnvelopeStatus(e2Id);
			RecipientStatus__c e2r1 = TestUtils.createRecipientStatus(e2.Id, 1);
			RecipientStatus__c e2r2 = TestUtils.createRecipientStatus(e2.Id, 2);

			Test.startTest();
			Boolean result = StatusService.DB.deleteStatus(new Set<UUID> { e1Id, e2Id }, false);
			Test.stopTest();

			System.assert(result);

			Set<Id> essIds = new Set<Id> { e1.Id, e2.Id };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE Id IN :essIds];
			System.assert(Collection.isEmpty(ess));

			Set<Id> rssIds = new Set<Id> { e1r1.Id, e1r2.Id, e2r1.Id, e2r2.Id };
			List<RecipientStatus__c> rss = [SELECT Id FROM RecipientStatus__c WHERE Id IN :rssIds];
			System.assert(Collection.isEmpty(rss));

			// Delete envelope records as well.
			Set<Id> eIds = new Set<Id> { ee1.Id, ee2.Id };
			List<Envelope__c> es = [SELECT Id FROM Envelope__c WHERE Id IN :eIds];
			System.assertEquals(2, Collection.size(es));
		}
	}

	@IsTest
	static void test_Database_deleteStatus_with_envelopes() {
		System.runAs(UserMock.createDocuSignUser()) {
			UUID e1Id = UUID.randomUUID();
			Envelope__c ee1 = TestUtils.createEnvelope(e1Id);
			TestUtils.createEnvelopeDocument(ee1.Id);
			TestUtils.createEnvelopeRecipient(ee1.Id);
			EnvelopeStatus__c e1 = TestUtils.createEnvelopeStatus(e1Id);
			RecipientStatus__c e1r1 = TestUtils.createRecipientStatus(e1.Id, 1);
			RecipientStatus__c e1r2 = TestUtils.createRecipientStatus(e1.Id, 2);
			UUID e2Id = UUID.randomUUID();
			Envelope__c ee2 = TestUtils.createEnvelope(e2Id);
			TestUtils.createEnvelopeDocument(ee2.Id);
			TestUtils.createEnvelopeRecipient(ee2.Id);
			EnvelopeStatus__c e2 = TestUtils.createEnvelopeStatus(e2Id);
			RecipientStatus__c e2r1 = TestUtils.createRecipientStatus(e2.Id, 1);
			RecipientStatus__c e2r2 = TestUtils.createRecipientStatus(e2.Id, 2);

			Test.startTest();
			Boolean result = StatusService.DB.deleteStatus(new Set<UUID> { e1Id, e2Id }, true);
			Test.stopTest();

			System.assert(result);

			Set<Id> essIds = new Set<Id> { e1.Id, e2.Id };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE Id IN :essIds];
			System.assert(Collection.isEmpty(ess));

			Set<Id> rssIds = new Set<Id> { e1r1.Id, e1r2.Id, e2r1.Id, e2r2.Id };
			List<RecipientStatus__c> rss = [SELECT Id FROM RecipientStatus__c WHERE Id IN :rssIds];
			System.assert(Collection.isEmpty(rss));

			// Delete envelope records as well.
			Set<Id> eIds = new Set<Id> { ee1.Id, ee2.Id };
			List<Envelope__c> es = [SELECT Id FROM Envelope__c WHERE Id IN :eIds];
			System.assert(Collection.isEmpty(es));
		}
	}

	@IsTest
	static void test_Database_updateStatus() {
		System.runAs(UserMock.createDocuSignUser()) {
			UUID dseId1 = UUID.randomUUID();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			RecipientStatus__c es1rs1 = TestUtils.createRecipientStatus(es1.Id, 1);
			es1rs1.Status__c = Recipient.STATUS_COMPLETED;
			es1rs1.Completed__c = Datetime.now();
			es1rs1.LastStatusUpdate__c = Datetime.now();
			RecipientStatus__c es1rs2 = TestUtils.createRecipientStatus(es1.Id, 2);
			es1rs2.Status__c = Recipient.STATUS_CREATED;
			es1rs2.Completed__c = null;
			es1rs2.LastStatusUpdate__c = null;
			UUID dseId2 = UUID.randomUUID();
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(dseId2);
			RecipientStatus__c es2rs1 = TestUtils.createRecipientStatus(es2.Id, 1);
			es2rs1.Status__c = Recipient.STATUS_CREATED;
			es2rs1.Completed__c = null;
			es2rs1.LastStatusUpdate__c = null;
			RecipientStatus__c es2rs2 = TestUtils.createRecipientStatus(es1.Id, 2);
			es2rs2.Status__c = Recipient.STATUS_SIGNED;
			es2rs2.Completed__c = Datetime.now();
			es2rs1.LastStatusUpdate__c = Datetime.now();
			update new List<RecipientStatus__c> { es1rs1, es1rs2, es2rs1, es2rs2 };

			Test.startTest();
			Boolean result = StatusService.DB.updateStatus(new Set<UUID> { dseId1, dseId2 }, Envelope.STATUS_DECLINED, 'decline reason');
			Test.stopTest();

			System.assert(result);
			Set<String> ids = new Set<String> { es1.DocuSignId__c, es2.DocuSignId__c };
			List<EnvelopeStatus__c> ess = [
				SELECT
					Status__c, Reason__c, Completed__c, LastStatusUpdate__c
				FROM EnvelopeStatus__c
				WHERE DocuSignId__c IN :ids
			];
			System.assertEquals(2, Collection.size(ess));
			for (EnvelopeStatus__c es : ess) {
				System.assertNotEquals(null, es);
				System.assertEquals(Envelope.STATUS_DECLINED, es.Status__c);
				System.assertEquals('decline reason', es.Reason__c);
				System.assertNotEquals(null, es.Completed__c);
				System.assertNotEquals(null, es.LastStatusUpdate__c);
			}

			Set<Id> esIds = new Set<Id> { es1.Id, es2.Id };
			List<RecipientStatus__c> rss = [
				SELECT
					Status__c, Completed__c, LastStatusUpdate__c
				FROM RecipientStatus__c
				WHERE EnvelopeStatus__c IN :esIds
			];
			System.assertEquals(4, Collection.size(rss));
			for (RecipientStatus__c rs : rss) {
				System.assertNotEquals(null, rs);
				if (rs.Id == es1rs1.Id) {
					System.assertEquals(Recipient.STATUS_COMPLETED, rs.Status__c);
				} else if (rs.Id == es2rs2.Id) {
					System.assertEquals(Recipient.STATUS_SIGNED, rs.Status__c);
				} else {
					System.assertEquals(Recipient.STATUS_CANCELED, rs.Status__c);
				}
				System.assertNotEquals(null, rs.Completed__c);
				System.assertNotEquals(null, rs.LastStatusUpdate__c);
			}
		}
	}

	@IsTest
	static void test_createStatus_unauthorized() {
		Envelope e1, e2;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			try {
				StatusService.createStatus(new List<Envelope.Status> { e1.toEnvelopeStatus(), e2.toEnvelopeStatus() });
				throw new AssertException('Expected createStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createStatus_no_envelopes() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				StatusService.createStatus(null);
				throw new AssertException('Expected createStatus to fail');
			} catch (ValidationException ex) {
				System.assertEquals(Label.CannotCreateStatus + '\n' + Label.AtLeastOneEnvelopeIsRequired, ex.getMessage());
			}
			try {
				StatusService.createStatus(new List<Envelope.Status>());
				throw new AssertException('Expected createStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.EnvelopeNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createStatus_invalid_envelopes() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			e2.Sent__c = null; // make invalid
			update e2;
			Envelope.Status es1 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.parse(e1.DocuSignId__c),
				Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, e1.Sent__c, null,
				Datetime.now(), 's1', null, Datetime.now());
			Envelope.Status es2 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.parse(e2.DocuSignId__c),
				Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, e2.Sent__c, null,
				Datetime.now(), 's2', null, Datetime.now());

			Test.startTest();
			try {
				StatusService.createStatus(new List<Envelope.Status> {
					es1, es2
				});
				throw new AssertException('Expected createStatus to fail');
			} catch (ValidationException ex) {
				System.assertEquals(Label.CannotCreateStatus + '\n' + Label.EnvelopesMustBeSent, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createStatus_valid() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Recipient e1r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e1.id));
			Recipient e1r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e1.id));
			Envelope e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Recipient e2r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e2.id));
			Envelope.Status es1 = e1.toEnvelopeStatus().addRecipients(new List<Recipient.Status> {
				e1r1.toRecipientStatus(e1.sent),
				e1r2.toRecipientStatus(e1.sent)
			});
			Envelope.Status es2 = e2.toEnvelopeStatus().addRecipients(new List<Recipient.Status> {
				e2r1.toRecipientStatus(e1.sent)
			});

			Test.startTest();
			List<Envelope.Status> result = StatusService.createStatus(new List<Envelope.Status> {
				es1, es2
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].id);
			System.assertNotEquals(null, result[0].recipients);
			System.assertEquals(2, result[0].recipients.size());
			System.assertNotEquals(null, result[0].recipients[0]);
			System.assertNotEquals(null, result[0].recipients[0].id);
			System.assertNotEquals(null, result[0].recipients[1]);
			System.assertNotEquals(null, result[0].recipients[1].id);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);
			System.assertNotEquals(null, result[0].recipients);
			System.assertEquals(1, result[1].recipients.size());
			System.assertNotEquals(null, result[1].recipients[0]);
			System.assertNotEquals(null, result[1].recipients[0].id);
		}
	}

	@IsTest
	static void test_prepareUpsert() {
		Datetime dt = Datetime.now().addDays(-3);
		Recipient.Status r1 = new Recipient.Status(
			UserInfo.getUserId(),
			new Entity(UserInfo.getUserId()),
			Recipient.TYPE_SIGNER,
			1,
			Recipient.STATUS_SIGNED,
			'r1',
			'r1@unit.test',
			1,
			dt,
			dt,
			'r1',
			dt);
		Recipient.Status r2 = new Recipient.Status(
			UserInfo.getUserId(),
			new Entity(UserInfo.getUserId()),
			Recipient.TYPE_CARBON_COPY,
			2,
			Recipient.STATUS_CREATED,
			'r2',
			'r2@unit.test',
			2,
			dt,
			dt,
			'r2',
			dt);
		Envelope.Status e = new Envelope.Status(
			UserInfo.getOrganizationId(),
			new Entity(UserInfo.getUserId()),
			UUID.randomUUID(),
			Envelope.STATUS_VOIDED,
			'sender',
			'sender@unit.test',
			new List<Recipient.Status> { r1, r2 },
			dt,
			dt.addDays(10),
			dt.addDays(3),
			'subject',
			'reason',
			dt.addDays(3));

		Test.startTest();
		Envelope.Status result = StatusService.prepareUpsert(e);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(e.id, result.id);
		System.assertEquals(e.source, result.source);
		System.assertEquals(e.docuSignId, result.docuSignId);
		System.assertEquals(e.status, result.status);
		System.assertEquals(e.senderName, result.senderName);
		System.assertEquals(e.senderEmail, result.senderEmail);
		System.assertEquals(2, Collection.size(result.recipients));
		System.assertEquals(e.sent, result.sent);
		System.assertEquals(e.expires, result.expires);
		System.assertEquals(e.completed, result.completed);
		System.assertEquals(e.emailSubject, result.emailSubject);
		System.assertEquals(e.reason, result.reason);
		System.assertEquals(e.lastStatusUpdate, result.lastStatusUpdate);

		Recipient.Status r = result.recipients[0];
		System.assertNotEquals(null, r);
		System.assertEquals(r1.id, r.id);
		System.assertEquals(r1.source, r.source);
		System.assertEquals(r1.type, r.type);
		System.assertEquals(r1.sequence, r.sequence);
		System.assertEquals(r1.status, r.status);
		System.assertEquals(r1.name, r.name);
		System.assertEquals(r1.email, r.email);
		System.assertEquals(r1.routingOrder, r.routingOrder);
		System.assertEquals(dt, r.sent);
		System.assertEquals(dt, r.completed);
		System.assertEquals(r1.reason, r.reason);
		System.assertEquals(dt, r.lastStatusUpdate);

		r = result.recipients[1];
		System.assertNotEquals(null, r);
		System.assertEquals(r2.id, r.id);
		System.assertEquals(r2.source, r.source);
		System.assertEquals(r2.type, r.type);
		System.assertEquals(r2.sequence, r.sequence);
		System.assertEquals(Recipient.STATUS_CANCELED, r.status);
		System.assertEquals(r2.name, r.name);
		System.assertEquals(r2.email, r.email);
		System.assertEquals(r2.routingOrder, r.routingOrder);
		System.assertEquals(dt, r.sent);
		System.assertNotEquals(dt, r.completed);
		System.assertEquals(r2.reason, r.reason);
		System.assertNotEquals(dt, r.lastStatusUpdate);
	}

	@IsTest
	static void test_getStatus_by_source_id() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Lead l = TestUtils.createLead();
			Envelope__c e1 = TestUtils.createEnvelope(a.Id);
			e1.Sent__c = Datetime.now().addDays(-5);
			Envelope__c e2 = TestUtils.createEnvelope(a.Id);
			e2.Sent__c = Datetime.now().addDays(-2);
			Envelope__c e3 = TestUtils.createEnvelope(l.Id);
			e3.Sent__c = Datetime.now().addDays(-3);
			Envelope__c e4 = TestUtils.createEnvelope(l.Id);
			e4.Sent__c = Datetime.now().addDays(-4);
			update new List<Envelope__c> {
				e1, e2, e3, e4
			};
			StatusService.DB.convert(TestUtils.createEnvelopeStatus(e1));
			Envelope.Status es2 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e2));
			Envelope.Status es3 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e3));
			Envelope.Status es4 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e4));

			Test.startTest();
			// Pulls last 3 statuses and orders by ascending sent date time. Expecting status for es4, es3, es2.
			List<Envelope.Status> result = StatusService.getStatus(new Set<Id> {
				a.Id, l.Id
			}, 3);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es4.id, result[0].id);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(es3.id, result[1].id);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(es2.id, result[2].id);
		}
	}

	@IsTest
	static void test_getStatus_no_update() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Envelope.Status es1 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e1));
			Envelope.Status es2 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e2));

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> {
				es1.docuSignId, es2.docuSignId
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es1.id, result[0].id);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(es2.id, result[1].id);
		}
	}

	private class StatusErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"UNIT_TEST","message":"Unit test error."}');
			return response;
		}
	}

	@IsTest
	static void test_getStatus_error() {
		Test.setMock(HttpCalloutMock.class, new StatusErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope(ID1);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			es1.Sent__c = Datetime.now().addDays(-3);
			es1.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es1.Id, 1);
			TestUtils.createRecipientStatus(es1.Id, 2);
			update es1;

			Test.startTest();
			try {
				StatusService.getStatus(new Set<UUID> { ID1 });
				throw new AssertException('Expected getStatus to fail');
			} catch (APIException ex) {
				System.assertEquals('Unit test error.', ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class StatusUnauthorizedMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			String path = new Url(request.getEndpoint()).getPath();
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (path.endsWith(ID1.toString())) {
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setBody('{"status":"voided","emailSubject":"Please DocuSign: word.pdf","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-08-30T01:00:47.0000000Z","lastModifiedDateTime":"2018-08-30T01:02:20.1170000Z","initialSentDateTime":"2018-08-30T01:00:54.1170000Z","sentDateTime":"2018-08-30T01:01:33.8470000Z","voidedDateTime":"2018-08-30T01:02:20.1170000Z","voidedReason":"Testing void status","statusChangedDateTime":"2018-08-30T01:02:20.1170000Z","recipients":{"signers":[{"name":"e1s1","email":"e1s1@unit.test","recipientId":"1","routingOrder":"1","status":"completed","signedDateTime":"2018-08-30T01:01:32.2530000Z","deliveredDateTime":"2018-08-30T01:01:17.0800000Z"},{"name":"e1s2","email":"e1s2@unit.test","recipientId":"2","routingOrder":"2","status":"sent"}],"agents":[],"editors":[],"intermediaries":[],"carbonCopies":[],"certifiedDeliveries":[],"inPersonSigners":[],"seals":[],"recipientCount":"2","currentRoutingOrder":"2"}}');
			} else if (path.endsWith(ID2.toString()) || path.endsWith(ID4.toString())) {
				response.setStatusCode(400);
				response.setStatus('BAD_REQUEST');
				response.setBody('{"errorCode":"USER_LACKS_PERMISSIONS","message":"This user lacks sufficient permissions to access this resource."}');
			} else { // ID3
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setBody('{"status":"completed","emailSubject":"Please DocuSign: word.pdf","envelopeId":"33333333-3333-3333-3333-333333333333","createdDateTime":"2018-08-30T01:00:47.0000000Z","lastModifiedDateTime":"2018-08-30T01:02:20.1170000Z","initialSentDateTime":"2018-08-30T01:00:54.1170000Z","sentDateTime":"2018-08-30T01:01:33.8470000Z","completedDateTime":"2018-08-30T01:02:20.1170000Z","statusChangedDateTime":"2018-08-30T01:02:20.1170000Z","recipients":{"signers":[{"name":"e3s1","email":"e3s1@unit.test","recipientId":"1","routingOrder":"1","status":"completed","signedDateTime":"2018-08-30T01:01:32.2530000Z","deliveredDateTime":"2018-08-30T01:01:17.0800000Z"}],"agents":[],"editors":[],"intermediaries":[],"carbonCopies":[],"certifiedDeliveries":[],"inPersonSigners":[],"seals":[],"recipientCount":"2","currentRoutingOrder":"2"}}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getStatus_unauthorized() {
		Test.setMock(HttpCalloutMock.class, new StatusUnauthorizedMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope(ID1);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			es1.Sent__c = Datetime.now().addDays(-3);
			es1.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es1.Id, 1);
			TestUtils.createRecipientStatus(es1.Id, 2);

			Envelope__c e2 = TestUtils.createEnvelope(ID2);
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(e2);
			es2.Sent__c = Datetime.now().addDays(-2);
			es2.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es2.Id, 1);

			Envelope__c e3 = TestUtils.createEnvelope(ID3);
			EnvelopeStatus__c es3 = TestUtils.createEnvelopeStatus(e3);
			es3.Sent__c = Datetime.now().addDays(-1);
			es3.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es3.Id, 1);

			update new List<EnvelopeStatus__c> { es1, es2, es3 };

			Test.startTest();
			// ID2 - unauthorized in DS API. Ignore and move on.
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> { ID1, ID2, ID3 });
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));

			System.assertEquals(1, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE Id = :es1.Id]));
			System.assertEquals(2, Collection.size([SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c = :es1.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM Envelope__c WHERE Id = :e1.Id]));

			System.assertEquals(1, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE Id = :es2.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c = :es2.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM Envelope__c WHERE Id = :e2.Id]));

			System.assertEquals(1, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE Id = :es3.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c = :es3.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM Envelope__c WHERE Id = :e3.Id]));
		}
	}

	private class StatusNotFoundMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			String path = new Url(request.getEndpoint()).getPath();
			HttpResponse response = new HttpResponse();
			if (path.endsWith(ID1.toString())) {
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setHeader('Content-Type', 'application/json; charset=utf-8');
				response.setBody('{"status":"voided","emailSubject":"Please DocuSign: word.pdf","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-08-30T01:00:47.0000000Z","lastModifiedDateTime":"2018-08-30T01:02:20.1170000Z","initialSentDateTime":"2018-08-30T01:00:54.1170000Z","sentDateTime":"2018-08-30T01:01:33.8470000Z","voidedDateTime":"2018-08-30T01:02:20.1170000Z","voidedReason":"Testing void status","statusChangedDateTime":"2018-08-30T01:02:20.1170000Z","recipients":{"signers":[{"name":"e1s1","email":"e1s1@unit.test","recipientId":"1","routingOrder":"1","status":"completed","signedDateTime":"2018-08-30T01:01:32.2530000Z","deliveredDateTime":"2018-08-30T01:01:17.0800000Z"},{"name":"e1s2","email":"e1s2@unit.test","recipientId":"2","routingOrder":"2","status":"sent"}],"agents":[],"editors":[],"intermediaries":[],"carbonCopies":[],"certifiedDeliveries":[],"inPersonSigners":[],"seals":[],"recipientCount":"2","currentRoutingOrder":"2"}}');
			} else if (path.endsWith(ID2.toString()) || path.endsWith(ID4.toString())) {
				response.setStatusCode(404);
				response.setStatus('NOT_FOUND');
			} else { // ID3
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setHeader('Content-Type', 'application/json; charset=utf-8');
				response.setBody('{"status":"completed","emailSubject":"Please DocuSign: word.pdf","envelopeId":"33333333-3333-3333-3333-333333333333","createdDateTime":"2018-08-30T01:00:47.0000000Z","lastModifiedDateTime":"2018-08-30T01:02:20.1170000Z","initialSentDateTime":"2018-08-30T01:00:54.1170000Z","sentDateTime":"2018-08-30T01:01:33.8470000Z","completedDateTime":"2018-08-30T01:02:20.1170000Z","statusChangedDateTime":"2018-08-30T01:02:20.1170000Z","recipients":{"signers":[{"name":"e3s1","email":"e3s1@unit.test","recipientId":"1","routingOrder":"1","status":"completed","signedDateTime":"2018-08-30T01:01:32.2530000Z","deliveredDateTime":"2018-08-30T01:01:17.0800000Z"}],"agents":[],"editors":[],"intermediaries":[],"carbonCopies":[],"certifiedDeliveries":[],"inPersonSigners":[],"seals":[],"recipientCount":"2","currentRoutingOrder":"2"}}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getStatus_not_found() {
		Test.setMock(HttpCalloutMock.class, new StatusNotFoundMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope(ID1);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			es1.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es1.Id, 1);
			TestUtils.createRecipientStatus(es1.Id, 2);

			Envelope__c e2 = TestUtils.createEnvelope(ID2);
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(e2);
			es2.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es2.Id, 1);

			Envelope__c e3 = TestUtils.createEnvelope(ID3);
			EnvelopeStatus__c es3 = TestUtils.createEnvelopeStatus(e3);
			es3.LastStatusUpdate__c = null;
			TestUtils.createRecipientStatus(es3.Id, 1);

			update new List<EnvelopeStatus__c> { es1, es2, es3 };

			Test.startTest();
			// ID2/ID4 = not found in DS API. Should succeed and silently delete orphaned records.
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> { ID1, ID2, ID3, ID4 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertEquals(ID1, result[0].docuSignId);
			System.assertEquals(ID3, result[1].docuSignId);

			System.assertEquals(1, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE Id = :es1.Id]));
			System.assertEquals(2, Collection.size([SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c = :es1.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM Envelope__c WHERE Id = :e1.Id]));

			System.assertEquals(0, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE Id = :es2.Id]));
			System.assertEquals(0, Collection.size([SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c = :es2.Id]));
			System.assertEquals(0, Collection.size([SELECT Id FROM Envelope__c WHERE Id = :e2.Id]));

			System.assertEquals(1, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE Id = :es3.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c = :es3.Id]));
			System.assertEquals(1, Collection.size([SELECT Id FROM Envelope__c WHERE Id = :e3.Id]));

			System.assertEquals(0, Collection.size([SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c = :ID4.toString()]));
			System.assertEquals(0, Collection.size([SELECT Id FROM Envelope__c WHERE DocuSignId__c = :ID4.toString()]));
		}
	}

	@IsTest
	static void test_getStatus_no_update_final_status() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Envelope__c e3 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			es1.LastStatusUpdate__c = null;
			es1.Status__c = Envelope.STATUS_COMPLETED;
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(e2);
			es2.LastStatusUpdate__c = null;
			es2.Status__c = Envelope.STATUS_VOIDED;
			EnvelopeStatus__c es3 = TestUtils.createEnvelopeStatus(e3);
			es3.LastStatusUpdate__c = null;
			es3.Status__c = Envelope.STATUS_DECLINED;
			update new List<EnvelopeStatus__c> {
				es1, es2, es3
			};

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> {
				UUID.parse(es1.DocuSignId__c), UUID.parse(es2.DocuSignId__c), UUID.parse(es3.DocuSignId__c)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es1.Id, result[0].id);
			System.assertEquals(null, result[0].lastStatusUpdate);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(es2.Id, result[1].id);
			System.assertEquals(null, result[1].lastStatusUpdate);
			System.assertNotEquals(null, result[2]);
			System.assertEquals(es3.Id, result[2].id);
			System.assertEquals(null, result[2].lastStatusUpdate);
		}
	}

	private class EnvelopeStatusMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			String endpoint = request.getEndpoint();
			String dseId = endpoint.substringAfter('envelopes/').substring(0, 36);

			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"status":"completed","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"'
				+ dseId + '","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","completedDateTime":"2018-04-18T22:06:22.5730000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z"}');
			return response;
		}
	}

	@IsTest
	static void test_getStatus_with_update() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			es1.LastStatusUpdate__c = null;
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(e2);
			es2.LastStatusUpdate__c = Datetime.now().addMinutes(-16);
			update new List<EnvelopeStatus__c> {
				es1, es2
			};

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> {
				UUID.parse(es1.DocuSignId__c), UUID.parse(es2.DocuSignId__c)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es1.Id, result[0].id);
			System.assertNotEquals(null, result[0].lastStatusUpdate);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(es2.Id, result[1].id);
			System.assertNotEquals(null, result[1].lastStatusUpdate);
		}
	}

	@IsTest
	static void test_getStatus_not_exists() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Envelope.Status es1 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e1));
			Envelope.Status es2 = EnvelopeService.DB.convert(e2).toEnvelopeStatus();
			Set<String> ids = new Set<String> { String.valueOf(es1.docuSignId), String.valueOf(es2.docuSignId) };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :ids];
			System.assertEquals(1, ess.size());

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> {
				es1.docuSignId, es2.docuSignId
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].id);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);

			ess = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :ids];
			System.assertEquals(2, ess.size());
		}
	}

	@IsTest
	static void test_deleteStatus_unauthorized() {
		Envelope e1, e2;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			try {
				StatusService.deleteStatus(new Set<UUID> {
					e1.docuSignId, e2.docuSignId
				}, false);
				throw new AssertException('Expected deleteStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteStatus_not_found() {
		System.runAs(UserMock.createDocuSignUser()) {
			UUID dseId1 = UUID.randomUUID();
			TestUtils.createEnvelopeStatus(dseId1);

			Test.startTest();
			try {
				StatusService.deleteStatus(new Set<UUID> { dseId1 }, false);
				throw new AssertException('Expected deleteStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.EnvelopeNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteStatus_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.parse(e1.DocuSignId__c);
			TestUtils.createEnvelopeStatus(dseId1);
			Envelope__c e2 = TestUtils.createEnvelope();
			UUID dseId2 = UUID.parse(e2.DocuSignId__c);
			TestUtils.createEnvelopeStatus(dseId2);

			Test.startTest();
			Boolean result = StatusService.deleteStatus(new Set<UUID> { dseId1, dseId2 }, false);
			Test.stopTest();

			System.assert(result);
			Set<String> ids = new Set<String> { e1.DocuSignId__c, e2.DocuSignId__c };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :ids];
			System.assert(Collection.isEmpty(ess));
		}
	}

	@IsTest
	static void test_resendEnvelope_unauthorized() {
		Envelope e1;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				StatusService.resendEnvelope(e1.docuSignId);
				throw new AssertException('Expected resendEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendEnvelope_invalid_status() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.parse(e1.DocuSignId__c);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			es1.Status__c = Envelope.STATUS_DECLINED;
			update es1;

			Test.startTest();
			try {
				StatusService.resendEnvelope(dseId1);
				throw new AssertException('Expected resendEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotResendEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			UUID dseId = UUID.randomUUID();
			Envelope__c e = TestUtils.createEnvelope(dseId);
			TestUtils.createEnvelopeStatus(e);

			Test.startTest();
			System.assert(StatusService.resendEnvelope(dseId));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendRecipients_unauthorized() {
		Envelope e1;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				StatusService.resendRecipients(e1.docuSignId, null);
				throw new AssertException('Expected resendRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendRecipients_invalid_status() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.parse(e1.DocuSignId__c);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			es1.Status__c = Envelope.STATUS_DECLINED;
			update es1;

			Test.startTest();
			try {
				StatusService.resendRecipients(dseId1, null);
				throw new AssertException('Expected resendRecipients to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotResendEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendRecipients_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			UUID dseId = UUID.randomUUID();
			Envelope__c e = TestUtils.createEnvelope(dseId);
			TestUtils.createEnvelopeStatus(e);

			Test.startTest();
			List<Recipient.ResendResult> result = StatusService.resendRecipients(dseId, new List<Recipient> {
				Recipient.fromSource('n', 'r@unit.test', null, null, null)
			});
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_voidEnvelope_unauthorized() {
		Envelope e1;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				StatusService.voidEnvelope(e1.docuSignId, 'reason');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_voidEnvelope_not_found() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			try {
				StatusService.voidEnvelope(e1.docuSignId, 'reason');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.StatusNotFound_1, new List<String> {
					String.valueOf(e1.docuSignId)
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_voidEnvelope_invalid_status() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.parse(e1.DocuSignId__c);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			es1.Status__c = Envelope.STATUS_COMPLETED;
			update es1;

			Test.startTest();
			try {
				StatusService.voidEnvelope(dseId1, 'reason');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotVoidEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_voidEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.parse(e1.DocuSignId__c);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			es1.Status__c = Envelope.STATUS_SENT;
			update es1;

			Test.startTest();
			Boolean result = StatusService.voidEnvelope(dseId1, 'reason');
			Test.stopTest();

			System.assert(result);
			List<EnvelopeStatus__c> ess = [
				SELECT
					Status__c, Reason__c, Completed__c, LastStatusUpdate__c
				FROM EnvelopeStatus__c
				WHERE DocuSignId__c = :e1.DocuSignId__c
			];
			System.assertNotEquals(null, ess);
			System.assertEquals(1, ess.size());
			System.assertNotEquals(null, ess[0]);
			System.assertEquals(Envelope.STATUS_VOIDED, ess[0].Status__c);
			System.assertEquals('reason', ess[0].Reason__c);
			System.assertNotEquals(null, ess[0].Completed__c);
			System.assertNotEquals(null, ess[0].LastStatusUpdate__c);
		}
	}

	@IsTest
	static void test_correctEnvelope_unauthorized() {
		Envelope e1;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				StatusService.getCorrectUrl(e1.docuSignId, new Url('https://unit.test/return'));
				throw new AssertException('Expected correctEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_correctEnvelope_not_found() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();

			Test.startTest();
			try {
				StatusService.getCorrectUrl(UUID.parse(e1.DocuSignId__c), new Url('https://unit.test/return'));
				throw new AssertException('Expected correctEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.StatusNotFound_1, new List<String> {
					e1.DocuSignId__c
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_correctEnvelope_invalid_status() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(UUID.parse(e1.DocuSignId__c));
			es1.Status__c = Envelope.STATUS_VOIDED;
			update es1;

			Test.startTest();
			try {
				StatusService.getCorrectUrl(UUID.parse(e1.DocuSignId__c), new Url('https://unit.test/return'));
				throw new AssertException('Expected correctEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotCorrectEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_correctEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(UUID.parse(e1.DocuSignId__c));
			es1.Status__c = Envelope.STATUS_SENT;
			update es1;

			Test.startTest();
			Url result = StatusService.getCorrectUrl(UUID.parse(e1.DocuSignId__c), new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_viewEnvelope_invalid() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				StatusService.getViewUrl(null, new Url('https://unit.test/return'));
				throw new AssertException('Expected viewEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidStatus, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_viewEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			TestUtils.createEnvelopeStatus(UUID.parse(e1.DocuSignId__c));

			Test.startTest();
			Url result = StatusService.getViewUrl(UUID.parse(e1.DocuSignId__c), new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_updateStatus_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				StatusService.updateStatus(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateStatus_empty() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			System.assertEquals(new List<Envelope.Status>(), StatusService.updateStatus(null));
			System.assertEquals(new List<Envelope.Status>(), StatusService.updateStatus(new List<Envelope.Status>()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateStatus_new() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Envelope.Status es = new Envelope.Status(
				null,
				new Entity(UserInfo.getUserId()),
				UUID.randomUUID(),
				Envelope.STATUS_COMPLETED,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString() + '@unit.test',
				new List<Recipient.Status> {
					new Recipient.Status(
						null,
						null,
						Recipient.TYPE_SIGNER,
						1,
						Recipient.STATUS_COMPLETED,
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						1,
						Datetime.now().addDays(-1),
						Datetime.now(),
						null,
						Datetime.now()),
					new Recipient.Status(
						null,
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						Recipient.STATUS_COMPLETED,
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						2,
						Datetime.now().addDays(-1),
						Datetime.now(),
						null,
						Datetime.now())
				},
				Datetime.now().addDays(-1),
				Datetime.now().addDays(1),
				Datetime.now(),
				UUID.randomUUID().toString(),
				null,
				Datetime.now());

			Test.startTest();
			List<Envelope.Status> result = StatusService.updateStatus(new List<Envelope.Status> { es });
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));

			Envelope.Status e = result[0];
			System.assertNotEquals(null, e);
			System.assertNotEquals(null, e.id);
			System.assertEquals(es.source, e.source);
			System.assertEquals(es.docuSignId, e.docuSignId);
			System.assertEquals(es.status, e.status);
			System.assertEquals(es.senderName, e.senderName);
			System.assertEquals(es.senderEmail, e.senderEmail);
			System.assertEquals(es.sent, e.sent);
			System.assertEquals(es.expires, e.expires);
			System.assertEquals(es.completed, e.completed);
			System.assertEquals(es.emailSubject, e.emailSubject);
			System.assertEquals(es.reason, e.reason);

			System.assertEquals(2, Collection.size(e.recipients));
			for (Integer i = 0; i < e.recipients.size(); i++) {
				Recipient.Status expected = es.recipients[i];
				Recipient.Status actual = e.recipients[i];
				System.assertNotEquals(null, actual);
				System.assertNotEquals(null, actual.id);
				System.assertEquals(expected.source, actual.source);
				System.assertEquals(expected.type, actual.type);
				System.assertEquals(expected.sequence, actual.sequence);
				System.assertEquals(expected.status, actual.status);
				System.assertEquals(expected.name, actual.name);
				System.assertEquals(expected.email, actual.email);
				System.assertEquals(expected.routingOrder, actual.routingOrder);
				System.assertEquals(expected.sent, actual.sent);
				System.assertEquals(expected.completed, actual.completed);
				System.assertEquals(expected.reason, actual.reason);
			}

			System.assertEquals(1, [SELECT COUNT() FROM EnvelopeStatus__c WHERE Id = :e.id]);
			System.assertEquals(2, [SELECT COUNT() FROM RecipientStatus__c WHERE EnvelopeStatus__c = :e.id]);
		}
	}

	@IsTest
	static void test_updateStatus_existing() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			EnvelopeStatus__c dbes1 = TestUtils.createEnvelopeStatus();
			TestUtils.createRecipientStatus(dbes1.Id, 1);
			TestUtils.createRecipientStatus(dbes1.Id, 2);
			Envelope.Status es1 = new Envelope.Status(
				null,
				new Entity(UserInfo.getUserId()),
				UUID.randomUUID(),
				Envelope.STATUS_COMPLETED,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString() + '@unit.test',
				new List<Recipient.Status> {
					new Recipient.Status(
						null,
						null,
						Recipient.TYPE_SIGNER,
						1,
						Recipient.STATUS_COMPLETED,
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						1,
						Datetime.now().addDays(-1),
						Datetime.now(),
						null,
						Datetime.now()),
					new Recipient.Status(
						null,
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						Recipient.STATUS_COMPLETED,
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						2,
						Datetime.now().addDays(-1),
						Datetime.now(),
						null,
						Datetime.now())
				},
				Datetime.now().addDays(-1),
				Datetime.now().addDays(1),
				Datetime.now(),
				UUID.randomUUID().toString(),
				null,
				Datetime.now());
			Envelope.Status es2 = new Envelope.Status(
				null,
				new Entity(UserInfo.getUserId()),
				UUID.parse(dbes1.DocuSignId__c),
				Envelope.STATUS_VOIDED,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString() + '@unit.test',
				new List<Recipient.Status> {
					new Recipient.Status(
						null,
						null,
						Recipient.TYPE_SIGNER,
						1,
						Recipient.STATUS_SENT,
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						1,
						Datetime.now().addDays(-1),
						Datetime.now(),
						null,
						Datetime.now()),
					new Recipient.Status(
						null,
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						Recipient.STATUS_CREATED,
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						2,
						Datetime.now().addDays(-1),
						Datetime.now(),
						null,
						Datetime.now())
				},
				Datetime.now().addDays(-1),
				Datetime.now().addDays(1),
				Datetime.now(),
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				Datetime.now());

			Test.startTest();
			List<Envelope.Status> result = StatusService.updateStatus(new List<Envelope.Status> { es1, es2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));

			Envelope.Status e = result[0];
			System.assertNotEquals(null, e);
			Boolean isExisting = e.id == dbes1.Id;
			Envelope.Status ee = isExisting ? es2 : es1;
			if (isExisting) {
				System.assertEquals(dbes1.Id, e.id);
				System.assertEquals(dbes1.DocuSignId__c, String.valueOf(e.docuSignId));
			} else {
				System.assertNotEquals(null, e.id);
				System.assertEquals(ee.docuSignId, e.docuSignId);
			}
			System.assertEquals(ee.source, e.source);
			System.assertEquals(ee.status, e.status);
			System.assertEquals(ee.senderName, e.senderName);
			System.assertEquals(ee.senderEmail, e.senderEmail);
			System.assertEquals(ee.sent, e.sent);
			System.assertEquals(ee.expires, e.expires);
			System.assertEquals(ee.completed, e.completed);
			System.assertEquals(ee.emailSubject, e.emailSubject);
			System.assertEquals(ee.reason, e.reason);

			System.assertEquals(2, Collection.size(e.recipients));
			for (Integer i = 0; i < e.recipients.size(); i++) {
				Recipient.Status expected = ee.recipients[i];
				Recipient.Status actual = e.recipients[i];
				System.assertNotEquals(null, actual);
				System.assertNotEquals(null, actual.id);
				if (isExisting) {
					System.assertEquals(new Entity(UserInfo.getUserId()), actual.source);
				} else {
					System.assertEquals(expected.source, actual.source);
				}
				System.assertEquals(expected.type, actual.type);
				System.assertEquals(expected.sequence, actual.sequence);
				System.assertEquals(expected.status, actual.status);
				System.assertEquals(expected.name, actual.name);
				System.assertEquals(expected.email, actual.email);
				System.assertEquals(expected.routingOrder, actual.routingOrder);
				System.assertEquals(expected.sent, actual.sent);
				System.assertEquals(expected.completed, actual.completed);
				System.assertEquals(expected.reason, actual.reason);
			}

			System.assertEquals(1, [SELECT COUNT() FROM EnvelopeStatus__c WHERE Id = :e.id]);
			System.assertEquals(2, [SELECT COUNT() FROM RecipientStatus__c WHERE EnvelopeStatus__c = :e.id]);

			e = result[1];
			isExisting = !isExisting;
			ee = isExisting ? es2 : es1;
			if (isExisting) {
				System.assertEquals(dbes1.Id, e.id);
				System.assertEquals(dbes1.DocuSignId__c, String.valueOf(e.docuSignId));
			} else {
				System.assertNotEquals(null, e.id);
				System.assertEquals(ee.docuSignId, e.docuSignId);
			}
			System.assertNotEquals(null, e);
			System.assertNotEquals(null, e.id);
			System.assertEquals(ee.source, e.source);
			System.assertEquals(ee.docuSignId, e.docuSignId);
			System.assertEquals(ee.status, e.status);
			System.assertEquals(ee.senderName, e.senderName);
			System.assertEquals(ee.senderEmail, e.senderEmail);
			System.assertEquals(ee.sent, e.sent);
			System.assertEquals(ee.expires, e.expires);
			System.assertEquals(ee.completed, e.completed);
			System.assertEquals(ee.emailSubject, e.emailSubject);
			System.assertEquals(ee.reason, e.reason);

			System.assertEquals(2, Collection.size(e.recipients));
			for (Integer i = 0; i < e.recipients.size(); i++) {
				Recipient.Status expected = ee.recipients[i];
				Recipient.Status actual = e.recipients[i];
				System.assertNotEquals(null, actual);
				System.assertNotEquals(null, actual.id);
				if (isExisting) {
					System.assertEquals(new Entity(UserInfo.getUserId()), actual.source);
				} else {
					System.assertEquals(expected.source, actual.source);
				}
				System.assertEquals(expected.type, actual.type);
				System.assertEquals(expected.sequence, actual.sequence);
				System.assertEquals(expected.status, actual.status);
				System.assertEquals(expected.name, actual.name);
				System.assertEquals(expected.email, actual.email);
				System.assertEquals(expected.routingOrder, actual.routingOrder);
				System.assertEquals(expected.sent, actual.sent);
				System.assertEquals(expected.completed, actual.completed);
				System.assertEquals(expected.reason, actual.reason);
			}

			System.assertEquals(1, [SELECT COUNT() FROM EnvelopeStatus__c WHERE Id = :e.id]);
			System.assertEquals(2, [SELECT COUNT() FROM RecipientStatus__c WHERE EnvelopeStatus__c = :e.id]);
		}
	}
}
