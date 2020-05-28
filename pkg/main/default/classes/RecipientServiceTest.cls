@IsTest
private class RecipientServiceTest {

	@IsTest
	static void test_bad_resolver() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientResolvers__c = 'bad_resolver';
			upsert s;

			Test.startTest();
			try {
				RecipientService.getRecipients(null, null);
				throw new AssertException('Expected initialization to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.InvalidRecipientResolver_1, new List<String> { 'bad_resolver' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_validate_send_later() {
		// Placeholder: invalid no role
		Recipient r1 = Recipient.fromSource('R1', null, null, null, null);
		// Placeholder: valid has role
		Recipient r2 = Recipient.fromSource('R2', null, null, 'r2', null);
		// Valid
		Recipient r3 = Recipient.fromSource('R2', 'r1@unit.test', '5555555555', 'r2', null);
		// Signing group
		Recipient r4 = Recipient.fromSigningGroup(4, new Recipient.Role('r4', 4), new SigningGroup(1234, 'SG4'), null, 'n4');

		Test.startTest();
		System.assert(!RecipientService.validate((List<Recipient>)null, false).isValid);
		System.assert(!RecipientService.validate(new List<Recipient>(), false).isValid);
		System.assert(!RecipientService.validate(new List<Recipient> { null }, false).isValid);
		System.assert(!RecipientService.validate(new List<Recipient> { r1 }, false).isValid);
		System.assert(RecipientService.validate(new List<Recipient> { r2 }, false).isValid);
		System.assert(RecipientService.validate(new List<Recipient> { r3 }, false).isValid);
		System.assert(RecipientService.validate(new List<Recipient> { r4 }, false).isValid);
		Test.stopTest();
	}

	@IsTest
	static void test_validate_send_now() {
		// Placeholder: invalid no role
		Recipient r1 = Recipient.fromSource('R1', null, null, null, null);
		// Placeholder: valid has role
		Recipient r2 = Recipient.fromSource('R2', null, null, 'r2', null);
		// Valid
		Recipient r3 = Recipient.fromSource('R2', 'r1@unit.test', '5555555555', 'r2', null);
		// Signing group
		Recipient r4 = Recipient.fromSigningGroup(4, new Recipient.Role('r4', 4), new SigningGroup(1234, 'SG4'), null, 'n4');

		Test.startTest();
		System.assert(!RecipientService.validate((List<Recipient>)null, true).isValid);
		System.assert(!RecipientService.validate(new List<Recipient>(), true).isValid);
		System.assert(!RecipientService.validate(new List<Recipient> { null }, true).isValid);
		System.assert(!RecipientService.validate(new List<Recipient> { r1 }, true).isValid);
		System.assert(!RecipientService.validate(new List<Recipient> { r2 }, true).isValid);
		System.assert(RecipientService.validate(new List<Recipient> { r3 }, true).isValid);
		System.assert(RecipientService.validate(new List<Recipient> { r4 }, true).isValid);
		Test.stopTest();
	}

	@IsTest
	static void test_convert_Recipient_sobject() {
		Envelope__c e = TestUtils.createEnvelope();
		Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
		r1.RoutingOrder__c = 2;
		r1.EmailSubject__c = 's1';
		r1.EmailMessage__c = 'm1';
		r1.Role__c = 'r1';
		r1.RoleValue__c = 1;
		r1.SigningGroupId__c = 1111;
		r1.SigningGroupName__c = 'sg1';
		r1.SmsPhoneNumber__c = '5555551111';
		r1.AccessCode__c = '1111';
		r1.SignNow__c = true;
		Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);
		r2.RoutingOrder__c = 3;
		r2.EmailSubject__c = 's2';
		r2.EmailMessage__c = 'm2';
		r2.Role__c = 'r2';
		r2.RoleValue__c = 2;
		r2.IdCheckRequired__c = true;
		r2.SmsPhoneNumber__c = '5555552222';
		r2.Type__c = Recipient.TYPE_IN_PERSON_SIGNER;
		r2.HostName__c = 'h2';
		r2.HostEmail__c = 'h2@unit.test';
		r2.Note__c = 'n1';
		r2.SourceId__c = UserInfo.getUserId();

		Test.startTest();
		List<Recipient> result = RecipientService.convert(new List<Recipient__c> { r1, r2 });
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, result.size());

