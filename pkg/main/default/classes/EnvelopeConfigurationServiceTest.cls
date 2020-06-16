@IsTest
private class EnvelopeConfigurationServiceTest {

	@IsTest
	static void test_Database_convert_for_insert() {
		EnvelopeConfiguration ec = new EnvelopeConfiguration(
			null,
			UUID.randomUUID().toString(),
			'Opportunity',
			UUID.randomUUID(),
			null,
			null,
			new List<CustomField> {
				CustomField.newListField('lf', 'lfV1', new List<String> { 'lfV1', 'lfV2', 'lfV3' }, false, false),
				CustomField.newTextField('tf', 'tfV', true, true)
			},
			new Notifications(true, 10, 1, true, 90, 80),
			'subject',
			'message',
			new List<Tab> {
				Tab.newMergeField(Tab.TYPE_TEXT, 'Name', true, true),
				Tab.newMergeField(Tab.TYPE_TEXT, 'Account.Name', true, false)
			},
			new Envelope.Permissions(
				true,
				false,
				true,
				false,
				true,
				false),
			new Envelope.Options(
				true,
				null,
				null,
				null),
			true);

		Test.startTest();
		EnvelopeConfiguration__c result = EnvelopeConfigurationService.DB.convert(ec, false);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(null, result.Id);
		System.assertEquals(ec.name, result.Name);
		System.assertEquals(ec.sourceObject, result.SourceObject__c);
		System.assertEquals(String.valueOf(ec.docuSignId), result.DocuSignId__c);
		System.assertEquals(JSON.serialize(ec.customFields), result.CustomFields__c);
		System.assertEquals(JSON.serialize(ec.notifications), result.Notifications__c);
		System.assertEquals(ec.emailSubject, result.EmailSubject__c);
		System.assertEquals(ec.emailMessage, result.EmailMessage__c);
		System.assertEquals(JSON.serialize(ec.mergeFields), result.MergeFields__c);
		System.assertEquals(JSON.serialize(ec.senderPermissions), result.SenderPermissions__c);
		System.assertEquals(ec.isDraft, result.IsDraft__c);
	}

	@IsTest
	static void test_Database_convert_for_update() {
		EnvelopeConfiguration ec = new EnvelopeConfiguration(
			TestUtils.createEnvelopeConfiguration().Id,
			UUID.randomUUID().toString(),
			'Opportunity',
			UUID.randomUUID(),
			null, // Documents are not converted to custom objects. They must have been previously linked.
			null,
			new List<CustomField> {
				CustomField.newListField('lf', 'lfV1', new List<String> { 'lfV1', 'lfV2', 'lfV3' }, false, false),
				CustomField.newTextField('tf', 'tfV', true, true)
			},
			new Notifications(true, 10, 1, true, 90, 80),
			'subject',
			'message',
			new List<Tab> {
				Tab.newMergeField(Tab.TYPE_TEXT, 'Name', true, true),
				Tab.newMergeField(Tab.TYPE_TEXT, 'Account.Name', true, false)
			},
			new Envelope.Permissions(
				true,
				false,
				true,
				false,
				true,
				false),
			new Envelope.Options(
				true,
				null,
				null,
				null),
			false);

		Test.startTest();
		EnvelopeConfiguration__c result = EnvelopeConfigurationService.DB.convert(ec, true);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(ec.id, result.Id);
		System.assertEquals(ec.name, result.Name);
		System.assertEquals(null, result.SourceObject__c);
		System.assertEquals(String.valueOf(ec.docuSignId), result.DocuSignId__c);
		System.assertEquals(JSON.serialize(ec.customFields), result.CustomFields__c);
		System.assertEquals(JSON.serialize(ec.notifications), result.Notifications__c);
		System.assertEquals(ec.emailSubject, result.EmailSubject__c);
		System.assertEquals(ec.emailMessage, result.EmailMessage__c);
		System.assertEquals(JSON.serialize(ec.mergeFields), result.MergeFields__c);
		System.assertEquals(JSON.serialize(ec.senderPermissions), result.SenderPermissions__c);
		System.assertEquals(ec.isDraft, result.IsDraft__c);
	}

