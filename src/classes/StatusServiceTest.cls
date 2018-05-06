@IsTest
private class StatusServiceTest {

	static testMethod void test_validate() {
		// Valid
		Envelope.Status es1 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.randomUUID(),
			Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, DateTime.now().addDays(-1),
			Datetime.now(), 's1', null, Datetime.now());
		// Invalid - no DocuSign ID
		Envelope.Status es2 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), null,
			Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, DateTime.now().addDays(-1),
			Datetime.now(), 's1', null, Datetime.now());
		// Invalid - not created/sent
		Envelope.Status es3 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.randomUUID(),
			Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, null,
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

	static testMethod void test_Database_convert_EnvelopeStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
			System.assertEquals(es2.Completed__c, es.completed);
			System.assertEquals(es2.Reason__c, es.reason);
			System.assertEquals(es2.LastStatusUpdate__c, es.lastStatusUpdate);
		}
	}

	static testMethod void test_Database_convert_RecipientStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_Database_queryStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_Database_insertStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Datetime now = DateTime.now();
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
				now.addDays(-2), 'e1', null, now.addDays(-1));
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
				now.addDays(-2), 'e2', null, now.addDays(-2));

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

	static testMethod void test_Database_upsertStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Datetime now = DateTime.now();
			Envelope.Status e1 = StatusService.DB.convert(TestUtils.createEnvelopeStatus());
			Recipient.Status e1r1 = StatusService.DB.convert(TestUtils.createRecipientStatus(e1.Id, 1));
			Recipient.Status e1r2 = StatusService.DB.convert(TestUtils.createRecipientStatus(e1.Id, 2));
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
				now.addDays(-2), 'e2', null, now.addDays(-2));

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

	static testMethod void test_Database_deleteStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Datetime now = DateTime.now();
			UUID e1Id = UUID.randomUUID();
			EnvelopeStatus__c e1 = TestUtils.createEnvelopeStatus(e1Id);
			RecipientStatus__c e1r1 = TestUtils.createRecipientStatus(e1.Id, 1);
			RecipientStatus__c e1r2 = TestUtils.createRecipientStatus(e1.Id, 2);
			UUID e2Id = UUID.randomUUID();
			EnvelopeStatus__c e2 = TestUtils.createEnvelopeStatus(e2Id);
			RecipientStatus__c e2r1 = TestUtils.createRecipientStatus(e2.Id, 1);
			RecipientStatus__c e2r2 = TestUtils.createRecipientStatus(e2.Id, 2);

			Test.startTest();
			Boolean result = StatusService.DB.deleteStatus(new Set<UUID> { e1Id, e2Id });
			Test.stopTest();

			System.assert(result);

			Set<Id> essIds = new Set<Id> { e1.Id, e2.Id };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE Id IN :essIds];
			System.assert(Collection.isEmpty(ess));

			Set<Id> rssIds = new Set<Id> { e1r1.Id, e1r2.Id, e2r1.Id, e2r2.Id };
			List<RecipientStatus__c> rss = [SELECT Id FROM RecipientStatus__c WHERE Id IN :rssIds];
			System.assert(Collection.isEmpty(rss));
		}
	}

	static testMethod void test_Database_updateStatus() {
		System.runAs(TestUtils.createDocuSignUser()) {
			UUID dseId1 = UUID.randomUUID();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			UUID dseId2 = UUID.randomUUID();
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(dseId2);

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
			System.assertNotEquals(null, ess);
			System.assertEquals(2, ess.size());
			for (EnvelopeStatus__c es : ess) {
				System.assertNotEquals(null, es);
				System.assertEquals(Envelope.STATUS_DECLINED, es.Status__c);
				System.assertEquals('decline reason', es.Reason__c);
				System.assertNotEquals(null, es.Completed__c);
				System.assertNotEquals(null, es.LastStatusUpdate__c);
			}
		}
	}

	static testMethod void test_createStatus_unauthorized() {
		Envelope e1, e2;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_createStatus_no_envelopes() {
		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_createStatus_invalid_envelopes() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			e2.Sent__c = null; // make invalid
			update e2;
			Envelope.Status es1 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.fromString(e1.DocuSignId__c),
				Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, e1.Sent__c,
				Datetime.now(), 's1', null, Datetime.now());
			Envelope.Status es2 = new Envelope.Status(null, new Entity(UserInfo.getUserId()), UUID.fromString(e2.DocuSignId__c),
				Envelope.STATUS_CREATED, UserInfo.getName(), UserInfo.getUserEmail(), null, e2.Sent__c,
				Datetime.now(), 's2', null, Datetime.now());

			Test.startTest();
			try {
				StatusService.createStatus(new List<Envelope.Status> { es1, es2 });
				throw new AssertException('Expected createStatus to fail');
			} catch (ValidationException ex) {
				System.assertEquals(Label.CannotCreateStatus + '\n' + Label.EnvelopesMustBeSent, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_createStatus_valid() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Recipient e1r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e1.Id));
			Recipient e1r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e1.Id));
			Envelope e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			Recipient e2r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e2.Id));
			Envelope.Status es1 = e1.toEnvelopeStatus().addRecipients(new List<Recipient.Status> {
				e1r1.toRecipientStatus(e1.sent),
				e1r2.toRecipientStatus(e1.sent)
			});
			Envelope.Status es2 = e2.toEnvelopeStatus().addRecipients(new List<Recipient.Status> {
				e2r1.toRecipientStatus(e1.sent)
			});

			Test.startTest();
			List<Envelope.Status> result = StatusService.createStatus(new List<Envelope.Status> { es1, es2 });
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

	static testMethod void test_getStatus_unauthorized() {
		Envelope e1, e2;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			try {
				StatusService.getStatus(new Set<UUID> { e1.docuSignId, e2.docuSignId });
				throw new AssertException('Expected createStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_getStatus_no_update() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Envelope.Status es1 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e1));
			Envelope.Status es2 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e2));

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> { es1.docuSignId, es2.docuSignId });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es1.id, result[0].id);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(es2.id, result[1].id);
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

	static testMethod void test_getStatus_with_update() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			es1.LastStatusUpdate__c = null;
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(e2);
			es2.LastStatusUpdate__c = Datetime.now().addMinutes(-16);
			update new List<EnvelopeStatus__c> { es1, es2 };

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> {
				UUID.fromString(es1.DocuSignId__c), UUID.fromString(es2.DocuSignId__c)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es1.id, result[0].id);
			System.assertNotEquals(null, result[0].lastStatusUpdate);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(es2.id, result[1].id);
			System.assertNotEquals(null, result[1].lastStatusUpdate);
		}
	}

	static testMethod void test_getStatus_not_exists() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Envelope.Status es1 = StatusService.DB.convert(TestUtils.createEnvelopeStatus(e1));
			Envelope.Status es2 = EnvelopeService.DB.convert(e2).toEnvelopeStatus();
			Set<String> ids = new Set<String> { String.valueOf(es1.docuSignId), String.valueOf(es2.docuSignId) };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :ids];
			System.assertEquals(1, ess.size());

			Test.startTest();
			List<Envelope.Status> result = StatusService.getStatus(new Set<UUID> { es1.docuSignId, es2.docuSignId });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(es1.id, result[0].id);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);

			ess = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :ids];
			System.assertEquals(2, ess.size());
		}
	}

	static testMethod void test_deleteStatus_unauthorized() {
		Envelope e1, e2;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			e2 = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			try {
				StatusService.deleteStatus(new Set<UUID> { e1.docuSignId, e2.docuSignId });
				throw new AssertException('Expected deleteStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_deleteStatus_not_found() {
		System.runAs(TestUtils.createDocuSignUser()) {
			UUID dseId1 = UUID.randomUUID();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);

			Test.startTest();
			try {
				StatusService.deleteStatus(new Set<UUID> { dseId1 });
				throw new AssertException('Expected deleteStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.EnvelopeNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_deleteStatus_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.fromString(e1.DocuSignId__c);
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(dseId1);
			Envelope__c e2 = TestUtils.createEnvelope();
			UUID dseId2 = UUID.fromString(e2.DocuSignId__c);
			EnvelopeStatus__c es2 = TestUtils.createEnvelopeStatus(dseId2);

			Test.startTest();
			Boolean result = StatusService.deleteStatus(new Set<UUID> { dseId1, dseId2 });
			Test.stopTest();

			System.assert(result);
			Set<String> ids = new Set<String> { e1.DocuSignId__c, e2.DocuSignId__c };
			List<EnvelopeStatus__c> ess = [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :ids];
			System.assert(Collection.isEmpty(ess));
		}
	}

	static testMethod void test_resendEnvelope_unauthorized() {
		Envelope e1;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_resendEnvelope_invalid_status() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.fromString(e1.DocuSignId__c);
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

	static testMethod void test_resendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			UUID dseId = UUID.randomUUID();
			Envelope__c e = TestUtils.createEnvelope(dseId);
			EnvelopeStatus__c es = TestUtils.createEnvelopeStatus(e);

			Test.startTest();
			System.assert(StatusService.resendEnvelope(dseId));
			Test.stopTest();
		}
	}

	static testMethod void test_resendRecipients_unauthorized() {
		Envelope e1;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_resendRecipients_invalid_status() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.fromString(e1.DocuSignId__c);
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

	static testMethod void test_resendRecipients_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			UUID dseId = UUID.randomUUID();
			Envelope__c e = TestUtils.createEnvelope(dseId);
			EnvelopeStatus__c es = TestUtils.createEnvelopeStatus(e);

			Test.startTest();
			List<Recipient.ResendResult> result = StatusService.resendRecipients(dseId, new List<Recipient> {
				Recipient.fromSource('n', 'r@unit.test', null, null, null)
			});
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	static testMethod void test_voidEnvelope_unauthorized() {
		Envelope e1;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_voidEnvelope_not_found() {
		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_voidEnvelope_invalid_status() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.fromString(e1.DocuSignId__c);
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

	static testMethod void test_voidEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Envelope__c e1 = TestUtils.createEnvelope();
			UUID dseId1 = UUID.fromString(e1.DocuSignId__c);
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

	static testMethod void test_correctEnvelope_unauthorized() {
		Envelope e1;
		System.runAs(TestUtils.createDocuSignUser()) {
			e1 = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_correctEnvelope_not_found() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();

			Test.startTest();
			try {
				StatusService.getCorrectUrl(UUID.fromString(e1.DocuSignId__c), new Url('https://unit.test/return'));
				throw new AssertException('Expected correctEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.StatusNotFound_1, new List<String> {
					e1.DocuSignId__c
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_correctEnvelope_invalid_status() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(UUID.fromString(e1.DocuSignId__c));
			es1.Status__c = Envelope.STATUS_VOIDED;
			update es1;

			Test.startTest();
			try {
				StatusService.getCorrectUrl(UUID.fromString(e1.DocuSignId__c), new Url('https://unit.test/return'));
				throw new AssertException('Expected correctEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotCorrectEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_correctEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(UUID.fromString(e1.DocuSignId__c));
			es1.Status__c = Envelope.STATUS_SENT;
			update es1;

			Test.startTest();
			Url result = StatusService.getCorrectUrl(UUID.fromString(e1.DocuSignId__c), new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	static testMethod void test_viewEnvelope_invalid() {
		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_viewEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(UUID.fromString(e1.DocuSignId__c));

			Test.startTest();
			Url result = StatusService.getViewUrl(UUID.fromString(e1.DocuSignId__c), new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}
}