		System.assertEquals(r1.Id, result[0].id);
		System.assertEquals(r1.Type__c, result[0].type);
		System.assertEquals(r1.Sequence__c, result[0].sequence);
		System.assertEquals(r1.RoutingOrder__c, result[0].routingOrder);
		System.assertNotEquals(null, result[0].role);
		System.assertEquals(r1.Role__c, result[0].role.name);
		System.assertEquals(Integer.valueOf(r1.RoleValue__c), result[0].role.value);
		System.assertEquals(r1.Name, result[0].name);
		System.assertEquals(r1.Email__c, result[0].email);
		System.assertNotEquals(null, result[0].signingGroup);
		System.assertEquals(r1.SigningGroupId__c, result[0].signingGroup.id);
		System.assertEquals(r1.SigningGroupName__c, result[0].signingGroup.name);
		System.assertEquals(r1.SmsPhoneNumber__c, result[0].phone);
		System.assertNotEquals(null, result[0].authentication);
		System.assertEquals(r1.AccessCode__c, result[0].authentication.accessCode);
		System.assertEquals(r1.IdCheckRequired__c == true, result[0].authentication.idCheckRequired == true);
		System.assertEquals(null, result[0].authentication.smsPhoneNumbers);
		System.assertEquals(r1.Note__c, result[0].note);
		System.assertNotEquals(null, result[0].emailSettings);
		System.assertEquals(r1.Language__c, result[0].emailSettings.language);
		System.assertEquals(r1.EmailSubject__c, result[0].emailSettings.subject);
		System.assertEquals(r1.EmailMessage__c, result[0].emailSettings.message);
		System.assertEquals(r1.HostName__c, result[0].hostName);
		System.assertEquals(r1.HostEmail__c, result[0].hostEmail);
		System.assertEquals(r1.SignNow__c, result[0].signNow);
		System.assertEquals(null, result[0].source);