	@IsTest
	static void test_Database_convert_EnvelopeConfiguration() {
		EnvelopeConfiguration ec = new EnvelopeConfiguration(
			null,
			UUID.randomUUID().toString(),
			'so',
			UUID.randomUUID(),
			new List<Document>(),
			new List<Recipient>(),
			new List<CustomField> {
				CustomField.newTextField('tf', 'tv', false, true),
				CustomField.newListField('lf', 'lv2', new List<String> { 'lv1', 'lv2', 'lv3' }, true, false)
			},
			new Notifications(true, 2, 1, true, 9, 7, false),
			's',
			'm',
			new List<Tab> {
				Tab.newMergeField(Tab.TYPE_FORMULA, 'mf1.p1', false, false),
				Tab.newMergeField(Tab.TYPE_NUMBER, 'mf2.p2', true, true)
			},
			Envelope.DEFAULT_PERMISSIONS,
			Envelope.DEFAULT_OPTIONS,
			false);

		Test.startTest();
		EnvelopeConfiguration result = EnvelopeConfigurationService.DB.convert(
			EnvelopeConfigurationService.DB.convert(ec, false));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(ec.id, result.id);
		System.assertEquals(ec.name, result.name);
		System.assertEquals(ec.sourceObject, result.sourceObject);
		System.assertEquals(ec.docuSignId, result.docuSignId);
		System.assertEquals(Collection.size(ec.customFields), Collection.size(result.customFields));
		System.assertEquals(Collection.size(ec.documents), Collection.size(result.documents));
		System.assertEquals(Collection.size(ec.recipients), Collection.size(result.recipients));
		System.assertNotEquals(null, result.notifications);
		System.assertEquals(ec.notifications.remind, result.notifications.remind);
		System.assertEquals(ec.notifications.remindAfterDays, result.notifications.remindAfterDays);
		System.assertEquals(ec.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
		System.assertEquals(ec.notifications.expires, result.notifications.expires);
		System.assertEquals(ec.notifications.expireAfterDays, result.notifications.expireAfterDays);
		System.assertEquals(ec.notifications.expireWarnDays, result.notifications.expireWarnDays);
		System.assertEquals(ec.notifications.updateChatter, result.notifications.updateChatter);
		System.assertEquals(ec.emailSubject, result.emailSubject);
		System.assertEquals(ec.emailMessage, result.emailMessage);
		System.assertEquals(Collection.size(ec.mergeFields), Collection.size(result.mergeFields));
		System.assertNotEquals(null, result.senderPermissions);
		System.assertEquals(ec.isDraft, result.isDraft);
	}

	@IsTest
	static void test_Database_convert_Documents() {
		Id ecId = TestUtils.createEnvelopeConfiguration().Id;
		ContentVersion cv = TestUtils.createContentVersion();
		EnvelopeConfiguration.TemplateDocument d1 = new EnvelopeConfiguration.TemplateDocument(
			null,
			cv.ContentDocumentId,
			1,
			cv.Title,
			cv.FileExtension,
			true,
			false);
		EnvelopeConfiguration.SourceFiles d2 = new EnvelopeConfiguration.SourceFiles(
			null,
			new Query.Filter(
				'FILTER_BY',
				'ORDER_BY',
				10),
			2,
			false,
			true);
		List<Document> ds = new List<Document> { d1, d2 };

		Test.startTest();
		List<Document> result = EnvelopeConfigurationService.DB.convert(
			EnvelopeConfigurationService.DB.convert(ecId, ds));
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		System.assertNotEquals(null, result[0]);
		System.assert(result[0] instanceof EnvelopeConfiguration.TemplateDocument);
		EnvelopeConfiguration.TemplateDocument td = (EnvelopeConfiguration.TemplateDocument)result[0];
		System.assert(result[1] instanceof EnvelopeConfiguration.SourceFiles);
		EnvelopeConfiguration.SourceFiles sfs = (EnvelopeConfiguration.SourceFiles)result[1];
		System.assertEquals(d1.id, td.id);
		System.assertEquals(d1.sourceId, td.sourceId);
		System.assertEquals(d1.sequence, td.sequence);
		System.assertEquals(d1.name, td.name);
		System.assertEquals(d1.extension, td.extension);
		System.assertEquals(d1.readOnly, td.readOnly);
		System.assertEquals(d1.required, td.required);
		System.assertNotEquals(null, result[0]);
		System.assertEquals(d2.id, sfs.id);
		System.assertNotEquals(null, sfs.filter);
		System.assertEquals(d2.filter.filterBy, sfs.filter.filterBy);
		System.assertEquals(d2.filter.orderBy, sfs.filter.orderBy);
		System.assertEquals(d2.filter.maximumRecords, sfs.filter.maximumRecords);
		System.assertEquals(d2.sequence, sfs.sequence);
		System.assertEquals(d2.readOnly, sfs.readOnly);
		System.assertEquals(d2.required, sfs.required);
	}

	@IsTest
	static void test_Database_convert_Recipients() {
		Id ecId = TestUtils.createEnvelopeConfiguration().Id;
		EnvelopeConfiguration.LookupRecipient r1 = (EnvelopeConfiguration.LookupRecipient)new EnvelopeConfiguration.LookupRecipient(
			new Query.Relationship(
				true,
				'rn1',
				'rl1',
				'rt1'),
			Recipient.TYPE_AGENT,
			1,
			'r1',
			false,
			true)
			.withAuthentication(new Recipient.Authentication(
				'1111',
				true,
				new List<String> { '1111111' }))
			.withEmailSettings(new Recipient.EmailSettings(
				'l1',
				'll1',
				's1',
				'm1'));
		EnvelopeConfiguration.RelatedRecipients r2 = (EnvelopeConfiguration.RelatedRecipients)new EnvelopeConfiguration.RelatedRecipients(
			new Query.Relationship(
				false,
				'rn2',
				'rl2',
				'rt2'),
			new Query.Filter(
				'filterBy1',
				'orderBy1',
				11),
			Recipient.TYPE_WITNESS,
			2,
			true,
			new List<String> { 'r1', 'r2', 'r3' },
			true,
			false)
			.withAuthentication(new Recipient.Authentication(
				'1111',
				true,
				new List<String> { '1111111' }))
			.withEmailSettings(new Recipient.EmailSettings(
				'l1',
				'll1',
				's1',
				'm1'));
		Recipient r3 = new Recipient(
			null,
			Recipient.TYPE_SIGNER,
			3,
			3,
			new Recipient.Role('Signer 1'),
			UUID.randomUUID().toString(),
			UUID.randomUUID() + '@unit.test',
			new SigningGroup(1111, 'sg1'),
			'1111',
			new Recipient.Authentication(
				'1111',
				true,
				new List<String> { '1111' }),
			'n1',
			new Recipient.EmailSettings(
				'l1',
				null,
				's1',
				's2'),
			null,
			null,
			true,
			new Entity(UserInfo.getUserId()),
			true,
			true);
		List<Recipient> rs = new List<Recipient> { r1, r2, r3 };

		Test.startTest();
		List<Recipient> result = EnvelopeConfigurationService.DB.convert(
			EnvelopeConfigurationService.DB.convert(ecId, rs));
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		System.assertNotEquals(null, result[0]);
		System.assert(result[0] instanceof EnvelopeConfiguration.LookupRecipient);
		EnvelopeConfiguration.LookupRecipient lr = (EnvelopeConfiguration.LookupRecipient)result[0];
		System.assertEquals(r1.id, lr.id);
		System.assertNotEquals(null, lr.relationship);
		System.assertEquals(r1.relationship.isLookup, lr.relationship.isLookup);
		System.assertEquals(r1.relationship.name, lr.relationship.name);
		System.assertEquals(r1.relationship.label, lr.relationship.label);
		System.assertEquals(r1.relationship.relatesTo, lr.relationship.relatesTo);
		System.assertEquals(r1.type, lr.type);
		System.assertEquals(r1.sequence, lr.sequence);
		System.assertEquals(r1.routingOrder, lr.routingOrder);
		System.assertNotEquals(null, lr.role);
		System.assertEquals(r1.role.name, lr.role.name);
		System.assertEquals(r1.name, lr.name);
		System.assertEquals(r1.email, lr.email);
		System.assertEquals(null, lr.signingGroup);
		System.assertNotEquals(null, lr.authentication);
		System.assertEquals(r1.authentication.accessCode, lr.authentication.accessCode);
		System.assertEquals(r1.authentication.idCheckRequired, lr.authentication.idCheckRequired);
		System.assertEquals(r1.authentication.smsPhoneNumbers, lr.authentication.smsPhoneNumbers);
		System.assertEquals(r1.note, lr.note);
		System.assertNotEquals(null, lr.emailSettings);
		System.assertEquals(r1.emailSettings.language, lr.emailSettings.language);
		System.assertEquals(r1.emailSettings.subject, lr.emailSettings.subject);
		System.assertEquals(r1.emailSettings.message, lr.emailSettings.message);
		System.assertEquals(r1.hostName, lr.hostName);
		System.assertEquals(r1.hostEmail, lr.hostEmail);
		System.assertEquals(r1.signNow, lr.signNow);
		System.assertEquals(null, lr.source);
		System.assertEquals(r1.readOnly, lr.readOnly);
		System.assertEquals(r1.required, lr.required);

		System.assertNotEquals(null, result[1]);
		System.assert(result[1] instanceof EnvelopeConfiguration.RelatedRecipients);
		EnvelopeConfiguration.RelatedRecipients rrs = (EnvelopeConfiguration.RelatedRecipients)result[1];
		System.assertEquals(r2.id, rrs.id);
		System.assertNotEquals(null, rrs.relationship);
		System.assertEquals(r2.relationship.isLookup, rrs.relationship.isLookup);
		System.assertEquals(r2.relationship.name, rrs.relationship.name);
		System.assertEquals(r2.relationship.label, rrs.relationship.label);
		System.assertEquals(r2.relationship.relatesTo, rrs.relationship.relatesTo);
		System.assertNotEquals(null, rrs.filter);
		System.assertEquals(r2.filter.filterBy, rrs.filter.filterBy);
		System.assertEquals(r2.filter.orderBy, rrs.filter.orderBy);
		System.assertEquals(r2.filter.maximumRecords, rrs.filter.maximumRecords);
		System.assertEquals(r2.incrementRoutingOrder, rrs.incrementRoutingOrder);
		System.assertEquals(r2.type, rrs.type);
		System.assertEquals(r2.sequence, rrs.sequence);
		System.assertEquals(r2.routingOrder, rrs.routingOrder);
		System.assertNotEquals(null, rrs.role);
		System.assertEquals(r2.role.name, rrs.role.name);
		System.assertEquals(r2.roles, rrs.roles);
		System.assertEquals(r2.name, rrs.name);
		System.assertEquals(r2.email, rrs.email);
		System.assertEquals(null, rrs.signingGroup);
		System.assertNotEquals(null, rrs.authentication);
		System.assertEquals(r2.authentication.accessCode, rrs.authentication.accessCode);
		System.assertEquals(r2.authentication.idCheckRequired, rrs.authentication.idCheckRequired);
		System.assertEquals(r2.authentication.smsPhoneNumbers, rrs.authentication.smsPhoneNumbers);
		System.assertEquals(r2.note, rrs.note);
		System.assertNotEquals(null, rrs.emailSettings);
		System.assertEquals(r2.emailSettings.language, rrs.emailSettings.language);
		System.assertEquals(r2.emailSettings.subject, rrs.emailSettings.subject);
		System.assertEquals(r2.emailSettings.message, rrs.emailSettings.message);
		System.assertEquals(r2.hostName, rrs.hostName);
		System.assertEquals(r2.hostEmail, rrs.hostEmail);
		System.assertEquals(r2.signNow, rrs.signNow);
		System.assertEquals(null, rrs.source);
		System.assertEquals(r2.readOnly, rrs.readOnly);
		System.assertEquals(r2.required, rrs.required);

		System.assertNotEquals(null, result[2]);
		Recipient r = result[2];
		System.assertEquals(r3.id, r.id);
		System.assertEquals(r3.type, r.type);
		System.assertEquals(r3.sequence, r.sequence);
		System.assertEquals(r3.routingOrder, r.routingOrder);
		System.assertNotEquals(null, r.role);
		System.assertEquals(r3.role.name, r.role.name);
		System.assertEquals(r3.name, r.name);
		System.assertEquals(r3.email, r.email);
		System.assertNotEquals(null, r.signingGroup);
		System.assertEquals(r3.signingGroup.id, r.signingGroup.id);
		System.assertEquals(r3.signingGroup.name, r.signingGroup.name);
		System.assertNotEquals(null, r.authentication);
		System.assertEquals(r3.authentication.accessCode, r.authentication.accessCode);
		System.assertEquals(r3.authentication.idCheckRequired, r.authentication.idCheckRequired);
		System.assertEquals(r3.authentication.smsPhoneNumbers, r.authentication.smsPhoneNumbers);
		System.assertEquals(r3.note, r.note);
		System.assertNotEquals(null, r.emailSettings);
		System.assertEquals(r3.emailSettings.language, r.emailSettings.language);
		System.assertEquals(r3.emailSettings.subject, r.emailSettings.subject);
		System.assertEquals(r3.emailSettings.message, r.emailSettings.message);
		System.assertEquals(r3.hostName, r.hostName);
		System.assertEquals(r3.hostEmail, r.hostEmail);
		System.assertEquals(r3.signNow, r.signNow);
		System.assertEquals(r3.source, r.source);
		System.assertEquals(r3.readOnly, r.readOnly);
		System.assertEquals(r3.required, r.required);
	}

	@IsTest
	static void test_validate_document_invalid_null() {
		Document d = null;
		Integer i = 2;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(d, i);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.DocumentElements,
			i,
			Label.UndefinedDocument
		}), result.toString());
	}

	@IsTest
	static void test_validate_document_invalid_TemplateDocument() {
		Document d1 = new EnvelopeConfiguration.TemplateDocument(
			null,
			UserInfo.getUserId(),
			1,
			'',
			'  ',
			false,
			false);
		ContentVersion cv = TestUtils.createContentVersion();
		Document d2 = new EnvelopeConfiguration.TemplateDocument(
			null,
			cv.ContentDocumentId,
			2,
			'n2',
			'invalid',
			false,
			false);
		Integer i1 = 2, i2 = 3;

		Test.startTest();
		ValidationResult result1 = EnvelopeConfigurationService.validate(d1, i1);
		ValidationResult result2 = EnvelopeConfigurationService.validate(d2, i2);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(3, Collection.size(result1.messages));
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.DocumentElements,
			i1,
			Label.InvalidContentDocumentSource
		}), result1.messages[0]);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.DocumentElements,
			i1,
			Label.UndefinedName
		}), result1.messages[1]);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.DocumentElements,
			i1,
			Label.UndefinedExtension
		}), result1.messages[2]);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.DocumentElements,
			i2,
			Label.InvalidFileType
		}), result2.toString());
	}

	@IsTest
	static void test_validate_document_invalid_type() {
		Document d = Document.fromTemplate(UUID.randomUUID(), 't1');
		Integer i = 0;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(d, i);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.DocumentElements,
			i,
			Label.InvalidType
		}), result.toString());
	}

	@IsTest
	static void test_validate_document_valid() {
		ContentVersion cv = TestUtils.createContentVersion();
		Document d1 = new EnvelopeConfiguration.TemplateDocument(
			null,
			cv.ContentDocumentId,
			1,
			cv.Title,
			cv.FileExtension,
			false,
			false);
		Document d2 = new EnvelopeConfiguration.SourceFiles(
			null,
			null,
			2,
			false,
			false);
		Integer i1 = 0, i2 = 1;

		Test.startTest();
		ValidationResult result1 = EnvelopeConfigurationService.validate(d1, i1);
		ValidationResult result2 = EnvelopeConfigurationService.validate(d2, i2);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertNotEquals(null, result2);
		System.assert(result2.isValid);
	}

	@IsTest
	static void test_validate_relationship_null() {
		Query.Relationship relationship = null;
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = null;
		Boolean expectLookup = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			Label.UndefinedRelationship
		}), result.toString());
	}

	@IsTest
	static void test_validate_relationship_blank() {
		Query.Relationship relationship = new Query.Relationship(
			true,
			'',
			null,
			'\t');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = null;
		Boolean expectLookup = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(3, Collection.size(result.messages));
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			Label.InvalidRelationshipType
		}), result.messages[0]);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			Label.UndefinedRelationshipName
		}), result.messages[1]);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			Label.UndefinedRelatedObject
		}), result.messages[2]);
	}

	@IsTest
	static void test_validate_relationship_invalid_type() {
		Query.Relationship relationship = new Query.Relationship(
			true,
			'Owner',
			'Owner',
			'Invalid');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = null;
		Boolean expectLookup = true;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			String.format(Label.InvalidRelatedObject_1, new List<Object> { relationship.relatesTo })
		}), result.toString());
	}

	@IsTest
	static void test_validate_relationship_unsupported_type() {
		Query.Relationship relationship = new Query.Relationship(
			true,
			'Owner',
			'Owner',
			'Opportunity');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = null;
		Boolean expectLookup = true;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			String.format(Label.UnsupportedRelatedObject_1, new List<Object> { relationship.relatesTo })
		}), result.toString());
	}

	@IsTest
	static void test_validate_relationship_invalid_lookup() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Query.Relationship relationship = new Query.Relationship(
			true,
			'Invalid',
			'Invalid',
			'User');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();
		Boolean expectLookup = true;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			String.format(Label.InvalidRelationship_1, new List<Object> { relationship.name })
		}), result.toString());
	}

	@IsTest
	static void test_validate_relationship_invalid_child() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Query.Relationship relationship = new Query.Relationship(
			false,
			'OpportunityContactRoles',
			'Opportunity Contact Role',
			'User');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();
		Boolean expectLookup = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			String.format(Label.InvalidRelationship_1, new List<Object> { relationship.name })
		}), result.toString());
	}

	@IsTest
	static void test_validate_relationship_valid_lookup() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Query.Relationship relationship = new Query.Relationship(
			true,
			'Owner',
			'Owner',
			'User');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();
		Boolean expectLookup = true;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isValid);
	}

	@IsTest
	static void test_validate_relationship_valid_child() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Query.Relationship relationship = new Query.Relationship(
			false,
			'OpportunityContactRoles',
			'Opportunity Contact Roles',
			'OpportunityContactRole');
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();
		Boolean expectLookup = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			relationship,
			index,
			sourceDescribe,
			expectLookup);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isValid);
	}

	@IsTest
	static void test_validate_recipient_invalid_null() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Recipient recipient = null;
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			recipient,
			index,
			sourceDescribe);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			Label.UndefinedRecipient
		}), result.toString());
	}

	@IsTest
	static void test_validate_recipient_invalid_LookupRecipient() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Recipient recipient = new EnvelopeConfiguration.LookupRecipient(
			null,
			Recipient.TYPE_SIGNER,
			1,
			null,
			false,
			false);
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			recipient,
			index,
			sourceDescribe);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
	}

	@IsTest
	static void test_validate_recipient_invalid_RelatedRecipients() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Recipient recipient = new EnvelopeConfiguration.RelatedRecipients(
			null,
			null,
			Recipient.TYPE_SIGNER,
			1,
			true,
			null,
			false,
			false);
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			recipient,
			index,
			sourceDescribe);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
	}

	@IsTest
	static void test_validate_recipient_invalid_placeholder() {
		Recipient recipient = Recipient.fromSource(
			null,
			null,
			null,
			null,
			null);
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			recipient,
			index,
			sourceDescribe);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			Label.PlaceholderRecipientMustHaveRole
		}), result.toString());
	}

	@IsTest
	static void test_validate_recipient_invalid_source() {
		Recipient recipient = Recipient.fromSource(
			null,
			null,
			null,
			'r1',
			new Entity(UserInfo.getOrganizationId()));
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			recipient,
			index,
			sourceDescribe);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.RecipientElements,
			index,
			String.format(Label.CannotResolveRecipientSource_1, new List<Object> { Organization.getSObjectType() })
		}), result.toString());
	}

	@IsTest
	static void test_validate_recipient_valid() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Recipient recipient = Recipient.fromSource(
			null,
			null,
			null,
			'r1',
			new Entity(UserInfo.getUserId()));
		Integer index = 0;
		DescribeSObjectResult sourceDescribe = Opportunity.getSObjectType().getDescribe();

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			recipient,
			index,
			sourceDescribe);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isValid);
	}

	@IsTest
	static void test_validate_custom_field_null() {
		CustomField customField = null;
		Integer index = 0;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			customField,
			index);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.CustomFieldElements,
			index,
			Label.UndefinedCustomField
		}), result.toString());
	}

	@IsTest
	static void test_validate_custom_field_invalid() {
		CustomField customField = CustomField.newListField(
			'  ',
			null,
			new List<String>(),
			true,
			false);
		Integer index = 0;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			customField,
			index);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(3, Collection.size(result.messages));
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.CustomFieldElements,
			index,
			Label.UndefinedName
		}), result.messages[0]);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.CustomFieldElements,
			index,
			Label.UndefinedCustomFieldValue
		}), result.messages[1]);
		System.assertEquals(String.format(Label.ArrayError_3, new List<Object> {
			Label.CustomFieldElements,
			index,
			Label.UndefinedList
		}), result.messages[2]);
	}

	@IsTest
	static void test_validate_custom_field_valid() {
		CustomField customField = CustomField.newListField(
			'n1',
			'v3',
			new List<String> { 'v1', 'v2', 'v3' },
			true,
			false);
		Integer index = 0;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			customField,
			index);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isValid);
	}

	@IsTest
	static void test_validate_null() {
		EnvelopeConfiguration ec = null;
		Boolean forUpdate = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			ec,
			forUpdate);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(Label.UndefinedEnvelopeConfiguration, result.toString());
	}

	@IsTest
	static void test_validate_blank() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		ContentVersion cv = TestUtils.createContentVersion();
		EnvelopeConfiguration ec = new EnvelopeConfiguration(
			null,
			'',
			'\t',
			null,
			new List<Document> {
				new EnvelopeConfiguration.TemplateDocument(
					null,
					cv.ContentDocumentId,
					1,
					cv.Title,
					cv.FileExtension,
					false,
					false),
				new EnvelopeConfiguration.SourceFiles(
					null,
					null,
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
					false),
				new EnvelopeConfiguration.RelatedRecipients(
					new Query.Relationship(
						false,
						'OpportunityContactRoles',
						'Opportunity Contact Roles',
						'OpportunityContactRole'),
					null,
					Recipient.TYPE_SIGNER,
					2,
					true,
					new List<String> { 'r1', 'r2' },
					false,
					false)
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
			's',
			'm',
			new List<Tab> {
				Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', true, true),
				Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
			},
			Envelope.DEFAULT_PERMISSIONS,
			Envelope.DEFAULT_OPTIONS,
			true);
		Boolean forUpdate = true;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			ec,
			forUpdate);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(3, Collection.size(result.messages));
		System.assertEquals(Label.UndefinedId, result.messages[0]);
		System.assertEquals(Label.UndefinedName, result.messages[1]);
		System.assertEquals(Label.UndefinedSourceObject, result.messages[2]);
	}

	@IsTest
	static void test_validate_invalid_source() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		ContentVersion cv = TestUtils.createContentVersion();
		EnvelopeConfiguration ec = new EnvelopeConfiguration(
			null,
			UUID.randomUUID().toString(),
			'Invalid',
			null,
			new List<Document> {
				new EnvelopeConfiguration.TemplateDocument(
					null,
					cv.ContentDocumentId,
					1,
					cv.Title,
					cv.FileExtension,
					false,
					false),
				new EnvelopeConfiguration.SourceFiles(
					null,
					null,
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
					false),
				new EnvelopeConfiguration.RelatedRecipients(
					new Query.Relationship(
						false,
						'OpportunityContactRoles',
						'Opportunity Contact Roles',
						'OpportunityContactRole'),
					null,
					Recipient.TYPE_SIGNER,
					2,
					true,
					new List<String> { 'r1', 'r2' },
					false,
					false)
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
			's',
			'm',
			new List<Tab> {
				Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', true, true),
				Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
			},
			Envelope.DEFAULT_PERMISSIONS,
			Envelope.DEFAULT_OPTIONS,
			true);
		Boolean forUpdate = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			ec,
			forUpdate);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(Label.InvalidSourceObject, result.toString());
	}

	@IsTest
	static void test_validate_valid() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		ContentVersion cv = TestUtils.createContentVersion();
		EnvelopeConfiguration ec = new EnvelopeConfiguration(
			null,
			UUID.randomUUID().toString(),
			'Opportunity',
			null,
			new List<Document> {
				new EnvelopeConfiguration.TemplateDocument(
					null,
					cv.ContentDocumentId,
					1,
					cv.Title,
					cv.FileExtension,
					false,
					false),
				new EnvelopeConfiguration.SourceFiles(
					null,
					null,
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
					false),
				new EnvelopeConfiguration.RelatedRecipients(
					new Query.Relationship(
						false,
						'OpportunityContactRoles',
						'Opportunity Contact Roles',
						'OpportunityContactRole'),
					null,
					Recipient.TYPE_SIGNER,
					2,
					true,
					new List<String> { 'r1', 'r2' },
					false,
					false)
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
			's',
			'm',
			new List<Tab> {
				Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', true, true),
				Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
			},
			Envelope.DEFAULT_PERMISSIONS,
			Envelope.DEFAULT_OPTIONS,
			true);
		Boolean forUpdate = false;

		Test.startTest();
		ValidationResult result = EnvelopeConfigurationService.validate(
			ec,
			forUpdate);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isValid);
	}

	@IsTest
	static void test_getTemplateRecipients() {
		// Related recipients, single role
		Recipient r1 = new EnvelopeConfiguration.RelatedRecipients(
			null,
			null,
			Recipient.TYPE_SIGNER,
			null,
			false,
			new List<String> { 'r1' },
			true,
			true);
		// Vanilla recipient
		Recipient r2 = Recipient.fromSource(
			'r2',
			'r2@unit.test',
			null,
			'r2',
			null)
			.withRoutingOrder(2);
		// Related recipient, 2 roles
		Recipient r3 = new EnvelopeConfiguration.RelatedRecipients(
			null,
			null,
			Recipient.TYPE_SIGNER,
			3,
			false,
			new List<String> { 'r3_1', 'r3_2' },
			true,
			true);
		Recipient r4 = new EnvelopeConfiguration.LookupRecipient(
			null,
			Recipient.TYPE_CARBON_COPY,
			3,
			'r4',
			true,
			true);
		List<Recipient> rs = new List<Recipient> { r1, r2, r3, r4 };

		Test.startTest();
		List<Recipient> result = EnvelopeConfigurationService.getTemplateRecipients(rs);
		Test.stopTest();

		System.assertEquals(5, Collection.size(result));

		System.assertNotEquals(null, result[0]);
		System.assertEquals(1, result[0].sequence);
		System.assertEquals(1, result[0].routingOrder);
		System.assertEquals('r1', result[0].getRoleName());

		System.assertNotEquals(null, result[1]);
		System.assertEquals(2, result[1].sequence);
		System.assertEquals(2, result[1].routingOrder);
		System.assertEquals('r2', result[1].getRoleName());

		System.assertNotEquals(null, result[2]);
		System.assertEquals(3, result[2].sequence);
		System.assertEquals(3, result[2].routingOrder);
		System.assertEquals('r3_1', result[2].getRoleName());

		System.assertNotEquals(null, result[3]);
		System.assertEquals(4, result[3].sequence);
		System.assertEquals(3, result[3].routingOrder);
		System.assertEquals('r3_2', result[3].getRoleName());

		System.assertNotEquals(null, result[4]);
		System.assertEquals(5, result[4].sequence);
		System.assertEquals(3, result[4].routingOrder);
		System.assertEquals('r4', result[4].getRoleName());
	}

	@IsTest
	static void test_createEnvelopeConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.createEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createEnvelopeConfiguration_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.createEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (ValidationException ex) {
				System.assertNotEquals(null, ex.details);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createEnvelopeConfiguration_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ContentVersion cv = TestUtils.createContentVersion();
			EnvelopeConfiguration ec = new EnvelopeConfiguration(
				null,
				UUID.randomUUID().toString(),
				'Opportunity',
				UUID.randomUUID(),
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						cv.ContentDocumentId,
						1,
						cv.Title,
						cv.FileExtension,
						false,
						true),
					new EnvelopeConfiguration.SourceFiles(
						null,
						null,
						2,
						true,
						false)
				},
				new List<Recipient> {
					new EnvelopeConfiguration.LookupRecipient(
						new Query.Relationship(
							true,
							'Owner',
							'Owner',
							'User'),
						Recipient.TYPE_EMBEDDED_SIGNER,
						1,
						'r1',
						true,
						false),
					new EnvelopeConfiguration.RelatedRecipients(
						new Query.Relationship(
							false,
							'OpportunityContactRoles',
							'Opportunity Contact Roles',
							'OpportunityContactRole'),
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						true,
						new List<String> { 'r1', 'r2', 'r3' },
						false,
						true)
				},
				new List<CustomField> {
					CustomField.newTextField('tf', 'tv', false, true),
					CustomField.newListField('lf', 'lv2', new List<String> { 'lv1', 'lv2', 'lv3' }, true, false)
				},
				new Notifications(true, 2, 1, true, 9, 7, false),
				's',
				'm',
				new List<Tab> {
					Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', false, false),
					Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
				},
				Envelope.DEFAULT_PERMISSIONS,
				Envelope.DEFAULT_OPTIONS,
				false);

			Test.startTest();
			EnvelopeConfiguration result = EnvelopeConfigurationService.createEnvelopeConfiguration(ec);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(ec.name, result.name);
			System.assertEquals(ec.sourceObject, result.sourceObject);
			System.assertEquals(ec.docuSignId, result.docuSignId);
			System.assertEquals(Collection.size(ec.customFields), Collection.size(result.customFields));
			System.assertEquals(Collection.size(ec.documents), Collection.size(result.documents));
			System.assertEquals(Collection.size(ec.recipients), Collection.size(result.recipients));
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(ec.notifications.remind, result.notifications.remind);
			System.assertEquals(ec.notifications.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(ec.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(ec.notifications.expires, result.notifications.expires);
			System.assertEquals(ec.notifications.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(ec.notifications.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(ec.notifications.updateChatter, result.notifications.updateChatter);
			System.assertEquals(ec.emailSubject, result.emailSubject);
			System.assertEquals(ec.emailMessage, result.emailMessage);
			System.assertEquals(Collection.size(ec.mergeFields), Collection.size(result.mergeFields));
			System.assertNotEquals(null, result.senderPermissions);
			System.assertEquals(ec.isDraft, result.isDraft);
		}
	}

	@IsTest
	static void test_getEnvelopeConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelopeConfiguration_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelopeConfiguration_not_found() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getEnvelopeConfiguration(UserInfo.getUserId());
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.EnvelopeConfigurationNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelopeConfiguration_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Contact c = TestUtils.createContact();
			EnvelopeConfiguration__c ec = TestUtils.createEnvelopeConfiguration();
			EnvelopeConfigurationRecipient__c ecr = new EnvelopeConfigurationRecipient__c(
				EnvelopeConfiguration__c = ec.Id,
				Roles__c = 'r1',
				SourceId__c = c.Id);
			insert ecr;

			Test.startTest();
			EnvelopeConfiguration result = EnvelopeConfigurationService.getEnvelopeConfiguration(ec.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(ec.Id, result.id);
			System.assertEquals(1, Collection.size(result.recipients));
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals(c.Name, result.recipients[0].name);
			System.assertEquals(c.Email, result.recipients[0].email);
			System.assertEquals(c.Phone, result.recipients[0].phone);
			System.assertEquals('r1', result.recipients[0].getRoleName());
			System.assertEquals(c.Id, result.recipients[0].getSourceId());
		}
	}

	@IsTest
	static void test_updateEnvelopeConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.updateEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateEnvelopeConfiguration_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.updateEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (ValidationException ex) {
				System.assertNotEquals(null, ex.details);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateEnvelopeConfiguration_new_template() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ContentVersion cv = TestUtils.createContentVersion();
			EnvelopeConfiguration__c dbec = TestUtils.createEnvelopeConfiguration(
				null,
				'Opportunity');
			EnvelopeConfiguration ec = new EnvelopeConfiguration(
				dbec.Id,
				UUID.randomUUID().toString(),
				dbec.SourceObject__c,
				null,
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						cv.ContentDocumentId,
						1,
						cv.Title,
						cv.FileExtension,
						false,
						true),
					new EnvelopeConfiguration.SourceFiles(
						null,
						null,
						2,
						true,
						false)
				},
				new List<Recipient> {
					new EnvelopeConfiguration.LookupRecipient(
						new Query.Relationship(
							true,
							'Owner',
							'Owner',
							'User'),
						Recipient.TYPE_EMBEDDED_SIGNER,
						1,
						'r1',
						true,
						false),
					new EnvelopeConfiguration.RelatedRecipients(
						new Query.Relationship(
							false,
							'OpportunityContactRoles',
							'Opportunity Contact Roles',
							'OpportunityContactRole'),
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						true,
						new List<String> { 'r1', 'r2', 'r3' },
						false,
						true)
				},
				new List<CustomField> {
					CustomField.newTextField('tf', 'tv', false, true),
					CustomField.newListField('lf', 'lv2', new List<String> { 'lv1', 'lv2', 'lv3' }, true, false)
				},
				new Notifications(true, 2, 1, true, 9, 7, false),
				's',
				'm',
				new List<Tab> {
					Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', false, false),
					Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
				},
				Envelope.DEFAULT_PERMISSIONS,
				Envelope.DEFAULT_OPTIONS,
				false);

			Test.startTest();
			EnvelopeConfiguration result = EnvelopeConfigurationService.updateEnvelopeConfiguration(ec);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(ec.name, result.name);
			System.assertEquals(ec.sourceObject, result.sourceObject);
			System.assertNotEquals(null, result.docuSignId);
			System.assertEquals(Collection.size(ec.customFields), Collection.size(result.customFields));
			System.assertEquals(Collection.size(ec.documents), Collection.size(result.documents));
			System.assertEquals(Collection.size(ec.recipients), Collection.size(result.recipients));
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(ec.notifications.remind, result.notifications.remind);
			System.assertEquals(ec.notifications.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(ec.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(ec.notifications.expires, result.notifications.expires);
			System.assertEquals(ec.notifications.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(ec.notifications.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(ec.notifications.updateChatter, result.notifications.updateChatter);
			System.assertEquals(ec.emailSubject, result.emailSubject);
			System.assertEquals(ec.emailMessage, result.emailMessage);
			System.assertEquals(Collection.size(ec.mergeFields), Collection.size(result.mergeFields));
			System.assertNotEquals(null, result.senderPermissions);
			System.assertEquals(ec.isDraft, result.isDraft);
		}
	}

	@IsTest
	static void test_updateEnvelopeConfiguration_existing_template() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeConfiguration__c dbec = TestUtils.createEnvelopeConfiguration(
				UUID.randomUUID().toString(),
				'Opportunity'
			);
			ContentVersion cv = TestUtils.createContentVersion();
			EnvelopeConfiguration ec = new EnvelopeConfiguration(
				dbec.Id,
				dbec.Name,
				dbec.SourceObject__c,
				UUID.parse(dbec.DocuSignId__c),
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						cv.ContentDocumentId,
						1,
						cv.Title,
						cv.FileExtension,
						false,
						true),
					new EnvelopeConfiguration.SourceFiles(
						null,
						null,
						2,
						true,
						false)
				},
				new List<Recipient> {
					new EnvelopeConfiguration.LookupRecipient(
						new Query.Relationship(
							true,
							'Owner',
							'Owner',
							'User'),
						Recipient.TYPE_EMBEDDED_SIGNER,
						1,
						'r1',
						true,
						false),
					new EnvelopeConfiguration.RelatedRecipients(
						new Query.Relationship(
							false,
							'OpportunityContactRoles',
							'Opportunity Contact Role',
							'OpportunityContactRole'),
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						true,
						new List<String> { 'r1', 'r2', 'r3' },
						false,
						true)
				},
				new List<CustomField> {
					CustomField.newTextField('tf', 'tv', false, true),
					CustomField.newListField('lf', 'lv2', new List<String> { 'lv1', 'lv2', 'lv3' }, true, false)
				},
				new Notifications(true, 2, 1, true, 9, 7, false),
				's',
				'm',
				new List<Tab> {
					Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', false, false),
					Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
				},
				Envelope.DEFAULT_PERMISSIONS,
				Envelope.DEFAULT_OPTIONS,
				false);

			Test.startTest();
			EnvelopeConfiguration result = EnvelopeConfigurationService.updateEnvelopeConfiguration(ec);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(ec.id, result.id);
			System.assertEquals(ec.name, result.name);
			System.assertEquals(ec.sourceObject, result.sourceObject);
			System.assertEquals(ec.docuSignId, result.docuSignId);
			System.assertEquals(Collection.size(ec.customFields), Collection.size(result.customFields));
			System.assertEquals(Collection.size(ec.documents), Collection.size(result.documents));
			System.assertEquals(Collection.size(ec.recipients), Collection.size(result.recipients));
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(ec.notifications.remind, result.notifications.remind);
			System.assertEquals(ec.notifications.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(ec.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(ec.notifications.expires, result.notifications.expires);
			System.assertEquals(ec.notifications.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(ec.notifications.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(ec.notifications.updateChatter, result.notifications.updateChatter);
			System.assertEquals(ec.emailSubject, result.emailSubject);
			System.assertEquals(ec.emailMessage, result.emailMessage);
			System.assertEquals(Collection.size(ec.mergeFields), Collection.size(result.mergeFields));
			System.assertNotEquals(null, result.senderPermissions);
			System.assertEquals(ec.isDraft, result.isDraft);
		}
	}

	@IsTest
	static void test_deleteEnvelopeConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.deleteEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelopeConfiguration_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.deleteEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelopeConfiguration_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeConfiguration__c ec = TestUtils.createEnvelopeConfiguration();

			Test.startTest();
			System.assert(EnvelopeConfigurationService.deleteEnvelopeConfiguration(ec.Id));
			Test.stopTest();

			System.assertEquals(0, Collection.size([SELECT Id FROM EnvelopeConfiguration__c WHERE Id = :ec.Id]));
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getTemplateEditUrl(null, null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getTemplateEditUrl(null, null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedDocuSignTemplateId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assertNotEquals(null, EnvelopeConfigurationService.getTemplateEditUrl(
				UUID.randomUUID(),
				new Url('https://unit.test')));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveMergeData() {
		Schema.Account a = TestUtils.createAccount();
		Opportunity o = TestUtils.createOpportunity(a.Id);
		Envelope e = new Envelope(
			null,
			'Opportunity {!Opportunity.Name}',
			'From {!$Organization.Name}',
			new Entity(o.Id))
			.withRecipients(new List<Recipient> {
				Recipient.fromSource('f1 l1', 'r1@unit.test', null, null, null)
					.withEmailSettings(new Recipient.EmailSettings(
					Localization.EN,
					null,
					'Hello {!$Recipient.FirstName}',
					'This is about your account {!Opportunity.Account.Name}')),
				Recipient.fromSource('r2', 'r3@unit.test', null, null, null),
				Recipient.fromSource('r3', 'r3@unit.test', null, null, null)
					.withNote('Note from {!$User.Name}')
			})
			.withCustomFields(new List<CustomField> {
				CustomField.newListField('lf', '{!$User.FirstName} {!$User.LastName}', new List<String> { 'v1', 'v2', 'v3' }, true, false),
				CustomField.newTextField('tf', '{!$Organization.NamespacePrefix}', true, false)
			});

		Test.startTest();
		Envelope result = EnvelopeConfigurationService.resolveMergeData(e.source, e);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('Opportunity ' + o.Name, result.emailSubject);
		System.assertEquals('From ' + UserInfo.getOrganizationName(), result.emailMessage);
		System.assertEquals(3, Collection.size(result.recipients));
		System.assertNotEquals(null, result.recipients[0]);
		System.assertNotEquals(null, result.recipients[0].emailSettings);
		System.assertEquals('Hello f1', result.recipients[0].emailSettings.subject);
		System.assertEquals('This is about your account ' + a.Name, result.recipients[0].emailSettings.message);
		System.assertNotEquals(null, result.recipients[2]);
		System.assertEquals('Note from ' + UserInfo.getName(), result.recipients[2].note);
		System.assertEquals(2, Collection.size(result.customFields));
		System.assertNotEquals(null, result.customFields[0]);
		System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), result.customFields[0].value);
		System.assertNotEquals(null, result.customFields[1]);
		System.assertEquals(Salesforce.namespace, result.customFields[1].value);
	}

	@IsTest
	static void test_resolveDocuments() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
		insert s;
		Lead l = TestUtils.createLead();
		ContentVersion cv1 = TestUtils.createContentVersion('111', 'pdf');
		TestUtils.createContentDocumentLink(l.Id, cv1);
		ContentVersion cv2 = TestUtils.createContentVersion('222', 'pdf');
		TestUtils.createContentDocumentLink(l.Id, cv2);
		ContentVersion cv3 = TestUtils.createContentVersion();
		// Template documents skipped
		Document d1 = new EnvelopeConfiguration.TemplateDocument(
			null,
			null,
			1,
			'td',
			'pdf',
			true,
			true);
		// Linked documents from source added, sorted by name DESC (cv2, cv1)
		Document d2 = new EnvelopeConfiguration.SourceFiles(
			null,
			new Query.Filter(
				null,
				'ContentDocument.LatestPublishedVersion.Title DESC',
				null),
			null,
			true,
			true);
		// Document added as-is
		Document d3 = Document.fromFile(cv3);
		// Expect docs: cv2, cv1, cv3

		Test.startTest();
		List<Document> result = EnvelopeConfigurationService.resolveDocuments(
			new Entity(l.Id),
			new List<Document> { d1, d2, d3 });
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		System.assertNotEquals(null, result[0]);
		System.assertEquals(cv2.Id, result[0].sourceId);
		System.assertEquals(2, result[0].sequence); // First doc is DS template, so sequence starts with 2
		System.assertNotEquals(null, result[1]);
		System.assertEquals(cv1.Id, result[1].sourceId);
		System.assertEquals(3, result[1].sequence);
		System.assertNotEquals(null, result[2]);
		System.assertEquals(cv3.Id, result[2].sourceId);
		System.assertEquals(4, result[2].sequence);
	}

	@IsTest
	static void test_resolveRelatedRecipients() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Schema.Account a = TestUtils.createAccount();
		Contact c0 = TestUtils.createContact(a.Id);
		Contact c1 = TestUtils.createContact(a.Id);
		Contact c2 = TestUtils.createContact(a.Id);
		Opportunity o = TestUtils.createOpportunity(a.Id);
		// Expect to be mapped to r3
		TestUtils.createOpportunityContactRole(o.Id, c0.Id, 'r0');
		// Expect match r1
		TestUtils.createOpportunityContactRole(o.Id, c1.Id, 'r1');
		// Expect match r2
		TestUtils.createOpportunityContactRole(o.Id, c2.Id, 'r2');
		// No r4, so placeholder will be added
		EnvelopeConfiguration.RelatedRecipients rrs = new EnvelopeConfiguration.RelatedRecipients(
			new Query.Relationship(
				false,
				'OpportunityContactRoles',
				'Opportunity Contact Roles',
				'OpportunityContactRole'),
			new Query.Filter(
				null,
				'Role ASC',
				null),
			Recipient.TYPE_SIGNER,
			2,
			true,
			new List<String> { 'r1', 'r2', 'r3', 'r4' },
			true,
			false);

		Test.startTest();
		List<Recipient> result = EnvelopeConfigurationService.resolveRelatedRecipients(
			rrs,
			new Entity(o.Id));
		Test.stopTest();

		System.assertEquals(4, Collection.size(result));

		System.assertNotEquals(null, result[0]);
		System.assertEquals(2, result[0].routingOrder);
		System.assertEquals(c1.Name, result[0].name);
		System.assertEquals(c1.Email, result[0].email);
		System.assertEquals(c1.Id, result[0].getSourceId());
		System.assertEquals('r1', result[0].getRoleName());

		System.assertNotEquals(null, result[1]);
		System.assertEquals(3, result[1].routingOrder);
		System.assertEquals(c2.Name, result[1].name);
		System.assertEquals(c2.Email, result[1].email);
		System.assertEquals(c2.Id, result[1].getSourceId());
		System.assertEquals('r2', result[1].getRoleName());

		System.assertNotEquals(null, result[2]);
		System.assertEquals(4, result[2].routingOrder);
		System.assertEquals(c0.Name, result[2].name);
		System.assertEquals(c0.Email, result[2].email);
		System.assertEquals(c0.Id, result[2].getSourceId());
		System.assertEquals('r3', result[2].getRoleName());

		System.assertNotEquals(null, result[3]);
		System.assertEquals(5, result[3].routingOrder);
		System.assertEquals(null, result[3].name);
		System.assertEquals(null, result[3].email);
		System.assertEquals(null, result[3].getSourceId());
		System.assertEquals('r4', result[3].getRoleName());
	}

	@IsTest
	static void test_getEnvelope_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getEnvelope(null, null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelope_undefined() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.getEnvelope(null, null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedEnvelopeConfiguration, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelope_invalid_source() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			EnvelopeConfiguration__c dbec = TestUtils.createEnvelopeConfiguration(
				UUID.randomUUID().toString(),
				'Case');
			Entity source = new Entity(TestUtils.createContact().Id);

			Test.startTest();
			try {
				EnvelopeConfigurationService.getEnvelope(dbec.Id, source);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.SourceMismatch_2, new List<Object> {
					source.typeName, dbec.SourceObject__c
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelope_success() {
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
			Envelope result = EnvelopeConfigurationService.getEnvelope(ec.id, new Entity(o.Id));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.id);
			System.assertEquals(null, result.name);
			System.assertEquals(null, result.docuSignId);
			System.assertEquals(ec.id, result.envelopeConfigurationId);

			System.assertEquals(2, Collection.size(result.documents));
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(null, result.documents[0].id);
			System.assertEquals(Document.TYPE_TEMPLATE, result.documents[0].type);
			System.assertEquals(1, result.documents[0].sequence);
			System.assertEquals(ec.name, result.documents[0].name);
			System.assertEquals(null, result.documents[0].extension);
			System.assertEquals(null, result.documents[0].size);
			System.assertEquals(null, result.documents[0].lastModified);
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
			System.assertEquals('Subject ' + o.Name, result.emailSubject);
			System.assertEquals('From ' + UserInfo.getName(), result.emailMessage);
			System.assertNotEquals(null, result.senderPermissions);
			System.assertNotEquals(null, result.source);
			System.assertEquals(o.Id, result.source.id);
		}
	}

	@IsTest
	static void test_queryEnvelopeConfigurationsForDisplay_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeConfiguration__c config1 = TestUtils.createEnvelopeConfiguration('Config 1', 'Account');
			EnvelopeConfiguration__c config2 = TestUtils.createEnvelopeConfiguration('Config 2', 'Account');

			Test.startTest();
			List<EnvelopeConfiguration.Listing> listings = EnvelopeConfigurationService.queryEnvelopeConfigurationsForDisplay();
			Test.stopTest();

			System.assertNotEquals(listings, null);
			System.assertEquals(listings.size(), 2);
			System.assertNotEquals(listings[0], null);
			System.assertEquals(listings[0].sourceObject, 'Account');
			System.assertNotEquals(listings[1], null);
			System.assertEquals(listings[1].sourceObject, 'Account');
		}
	}

	@IsTest
	static void test_queryEnvelopeConfigurationsForDisplay_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			EnvelopeConfiguration__c config1 = TestUtils.createEnvelopeConfiguration('Config 1', 'Account');
			EnvelopeConfiguration__c config2 = TestUtils.createEnvelopeConfiguration('Config 2', 'Account');
			Test.startTest();
			try {
				List<EnvelopeConfiguration.Listing> listings = EnvelopeConfigurationService.queryEnvelopeConfigurationsForDisplay();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@isTest
	static void test_mergeRecipients() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;
		Recipient r1 = new EnvelopeConfiguration.RelatedRecipients(
			new Query.Relationship(
				false,
				'OpportunityContactRoles',
				'Opportunity Contact Roles',
				'OpportunityContactRole'),
			null,
			Recipient.TYPE_SIGNER,
			1,
			true,
			new List<String> { 'r1', 'r2' },
			false,
			false);
		Recipient r2 = Recipient.fromSource(
			null,
			null,
			null,
			'r3',
			new Entity(UserInfo.getUserId()))
			.withRoutingOrder(3);
		Contact c1 = TestUtils.createContact();
		Recipient r3 = Recipient.fromSource(
			null,
			null,
			null,
			'r4',
			new Entity(c1.Id))
			.withRoutingOrder(4);
		Lead l = TestUtils.createLead();
		Recipient r4 = Recipient.fromSource(
			null,
			null,
			null,
			'r5',
			new Entity(l.Id))
			.withRoutingOrder(5);
		Recipient r5 = new EnvelopeConfiguration.LookupRecipient(
			new Query.Relationship(
				true,
				'Owner',
				'Owner',
				'User'),
			Recipient.TYPE_CARBON_COPY,
			6,
			'r6',
			false,
			false);
		Contact c2 = TestUtils.createContact();
		Recipient r6 = Recipient.fromSource(
			null,
			null,
			null,
			'r7',
			new Entity(c2.Id))
			.withRoutingOrder(7);

		Test.startTest();
		List<Recipient> result = EnvelopeConfigurationService.mergeRecipients(new List<Recipient> {
			r1, r2, r3, r4, r5, r6
		});
		Test.stopTest();

		System.assertEquals(6, Collection.size(result));

		System.assertNotEquals(null, result[0]);
		System.assert(result[0] instanceof EnvelopeConfiguration.RelatedRecipients);
		System.assertEquals(null, result[0].name);
		System.assertEquals(null, result[0].email);
		System.assertEquals(null, result[0].phone);
		System.assertEquals(null, result[0].source);
		System.assertEquals('r1', result[0].getRoleName());
		System.assertEquals(1, result[0].routingOrder);

		System.assertNotEquals(null, result[1]);
		System.assertEquals(UserInfo.getName(), result[1].name);
		System.assertEquals(UserInfo.getUserEmail(), result[1].email);
		System.assertEquals([SELECT Phone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Phone, result[1].phone);
		System.assertEquals('r3', result[1].getRoleName());
		System.assertEquals(UserInfo.getUserId(), result[1].getSourceId());
		System.assertEquals(3, result[1].routingOrder);

		System.assertNotEquals(null, result[2]);
		System.assertEquals(c1.Name, result[2].name);
		System.assertEquals(c1.Email, result[2].email);
		System.assertEquals(c1.Phone, result[2].phone);
		System.assertEquals('r4', result[2].getRoleName());
		System.assertEquals(c1.Id, result[2].getSourceId());
		System.assertEquals(4, result[2].routingOrder);

		System.assertNotEquals(null, result[3]);
		System.assertEquals(l.Name, result[3].name);
		System.assertEquals(l.Email, result[3].email);
		System.assertEquals(l.Phone, result[3].phone);
		System.assertEquals('r5', result[3].getRoleName());
		System.assertEquals(l.Id, result[3].getSourceId());
		System.assertEquals(5, result[3].routingOrder);

		System.assertNotEquals(null, result[4]);
		System.assert(result[4] instanceof EnvelopeConfiguration.LookupRecipient);
		System.assertEquals(null, result[4].name);
		System.assertEquals(null, result[4].email);
		System.assertEquals(null, result[4].phone);
		System.assertEquals('r6', result[4].getRoleName());
		System.assertEquals(null, result[4].source);
		System.assertEquals(6, result[4].routingOrder);

		System.assertNotEquals(null, result[5]);
		System.assertEquals(c2.Name, result[5].name);
		System.assertEquals(c2.Email, result[5].email);
		System.assertEquals(c2.Phone, result[5].phone);
		System.assertEquals('r7', result[5].getRoleName());
		System.assertEquals(c2.Id, result[5].getSourceId());
		System.assertEquals(7, result[5].routingOrder);
	}

	@IsTest
	static void test_deleteContentDocuments_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationService.deleteContentDocuments(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteContentDocuments_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			List<Id> contentVersionIds = new List<Id> { cv1.Id, cv2.Id };
			List<Id> contentDocumentIds = new List<Id> { cv1.ContentDocumentId, cv2.ContentDocumentId };
			System.assertNotEquals(null, cv1.ContentDocumentId);
			System.assertNotEquals(null, cv2.ContentDocumentId);

			Test.startTest();
			System.assert(EnvelopeConfigurationService.deleteContentDocuments(contentDocumentIds));
			Test.stopTest();

			System.assert(Collection.isEmpty([SELECT Id FROM ContentVersion WHERE Id IN :contentVersionIds]));
			System.assert(Collection.isEmpty([SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds]));
		}
	}
}