		System.assertNotEquals(null, result[1]);
		System.assertEquals(r2.Id, result[1].id);
		System.assertEquals(r2.Type__c, result[1].type);
		System.assertEquals(r2.Sequence__c, result[1].sequence);
		System.assertEquals(r2.RoutingOrder__c, result[1].routingOrder);
		System.assertNotEquals(null, result[1].role);
		System.assertEquals(r2.Role__c, result[1].role.name);
		System.assertEquals(Integer.valueOf(r2.RoleValue__c), result[1].role.value);
		System.assertEquals(r2.Name, result[1].name);
		System.assertEquals(r2.Email__c, result[1].email);
		System.assertEquals(null, result[1].signingGroup);
		System.assertEquals(r2.SmsPhoneNumber__c, result[1].phone);
		System.assertNotEquals(null, result[1].authentication);
		System.assertEquals(r2.AccessCode__c, result[1].authentication.accessCode);
		System.assertEquals(r2.IdCheckRequired__c == true, result[1].authentication.idCheckRequired == true);
		System.assertEquals(new List<String> { r2.SmsPhoneNumber__c }, result[1].authentication.smsPhoneNumbers);
		System.assertEquals(r2.Note__c, result[1].note);
		System.assertNotEquals(null, result[1].emailSettings);
		System.assertEquals(r2.Language__c, result[1].emailSettings.language);
		System.assertEquals(r2.EmailSubject__c, result[1].emailSettings.subject);
		System.assertEquals(r2.EmailMessage__c, result[1].emailSettings.message);
		System.assertEquals(r2.HostName__c, result[1].hostName);
		System.assertEquals(r2.HostEmail__c, result[1].hostEmail);
		System.assertEquals(r2.SignNow__c, result[1].signNow);
		System.assertNotEquals(null, result[1].source);
		System.assertEquals(r2.SourceId__c, result[1].source.id);
	}

	@IsTest
	static void test_convert_Recipient() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '5555551111', 'r1', new Entity(UserInfo.getUserId()))
				.withAuthentication(new Recipient.Authentication('1234', true, new List<String> { '55555511111' }));
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '5555552222', 'r2', new Entity(UserInfo.getOrganizationId()))
				.withRole(new Recipient.Role('r2', 2));

			Test.startTest();
			Recipient__c result1 = RecipientService.DB.convert(r1, e.Id, 1);
			Recipient__c result2 = RecipientService.DB.convert(r2, e.Id, 2);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(e.Id, result1.Envelope__c);
			System.assertEquals(1, result1.Sequence__c);
			System.assertEquals(r1.name, result1.Name);
			System.assertEquals(r1.email, result1.Email__c);
			System.assertEquals(r1.authentication.accessCode, result1.AccessCode__c);
			System.assertEquals(true, result1.IdCheckRequired__c);
			System.assertEquals(r1.authentication.smsPhoneNumbers[0], result1.SmsPhoneNumber__c);
			System.assertEquals(r1.role.name, result1.Role__c);
			System.assertEquals(r1.role.value, result1.RoleValue__c);
			System.assertEquals(r1.source.id, result1.SourceId__c);
			System.assertEquals(Recipient.TYPE_SIGNER, result1.Type__c);
			System.assertEquals(false, result1.SignNow__c);

			System.assertNotEquals(null, result2);
			System.assertEquals(e.Id, result2.Envelope__c);
			System.assertEquals(2, result2.Sequence__c);
			System.assertEquals(r2.name, result2.Name);
			System.assertEquals(r2.email, result2.Email__c);
			System.assertEquals(null, result2.AccessCode__c);
			System.assertEquals(false, result2.IdCheckRequired__c);
			System.assertEquals(null, result2.SmsPhoneNumber__c);
			System.assertEquals(r2.role.name, result2.Role__c);
			System.assertEquals(r2.role.value, result2.RoleValue__c);
			System.assertEquals(r2.source.id, result2.SourceId__c);
			System.assertEquals(Recipient.TYPE_SIGNER, result2.Type__c);
			System.assertEquals(false, result2.SignNow__c);
		}
	}

	@IsTest
	static void test_getRecipients_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			TestUtils.createContact(a1.Id);
			TestUtils.createContact(a1.Id);
			TestUtils.createContact(a2.Id);

			Test.startTest();
			List<Recipient> result = RecipientService.getRecipients(Schema.Account.getSObjectType(), new Set<Id> { a1.Id, a2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(null, result[0].id);
			System.assertEquals(Recipient.TYPE_SIGNER, result[0].type);
			System.assertNotEquals(null, result[0].source);
			System.assertEquals(Contact.getSObjectType(), result[0].source.type);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(null, result[1].id);
			System.assertEquals(Recipient.TYPE_SIGNER, result[1].type);
			System.assertNotEquals(null, result[1].source);
			System.assertEquals(Contact.getSObjectType(), result[1].source.type);
		}
	}

	@IsTest
	static void test_searchRecipients_CompoundMatchBeginning() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = Recipient.SearchBehavior.CompoundMatchBeginning.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients(Lead.getSObjectType(), 'AB', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_searchRecipients_CompoundMatchExact() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = Recipient.SearchBehavior.CompoundMatchExact.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients(Lead.getSObjectType(), 'AB', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(0, result.size());
		}
	}

	@IsTest
	static void test_searchRecipients_CompoundMatchAny() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = Recipient.SearchBehavior.CompoundMatchAny.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients(Lead.getSObjectType(), 'WX', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_searchRecipients_DiscreteMatchBeginning() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = Recipient.SearchBehavior.DiscreteMatchBeginning.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients(Lead.getSObjectType(), 'AB', 'WX');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
		}
	}

	@IsTest
	static void test_searchRecipients_DiscreteMatchExact() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = Recipient.SearchBehavior.DiscreteMatchExact.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients(Lead.getSObjectType(), 'ABCD', 'EFGH');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
		}
	}

	@IsTest
	static void test_searchRecipients_DiscreteMatchAny() {
		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = Recipient.SearchBehavior.DiscreteMatchAny.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients(Lead.getSObjectType(), 'BC', 'XY');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
		}
	}

	@IsTest
	static void test_Database_queryMaxSequence() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			TestUtils.createEnvelopeRecipient(e1.Id, 1);
			TestUtils.createEnvelopeRecipient(e1.Id, 2);

			Test.startTest();
			Integer result1 = RecipientService.DB.queryMaxSequence(e1.Id);
			Integer result2 = RecipientService.DB.queryMaxSequence(e2.Id);
			Test.stopTest();

			System.assertEquals(2, result1);
			System.assertEquals(0, result2);
		}
	}

	@IsTest
	static void test_Database_updateRecipientSequence_by_sequence() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 2);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 4);
			Recipient__c r3 = TestUtils.createEnvelopeRecipient(e.Id, 6);

			Test.startTest();
			List<Recipient> result = RecipientService.DB.updateRecipientSequence(e.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(r1.Id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(r2.Id, result[1].id);
			System.assertEquals(2, result[1].sequence);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(r3.Id, result[2].id);
			System.assertEquals(3, result[2].sequence);
		}
	}

	@IsTest
	static void test_Database_updateRecipientSequence_by_routing_order() {
		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 12);
			r1.RoutingOrder__c = 1;
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 6);
			r2.RoutingOrder__c = 2;
			Recipient__c r3 = TestUtils.createEnvelopeRecipient(e.Id, -1);
			r3.RoutingOrder__c = 3;
			update new List<Recipient__c> { r1, r2, r3 };

			Test.startTest();
			List<Recipient> result = RecipientService.DB.updateRecipientSequence(e.Id, false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(r1.Id, result[0].id);
			System.assertEquals(1, result[0].sequence);
			System.assertEquals(1, result[0].routingOrder);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(r2.Id, result[1].id);
			System.assertEquals(2, result[1].sequence);
			System.assertEquals(2, result[1].routingOrder);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(r3.Id, result[2].id);
			System.assertEquals(3, result[2].sequence);
			System.assertEquals(3, result[2].routingOrder);
		}
	}

	@IsTest
	static void test_Database_insertRecipients() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', null, 'r1', null);
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', null, 'r2', null);
			Recipient r3 = Recipient.fromSource('r3', 'r3@unit.test', null, 'r3', null);

			Test.startTest();
			List<Recipient> result = RecipientService.DB.insertRecipients(e.Id, new List<Recipient> { r1, r2, r3 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			for (Integer i = 0; i < result.size(); i++) {
				System.assertNotEquals(null, result[i]);
				System.assertNotEquals(null, result[i].id);
				System.assertEquals(i + 1, result[i].sequence);
			}
		}
	}

	@IsTest
	static void test_Database_deleteRecipients() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);
			Recipient__c r3 = TestUtils.createEnvelopeRecipient(e.Id, 3);

			Test.startTest();
			List<Recipient> result = RecipientService.DB.deleteRecipients(e.Id, new Set<Id> { r2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(r1.Id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(r3.Id, result[1].id);
			System.assertEquals(2, result[1].sequence);
		}
	}

	@IsTest
	static void test_Database_upsertRecipients() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id, 1));
			Recipient r2 = Recipient.newRecipient(2, Recipient.TYPE_SIGNER, null, 'R2', 'r2@unit.test', null, 'n2', false);
			Recipient r3 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id, 3));

			Test.startTest();
			List<Recipient> result = RecipientService.DB.upsertRecipients(e.Id, new List<Recipient> { r1, r2, r3 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(r1.id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);
			System.assertEquals(r2.email, result[1].email);
			System.assertEquals(2, result[1].sequence);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(r3.id, result[2].id);
			System.assertEquals(3, result[2].sequence);
		}
	}

	@IsTest
	static void test_getDefaultRoles_success() {
		insert new List<RoleSettings__c> {
			new RoleSettings__c(Name = 'Role1', Value__c = 1),
			new RoleSettings__c(Name = 'Role2', Value__c = 2),
			new RoleSettings__c(Name = 'Role3', Value__c = 3),
			new RoleSettings__c(Name = 'Role4', Value__c = 4)
		};

		Test.startTest();
		List<Recipient.Role> result = RecipientService.getDefaultRoles();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(4, result.size());
		System.assertEquals('Role1', result[0].name);
		System.assertEquals(1, result[0].value);
		System.assertEquals('Role2', result[1].name);
		System.assertEquals(2, result[1].value);
		System.assertEquals('Role3', result[2].name);
		System.assertEquals(3, result[2].value);
		System.assertEquals('Role4', result[3].name);
		System.assertEquals(4, result[3].value);
	}

	@IsTest
	static void test_resolveRole() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2),
				new RoleSettings__c(Name = 'Role3', Value__c = 3),
				new RoleSettings__c(Name = 'Role4', Value__c = 4)
			};

			Test.startTest();
			Recipient.Role result = RecipientService.resolveRole('Role3');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Role3', result.name);
			System.assertEquals(3, result.value);
		}
	}

	@IsTest
	static void test_mergeRole() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2),
				new RoleSettings__c(Name = 'Role3', Value__c = 3)
			};

			Test.startTest();
			RecipientService.MergeResult result = RecipientService.mergeRole(Recipient.fromSource(
				'r1',
				'r1@unit.test',
				'5555551111',
				'Role1',
				null),
				new Set<String> { 'Role3' });
			System.assertNotEquals(null, result);
			System.assert(result.isMerged);
			System.assertNotEquals(null, result.recipient);
			System.assertNotEquals(null, result.recipient.role);
			System.assertEquals('Role1', result.recipient.role.name);
			System.assertEquals(1, result.recipient.role.value);

			result = RecipientService.mergeRole(Recipient.fromSource(
				'r1',
				'r1@unit.test',
				'5555551111',
				'Role1',
				null),
				new Set<String> { 'Role2', 'Role3' });
			System.assertNotEquals(null, result);
			System.assert(result.isMerged);
			System.assertNotEquals(null, result.recipient);
			System.assertNotEquals(null, result.recipient.role);
			System.assertEquals('Role1', result.recipient.role.name);
			System.assertEquals(1, result.recipient.role.value);

			result = RecipientService.mergeRole(Recipient.fromSource(
				'r1',
				'r1@unit.test',
				'5555551111',
				'',
				null),
				new Set<String> { 'Role1', 'Role3' });
			System.assertNotEquals(null, result);
			System.assert(result.isMerged);
			System.assertNotEquals(null, result.recipient);
			System.assertNotEquals(null, result.recipient.role);
			System.assertEquals('Role2', result.recipient.role.name);

			result = RecipientService.mergeRole(Recipient.fromSource(
				'r1',
				'r1@unit.test',
				'5555551111',
				null,
				null),
				new Set<String> { 'Role1', 'Role2', 'Role3' });
			System.assertNotEquals(null, result);
			System.assert(!result.isMerged);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_mergeDefaultSettings() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			TestUtils.createEnvelope();
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2)
			};

			Test.startTest();
			List<Recipient> result1 = RecipientService.mergeDefaultSettings(null, null);
			List<Recipient> result2 = RecipientService.mergeDefaultSettings(new List<Recipient> {
				Recipient.fromSource(
					'r1',
					'r1@unit.test',
					'5555551111',
					'Role1',
					null),
				Recipient.fromSource(
					'r2',
					'r2@unit.test',
					'5555552222',
					'Some other role',
					null),
				Recipient.fromSource(
					'r3',
					'r3@unit.test',
					'5555553333',
					'',
					null),
				Recipient.fromSource(
					'r4',
					'r4@unit.test',
					'5555554444',
					'',
					null)
			}, null);
			Test.stopTest();

			System.assertEquals(0, Collection.size(result1));

			System.assertNotEquals(null, result2);
			System.assertEquals(4, result2.size());

			System.assertNotEquals(null, result2[0]);
			System.assertNotEquals(null, result2[0].role);
			System.assertEquals('Role1', result2[0].role.name);
			System.assertEquals(1, result2[0].role.value);

			System.assertNotEquals(null, result2[1]);
			System.assertNotEquals(null, result2[1].role);
			System.assertEquals('Some other role', result2[1].role.name);
			System.assertEquals(null, result2[1].role.value);

			System.assertNotEquals(null, result2[2]);
			System.assertNotEquals(null, result2[2].role);
			System.assertEquals('Role2', result2[2].role.name);
			System.assertEquals(2, result2[2].role.value);

			System.assertNotEquals(null, result2[3]);
			System.assertEquals(null, result2[3].role);
		}
	}

	@IsTest
	static void test_mergeUserTags() {
		System.runAs(UserMock.createUser()) {
			Recipient r1 = Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r1', 'r1@unit.test', null, null, false)
				.withEmailSettings(new Recipient.EmailSettings(Localization.EN, Localization.getLabel(Localization.EN),
					'subject1: [FirstName][LastName][Email]', 'message1'));
			Recipient r2 = Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'r2', 'r2@unit.test', null, null, false)
				.withEmailSettings(new Recipient.EmailSettings(Localization.EN, Localization.getLabel(Localization.EN),
					'subject2', 'message2: [FirstName][LastName][Email]'));

			Test.startTest();
			List<Recipient> result = RecipientService.mergeUserTags(new List<Recipient> { r1, r2 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].emailSettings);
			System.assertEquals('subject1: ' + UserInfo.getFirstName() + UserInfo.getLastName() + UserInfo.getUserEmail(),
				result[0].emailSettings.subject);
			System.assertEquals('message1', result[0].emailSettings.message);

			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].emailSettings);
			System.assertEquals('subject2', result[1].emailSettings.subject);
			System.assertEquals('message2: ' + UserInfo.getFirstName() + UserInfo.getLastName() + UserInfo.getUserEmail(),
				result[1].emailSettings.message);
		}
	}

	@IsTest
	static void test_prepareRecipients_invalid() {
		Test.startTest();
		try {
			RecipientService.prepareRecipients(null);
			throw new AssertException('Expected prepareRecipients to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedRecipient, ex.getMessage());
		}
		try {
			RecipientService.prepareRecipients(new List<Recipient>());
			throw new AssertException('Expected prepareRecipients to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedRecipient, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_prepareRecipients_default() {
		System.runAs(UserMock.createUser()) {
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2)
			};
			Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '5551111111', null, null);
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '5552222222', 'Role2', null)
				.withEmailSettings(new Recipient.EmailSettings(
					Localization.EN, Label.English, '[FirstName][LastName]', '[Email]'));
			Recipient r3 = Recipient.fromSource('r3', 'r3@unit.test', '5553333333', '', null);

			Test.startTest();
			List<Recipient> result = RecipientService.prepareRecipients(new List<Recipient> { r1, r2, r3 });
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));

			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].role);
			System.assertEquals('Role1', result[0].role.name);
			System.assertEquals(1, result[0].role.value);
			System.assertEquals(null, result[0].emailSettings);

			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].role);
			System.assertEquals('Role2', result[1].role.name);
			System.assertEquals(2, result[1].role.value);
			System.assertNotEquals(null, result[1].emailSettings);
			System.assertEquals(UserInfo.getFirstName() + UserInfo.getLastName(), result[1].emailSettings.subject);
			System.assertEquals(UserInfo.getUserEmail(), result[1].emailSettings.message);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(null, result[2].role);
			System.assertEquals(null, result[2].emailSettings);
		}
	}

	@IsTest
	static void test_addEnvelopeRecipients_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				RecipientService.addEnvelopeRecipients(e.Id, null);
				throw new AssertException('Expected addEnvelopeRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addEnvelopeRecipients_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e1.Id, 1));
			RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e2.Id, 1));
			Recipient r2 = Recipient.newRecipient(2, Recipient.TYPE_SIGNER, null, 'r2', 'r2@unit.test', null, null, false);
			Recipient r3 = Recipient.newRecipient(3, Recipient.TYPE_SIGNER, null, 'r3', 'r3@unit.test', null, null, false);

			Test.startTest();
			List<Recipient> result = RecipientService.addEnvelopeRecipients(e1.Id, new List<Recipient> { r2, r3 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(2, result[0].sequence);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(3, result[1].sequence);
		}
	}

	@IsTest
	static void test_updateEnvelopeRecipients_unauthorized() {
		Envelope__c e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				RecipientService.updateEnvelopeRecipients(e.Id, null, null);
				throw new AssertException('Expected updateEnvelopeRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateEnvelopeRecipients_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id, 1));
			Recipient r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id, 2));
			Recipient r3 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id, 3));

			Test.startTest();
			List<Recipient> result = RecipientService.updateEnvelopeRecipients(e.Id,
				new List<Recipient> { r1, r2, r3 },
				new List<Recipient> { r1, r3 });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(r1.id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(r3.id, result[1].id);
			System.assertEquals(2, result[1].sequence);
		}
	}

	@IsTest
	static void test_resolveSourceRecipients_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				RecipientService.resolveSourceRecipients(null, null);
				throw new AssertException('Expected resolveSourceRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveSourceRecipients_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			Recipient.EmailSettings es = new Recipient.EmailSettings(
				Localization.NL,
				Localization.getLabel(Localization.NL),
				'nl subject',
				'nl message');

			Test.startTest();
			List<Recipient> result = RecipientService.resolveSourceRecipients(new Entity(a.Id), es);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundC1 = false, foundC2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r.source);
				System.assertEquals(es, r.emailSettings);
				if (r.source.id == c1.Id) {
					foundC1 = true;
					System.assertEquals(c1.Name, r.name);
					System.assertEquals(c1.Email, r.email);
					System.assertEquals(c1.Phone, r.phone);
				} else if (r.source.id == c2.Id) {
					foundC2 = true;
					System.assertEquals(c2.Name, r.name);
					System.assertEquals(c2.Email, r.email);
					System.assertEquals(c2.Phone, r.phone);
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
			}
			System.assert(foundC1);
			System.assert(foundC2);
		}
	}

	@IsTest
	static void test_addEnvelopeRecipients_multi_send_unauthorized() {
		Envelope__c e1, e2, e3;
		System.runAs(UserMock.createDocuSignSender(false)) {
			Schema.Account a = TestUtils.createAccount();
			e1 = TestUtils.createEnvelope(a.Id);
			e2 = TestUtils.createEnvelope(a.Id);
			e3 = TestUtils.createEnvelope(a.Id);
		}

		System.runAs(UserMock.createDocuSignSender(false)) {
			Recipient e1r1 = Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null);
			Recipient e1r2 = Recipient.fromSource('e1r2', 'e1r2@unit.test', '2222222', 'r2', null);
			Recipient e3r1 = Recipient.fromSource('e2r1', 'e2r1@unit.test', '1111111', 'r1', null);
			Map<Id, List<Recipient>> rs = new Map<Id, List<Recipient>> {
				e1.Id => new List<Recipient> { e1r1, e1r2 },
				e2.Id => null,
				e3.Id => new List<Recipient> { e3r1 }
			};

			Test.startTest();
			try {
				RecipientService.addEnvelopeRecipients(rs);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addEnvelopeRecipients_multi_send_success() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e1 = TestUtils.createEnvelope(a.Id);
			Recipient e1r1 = Recipient.fromSource('e1r1', 'e1r1@unit.test', '1111111', 'r1', null);
			Recipient e1r2 = Recipient.fromSource('e1r2', 'e1r2@unit.test', '2222222', 'r2', null);
			Envelope__c e2 = TestUtils.createEnvelope(a.Id);
			Envelope__c e3 = TestUtils.createEnvelope(a.Id);
			Recipient e3r1 = Recipient.fromSource('e2r1', 'e2r1@unit.test', '1111111', 'r1', null);
			Map<Id, List<Recipient>> rs = new Map<Id, List<Recipient>> {
				e1.Id => new List<Recipient> { e1r1, e1r2 },
				e2.Id => null,
				e3.Id => new List<Recipient> { e3r1 }
			};

			Test.startTest();
			Map<Id, List<Recipient>> result = RecipientService.addEnvelopeRecipients(rs);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(new Set<Id> { e1.Id, e3.Id }, result.keySet());
			System.assertNotEquals(null, result.get(e1.Id)[0]);
			System.assertNotEquals(null, result.get(e1.Id)[0].id);
			System.assertNotEquals(null, result.get(e1.Id)[1]);
			System.assertNotEquals(null, result.get(e1.Id)[1].id);
			System.assertEquals(1, Collection.size(result.get(e3.Id)));
			System.assertNotEquals(null, result.get(e3.Id)[0]);
			System.assertNotEquals(null, result.get(e3.Id)[0].id);
		}
	}

	@IsTest
	static void test_canResolveRelatedRecipients() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;

		Test.startTest();
		System.assert(!RecipientService.canResolveRelatedRecipients(null));
		System.assert(!RecipientService.canResolveRelatedRecipients(Envelope__c.getSObjectType()));
		System.assert(RecipientService.canResolveRelatedRecipients(Contact.getSObjectType()));
		System.assert(RecipientService.canResolveRelatedRecipients(Lead.getSObjectType()));
		System.assert(RecipientService.canResolveRelatedRecipients(User.getSObjectType()));
		System.assert(RecipientService.canResolveRelatedRecipients(OpportunityContactRole.getSObjectType()));
		System.assert(RecipientService.canResolveRelatedRecipients(CaseContactRole.getSObjectType()));
		if (Salesforce.isValidSObject('AccountTeamMember')) {
			System.assert(RecipientService.canResolveRelatedRecipients(Salesforce.getSObjectType('AccountTeamMember')));
		}
		if (Salesforce.isValidSObject('OpportunityTeamMember')) {
			System.assert(RecipientService.canResolveRelatedRecipients(Salesforce.getSObjectType('OpportunityTeamMember')));
		}
		Test.stopTest();
	}

	@IsTest
	static void test_canResolveRecipientType() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		insert s;

		Test.startTest();
		System.assert(!RecipientService.canResolveRecipientType(null));
		System.assert(!RecipientService.canResolveRecipientType(Envelope__c.getSObjectType()));
		System.assert(RecipientService.canResolveRecipientType(Contact.getSObjectType()));
		System.assert(RecipientService.canResolveRecipientType(Lead.getSObjectType()));
		System.assert(RecipientService.canResolveRecipientType(User.getSObjectType()));
		System.assert(!RecipientService.canResolveRecipientType(OpportunityContactRole.getSObjectType()));
		System.assert(!RecipientService.canResolveRecipientType(CaseContactRole.getSObjectType()));
		if (Salesforce.isValidSObject('AccountTeamMember')) {
			System.assert(!RecipientService.canResolveRecipientType(Salesforce.getSObjectType('AccountTeamMember')));
		}
		if (Salesforce.isValidSObject('OpportunityTeamMember')) {
			System.assert(!RecipientService.canResolveRecipientType(Salesforce.getSObjectType('OpportunityTeamMember')));
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getRelatedRecipients_invalid_arguments() {
		Test.startTest();
		try {
			RecipientService.getRelatedRecipients(
				null,
				null,
				null,
				null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidType, ex.getMessage());
		}
		try {
			RecipientService.getRelatedRecipients(
				Opportunity.getSObjectType(),
				null,
				null,
				null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedRelationship, ex.getMessage());
		}
		try {
			RecipientService.getRelatedRecipients(
				Opportunity.getSObjectType(),
				null,
				new Query.Relationship(
					false,
					' ',
					'Opportunity Contact Roles',
					'OpportunityContactRole'),
				null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedRelationship, ex.getMessage());
		}
		try {
			RecipientService.getRelatedRecipients(
				Opportunity.getSObjectType(),
				null,
				new Query.Relationship(
					false,
					'OpportunityContactRoles',
					'Opportunity Contact Roles',
					''),
				null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedRelationship, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getRelatedRecipients_success() {
		System.runAs(UserMock.createDocuSignSender()) {
			Schema.Account a = TestUtils.createAccount();

			Test.startTest();
			List<Recipient> result = RecipientService.getRelatedRecipients(
				Schema.Account.getSObjectType(),
				new Set<Id> { a.Id },
				new Query.Relationship(
					true,
					'Owner',
					'Owner',
					'User'),
				null);
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(UserInfo.getName(), result[0].name);
			System.assertEquals(UserInfo.getUserEmail(), result[0].email);
			System.assertNotEquals(null, result[0].source);
			System.assertEquals(UserInfo.getUserId(), result[0].source.id);
		}
	}

	@IsTest
	static void test_getSigningGroups() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			List<SigningGroup> signingGroups1 = RecipientService.getSigningGroups();
			// Call again to get cached version
			List<SigningGroup> signingGroups2 = RecipientService.getSigningGroups();
			Test.stopTest();

			System.assertNotEquals(null, signingGroups1);
			System.assertEquals(3, signingGroups1.size());
			System.assert(signingGroups1 === signingGroups2); // Check reference equality

			System.assertNotEquals(null, signingGroups1[0].id);
			System.assertEquals('SG1', signingGroups1[0].name);
			System.assert(signingGroups1[0].isValid);
			System.assertNotEquals(null, signingGroups1[0].members);
			System.assertEquals(2, signingGroups1[0].members.size());
			System.assertNotEquals(null, signingGroups1[0].members[0].username);
			System.assertNotEquals(null, signingGroups1[0].members[0].email);
			System.assertNotEquals(null, signingGroups1[0].members[1].username);
			System.assertNotEquals(null, signingGroups1[0].members[1].email);

			System.assertNotEquals(null, signingGroups1[1].id);
			System.assertEquals('SG2', signingGroups1[1].name);
			System.assert(!signingGroups1[1].isValid);
			System.assertNotEquals(null, signingGroups1[1].members);
			System.assertEquals(0, signingGroups1[1].members.size());

			System.assertNotEquals(null, signingGroups1[2].id);
			System.assertEquals('SG3', signingGroups1[2].name);
			System.assert(signingGroups1[2].isValid);
			System.assertNotEquals(null, signingGroups1[2].members);
			System.assertEquals(1, signingGroups1[2].members.size());
			System.assertNotEquals(null, signingGroups1[2].members[0].username);
			System.assertNotEquals(null, signingGroups1[2].members[0].email);
		}
	}


	@IsTest
	static void test_getSigningGroups_unauthorized() {
		System.runAs(UserMock.createDocuSignSender()) {
			Test.startTest();
			try {
				List<SigningGroup> signingGroups = RecipientService.getSigningGroups();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}	

	@IsTest
	static void test_resolveRecipients_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				RecipientService.resolveRecipients(null, null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveRecipients_invalid_arguments() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			try {
				RecipientService.resolveRecipients(null, null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidType, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveRecipients_success() {
		System.runAs(UserMock.createDocuSignSender()) {
			Contact c1 = TestUtils.createContact();
			Contact c2 = TestUtils.createContact();
			Contact c3 = TestUtils.createContact();

			Test.startTest();
			List<Recipient> result = RecipientService.resolveRecipients(
				Contact.getSObjectType(),
				new Set<Id> { c1.Id, c2.Id, c3.Id });
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
		}
	}
}