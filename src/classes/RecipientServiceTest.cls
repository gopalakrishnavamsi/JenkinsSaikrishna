@IsTest
private class RecipientServiceTest {

	@IsTest
	static void test_bad_resolver() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
		Recipient r4 = Recipient.fromSigningGroup(4, new Recipient.Role('r4', 4), new Recipient.SigningGroup(1234, 'SG4'), null, 'n4');

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
		Recipient r4 = Recipient.fromSigningGroup(4, new Recipient.Role('r4', 4), new Recipient.SigningGroup(1234, 'SG4'), null, 'n4');

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
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '5555551111', 'r1', new Entity(UserInfo.getUserId()))
				.withAuthentication(new Recipient.Authentication('1234', true, new List<String> { '55555511111' }));
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '5555552222', 'r2', new Entity(UserInfo.getOrganizationId()));

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
			System.assertEquals(r2.source.id, result2.SourceId__c);
			System.assertEquals(Recipient.TYPE_SIGNER, result2.Type__c);
			System.assertEquals(false, result2.SignNow__c);
		}
	}

	@IsTest
	static void test_getRecipients_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				RecipientService.getRecipients(null, null);
				throw new AssertException('Expected getRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecipients_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			Contact c3 = TestUtils.createContact(a2.Id);

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
	static void test_searchRecipients_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				RecipientService.searchRecipients(null, null, null);
				throw new AssertException('Expected searchRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_searchRecipients_CompoundMatchBeginning() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Recipient__c d1 = TestUtils.createEnvelopeRecipient(e1.Id, 1);
			Recipient__c d2 = TestUtils.createEnvelopeRecipient(e1.Id, 2);

			Test.startTest();
			Integer result1 = RecipientService.DB.queryMaxSequence(e1.Id);
			Integer result2 = RecipientService.DB.queryMaxSequence(e2.Id);
			Test.stopTest();

			System.assertEquals(2, result1);
			System.assertEquals(0, result2);
		}
	}

	@IsTest
	static void test_Database_queryRoles() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id);
			r1.Role__c = 'r1';
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id);
			r2.Role__c = 'r2';
			update new List<Recipient__c> { r1, r2 };

			Test.startTest();
			Set<String> result = RecipientService.DB.queryRoles(e.Id);
			Test.stopTest();

			System.assertEquals(new Set<String> { r1.Role__c, r2.Role__c }, result);
		}
	}

	@IsTest
	static void test_Database_queryRecipients_by_sequence() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			r1.RoutingOrder__c = 3;
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);
			r2.RoutingOrder__c = 2;
			Recipient__c r3 = TestUtils.createEnvelopeRecipient(e.Id, 3);
			r3.RoutingOrder__c = 1;
			update new List<Recipient__c> { r1, r2, r3 };
			List<Id> rIds = new List<Id> { r1.Id, r2.Id, r3.Id };

			Test.startTest();
			List<Recipient> result = RecipientService.DB.queryRecipients(e.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			for (Integer i = 0; i < result.size(); i++) {
				System.assertNotEquals(null, result[i]);
				System.assertEquals(rIds[i], result[i].id);
				System.assertEquals(i + 1, result[i].sequence);
			}
		}
	}

	@IsTest
	static void test_Database_queryRecipients_by_routing_order() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 3);
			r1.RoutingOrder__c = 1;
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);
			r2.RoutingOrder__c = 2;
			Recipient__c r3 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			r3.RoutingOrder__c = 3;
			update new List<Recipient__c> { r1, r2, r3 };
			List<Id> rIds = new List<Id> { r1.Id, r2.Id, r3.Id };

			Test.startTest();
			List<Recipient> result = RecipientService.DB.queryRecipients(e.Id, false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());
			for (Integer i = 0; i < result.size(); i++) {
				System.assertNotEquals(null, result[i]);
				System.assertEquals(rIds[i], result[i].id);
				System.assertEquals(i + 1, result[i].routingOrder);
			}
		}
	}

	@IsTest
	static void test_Database_updateRecipientSequence_by_sequence() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
	static void test_Database_getRelatedObjectType() {
		Test.startTest();
		System.assertEquals(null, RecipientService.DB.getRelatedObjectType(null, null));
		System.assertEquals(OpportunityContactRole.getSObjectType(),
			RecipientService.DB.getRelatedObjectType(Opportunity.getSObjectType(), 'OpportunityContactRoles'));
		Test.stopTest();
	}

	@IsTest
	static void test_Database_queryRelatedContacts_signing_group() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			// Valid signing group mapping
			EnvelopeConfiguration.RelatedContacts rc1 = new EnvelopeConfiguration.RelatedContacts(
				new Map<String, String> {
					'signinggroup' => 'Name',
					'smsauthphone' => 'Phone',
					'role' => 'LastName'
				},
				'Contacts',
				null); // parseErrors
			// Invalid signing group mapping
			EnvelopeConfiguration.RelatedContacts rc2 = new EnvelopeConfiguration.RelatedContacts(
				new Map<String, String> {
					'signinggroup' => 'Birthdate',
					'role' => 'LastName'
				},
				'Contacts',
				null); // parseErrors
			// Valid - has all mappings
			Map<String, Recipient.SigningGroup> sgs1 = new Map<String, Recipient.SigningGroup> {
				c1.Name => new Recipient.SigningGroup(1111, c1.Name),
				c2.Name => new Recipient.SigningGroup(2222, c2.Name)
			};
			// Invalid - missing mapping for c2
			Map<String, Recipient.SigningGroup> sgs2 = new Map<String, Recipient.SigningGroup> {
				c1.Name => new Recipient.SigningGroup(1111, c1.Name)
			};

			Test.startTest();
			List<Recipient> result = RecipientService.DB.queryRelatedContacts(new Entity(a1.Id), rc1, sgs1);
			try {
				RecipientService.DB.queryRelatedContacts(new Entity(a1.Id), rc1, sgs2);
				throw new AssertException('Expected queryRelatedContacts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.SigningGroupNotFound, ex.getMessage());
			}
			try {
				RecipientService.DB.queryRelatedContacts(new Entity(a1.Id), rc2, sgs1);
				throw new AssertException('Expected queryRelatedContacts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedSigningGroup, ex.getMessage());
			}
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(sgs1.get(c1.Name), result[0].signingGroup);
			System.assertNotEquals(null, result[0].role);
			System.assertEquals(c1.LastName, result[0].role.name);
			System.assertNotEquals(null, result[0].authentication);
			System.assertEquals(new List<String> { c1.Phone }, result[0].authentication.smsPhoneNumbers);
			System.assertNotEquals(null, result[0].authentication);
			System.assertNotEquals(null, result[0].source);
			System.assertEquals(c1.Id, result[0].source.id);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(sgs1.get(c2.Name), result[1].signingGroup);
			System.assertNotEquals(null, result[1].role);
			System.assertEquals(c2.LastName, result[1].role.name);
			System.assertNotEquals(null, result[1].authentication);
			System.assertEquals(new List<String> { c2.Phone }, result[1].authentication.smsPhoneNumbers);
			System.assertNotEquals(null, result[1].source);
			System.assertEquals(c2.Id, result[1].source.id);
		}
	}

	@IsTest
	static void test_Database_queryRelatedContacts_sign_in_person() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			EnvelopeConfiguration.RelatedContacts rc1 = new EnvelopeConfiguration.RelatedContacts(
				new Map<String, String> {
					'firstname' => 'FirstName',
					'lastname' => 'LastName',
					'email' => 'Email',
					'signinpersonname' => 'Name',
					'role' => 'Phone'
				},
				'Contacts',
				null); // parseErrors

			Test.startTest();
			List<Recipient> result = RecipientService.DB.queryRelatedContacts(new Entity(a1.Id), rc1, new Map<String, Recipient.SigningGroup>());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(c1.Name, result[0].name);
			System.assertEquals(null, result[0].email);
			System.assertEquals(c1.Name, result[0].hostName);
			System.assertEquals(c1.Email, result[0].hostEmail);
			System.assertNotEquals(null, result[0].role);
			System.assertEquals(c1.Phone, result[0].role.name);
			System.assertEquals(null, result[0].authentication);
			System.assertNotEquals(null, result[0].source);
			System.assertEquals(c1.Id, result[0].source.id);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(c2.Name, result[1].name);
			System.assertEquals(null, result[1].email);
			System.assertEquals(c2.Name, result[1].hostName);
			System.assertEquals(c2.Email, result[1].hostEmail);
			System.assertNotEquals(null, result[1].role);
			System.assertEquals(c2.Phone, result[1].role.name);
			System.assertEquals(null, result[1].authentication);
			System.assertNotEquals(null, result[1].source);
			System.assertEquals(c2.Id, result[1].source.id);
		}
	}

	@IsTest
	static void test_Database_queryRelatedContacts_success() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
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
			List<Recipient> result = RecipientService.DB.queryRelatedContacts(new Entity(a1.Id), rc1, new Map<String, Recipient.SigningGroup>());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(c1.Name, result[0].name);
			System.assertEquals(c1.Email, result[0].email);
			System.assertEquals(null, result[0].hostName);
			System.assertEquals(null, result[0].hostEmail);
			System.assertNotEquals(null, result[0].role);
			System.assertEquals(c1.Phone, result[0].role.name);
			System.assertEquals(null, result[0].authentication);
			System.assertNotEquals(null, result[0].source);
			System.assertEquals(c1.Id, result[0].source.id);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(c2.Name, result[1].name);
			System.assertEquals(c2.Email, result[1].email);
			System.assertEquals(null, result[1].hostName);
			System.assertEquals(null, result[1].hostEmail);
			System.assertNotEquals(null, result[1].role);
			System.assertEquals(c2.Phone, result[1].role.name);
			System.assertEquals(null, result[1].authentication);
			System.assertNotEquals(null, result[1].source);
			System.assertEquals(c2.Id, result[1].source.id);
		}
	}

	@IsTest
	static void test_Database_querySigningGroups() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			EnvelopeConfiguration.RelatedContacts rc1 = new EnvelopeConfiguration.RelatedContacts(
				new Map<String, String> {
					'signinggroup' => 'Name'
				},
				'Contacts',
				null); // parseErrors

			Test.startTest();
			Set<String> result = RecipientService.DB.querySigningGroups(new Entity(a1.Id), rc1);
			Test.stopTest();

			System.assertEquals(new Set<String> { c1.Name, c2.Name }, result);
		}
	}

	@IsTest
	static void test_Database_deleteRecipients() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
	static void test_mergeAvailableRole() {
		System.runAs(TestUtils.createDocuSignUser()) {
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2),
				new RoleSettings__c(Name = 'Role3', Value__c = 3)
			};

			Test.startTest();
			RecipientService.MergeResult result = RecipientService.mergeAvailableRole(Recipient.fromSource(
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

			result = RecipientService.mergeAvailableRole(Recipient.fromSource(
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

			result = RecipientService.mergeAvailableRole(Recipient.fromSource(
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
			System.assertEquals(2, result.recipient.role.value);

			result = RecipientService.mergeAvailableRole(Recipient.fromSource(
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2)
			};

			Test.startTest();
			List<Recipient> result1 = RecipientService.mergeDefaultSettings(e.Id, null);
			// FIXME: This should fail if we ask for more recipients than we have roles. Currently we silently truncate the List which is always bad.
			List<Recipient> result2 = RecipientService.mergeDefaultSettings(e.Id, new List<Recipient> {
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
					'Role3',
					null)
			});
			Test.stopTest();

			System.assertEquals(null, result1);

			System.assertNotEquals(null, result2);
			System.assertEquals(3, result2.size());

			System.assertNotEquals(null, result2[0]);
			System.assertNotEquals(null, result2[0].role);
			System.assertEquals('Role1', result2[0].role.name);
			System.assertEquals(1, result2[0].role.value);

			System.assertNotEquals(null, result2[1]);
			System.assertNotEquals(null, result2[1].role);
			System.assertEquals('Role2', result2[1].role.name);
			System.assertEquals(2, result2[1].role.value);

			System.assertNotEquals(null, result2[2]);
			System.assertNotEquals(null, result2[2].role);
			System.assertEquals('Role3', result2[2].role.name);
			System.assertEquals(0, result2[2].role.value);
		}
	}

	@IsTest
	static void test_mergeEmailSettings() {
		Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '5555555555', 'r1', null);
		Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '5555555555', 'r2', null);
		Recipient r3 = Recipient.fromSource('r3', 'r3@unit.test', '5555555555', 'r3', null);
		Recipient r4 = Recipient.fromSource('r4', 'r4@unit.test', '5555555555', 'r4', null);
		Recipient.EmailSettings defaultSettings = new Recipient.EmailSettings(
			Localization.EN,
			Localization.getLabel(Localization.EN),
			'en default subject',
			'en default message');
		Recipient.EmailSettings customSettings1 = new Recipient.EmailSettings(
			Localization.ES,
			Localization.getLabel(Localization.ES),
			'es custom subject',
			'es custom message');
		Recipient.EmailSettings customSettings2 = new Recipient.EmailSettings(
			null,
			null,
			'en custom subject',
			null);

		Test.startTest();
		RecipientService.MergeResult result1 = RecipientService.mergeEmailSettings(r1, customSettings1, defaultSettings);
		RecipientService.MergeResult result2 = RecipientService.mergeEmailSettings(r2, null, defaultSettings);
		RecipientService.MergeResult result3 = RecipientService.mergeEmailSettings(r3, null, null);
		RecipientService.MergeResult result4 = RecipientService.mergeEmailSettings(r4, customSettings2, defaultSettings);
		Test.stopTest();

		// Full custom
		System.assertNotEquals(null, result1);
		System.assert(result1.isMerged);
		System.assertNotEquals(null, result1.recipient);
		System.assertNotEquals(null, result1.recipient.emailSettings);
		System.assertEquals(customSettings1.language, result1.recipient.emailSettings.language);
		System.assertEquals(customSettings1.languageLabel, result1.recipient.emailSettings.languageLabel);
		System.assertEquals(customSettings1.subject, result1.recipient.emailSettings.subject);
		System.assertEquals(customSettings1.message, result1.recipient.emailSettings.message);

		// Full default
		System.assertNotEquals(null, result2);
		System.assert(result2.isMerged);
		System.assertNotEquals(null, result2.recipient);
		System.assertNotEquals(null, result2.recipient.emailSettings);
		System.assertEquals(defaultSettings.language, result2.recipient.emailSettings.language);
		System.assertEquals(defaultSettings.languageLabel, result2.recipient.emailSettings.languageLabel);
		System.assertEquals(defaultSettings.subject, result2.recipient.emailSettings.subject);
		System.assertEquals(defaultSettings.message, result2.recipient.emailSettings.message);

		// Null: no custom or default
		System.assertNotEquals(null, result3);
		System.assert(!result3.isMerged);
		System.assertNotEquals(null, result3.recipient);
		System.assertEquals(null, result3.recipient.emailSettings);

		// Custom email subject
		System.assertNotEquals(null, result4);
		System.assert(result4.isMerged);
		System.assertNotEquals(null, result4.recipient);
		System.assertNotEquals(null, result4.recipient.emailSettings);
		System.assertEquals(defaultSettings.language, result4.recipient.emailSettings.language);
		System.assertEquals(defaultSettings.languageLabel, result4.recipient.emailSettings.languageLabel);
		System.assertEquals(customSettings2.subject, result4.recipient.emailSettings.subject);
		System.assertEquals(defaultSettings.message, result4.recipient.emailSettings.message);
	}

	@IsTest
	static void test_mergeTemplateRoleWithRole() {
		System.runAs(TestUtils.createDocuSignUser()) {
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'dr1', Value__c = 1),
				new RoleSettings__c(Name = 'dr2', Value__c = 2),
				new RoleSettings__c(Name = 'dr3', Value__c = 3)
			};
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));
			Recipient r2 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));
			Recipient r3 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id));
			Map<String, String> roleMap = new Map<String, String> {
				'rr1' => 'tr1',
				'rr2' => 'dr2',
				'rr3' => ''
			};

			Test.startTest();
			RecipientService.MergeResult result1 = RecipientService.mergeTemplateRoleWithRole(r1, 'rr1', roleMap);
			RecipientService.MergeResult result2 = RecipientService.mergeTemplateRoleWithRole(r2, 'rr2', roleMap);
			RecipientService.MergeResult result3 = RecipientService.mergeTemplateRoleWithRole(r3, 'rr3', roleMap);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isMerged);
			System.assertNotEquals(null, result1.recipient);
			System.assertNotEquals(null, result1.recipient.role);
			System.assertEquals('tr1', result1.recipient.role.name);
			System.assertEquals(0, result1.recipient.role.value);

			System.assertNotEquals(null, result2);
			System.assert(result2.isMerged);
			System.assertNotEquals(null, result2.recipient);
			System.assertNotEquals(null, result2.recipient.role);
			System.assertEquals('dr2', result2.recipient.role.name);
			System.assertEquals(2, result2.recipient.role.value);

			System.assertNotEquals(null, result3);
			System.assert(!result3.isMerged);
		}
	}

	@IsTest
	static void test_mergeNoteWithRole() {
		Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '555551111', 'rr1', null);
		Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '555552222', 'rr2', null);
		Map<String, String> noteMap = new Map<String, String> {
			'rr1' => 'n1',
			EnvelopeConfiguration.DEFAULT_NOTE => 'dn'
		};

		Test.startTest();
		RecipientService.MergeResult result1 = RecipientService.mergeNoteWithRole(r1, 'rr1', noteMap);
		RecipientService.MergeResult result2 = RecipientService.mergeNoteWithRole(r2, 'rr2', noteMap);
		RecipientService.MergeResult result3 = RecipientService.mergeNoteWithRole(r2, 'rr2', new Map<String, String>());
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isMerged);
		System.assertNotEquals(null, result1.recipient);
		System.assertEquals(noteMap.get(r1.role.name), result1.recipient.note);

		System.assertNotEquals(null, result2);
		System.assert(result2.isMerged);
		System.assertNotEquals(null, result2.recipient);
		System.assertEquals(noteMap.get(EnvelopeConfiguration.DEFAULT_NOTE), result2.recipient.note);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isMerged);
	}

	@IsTest
	static void test_mergeTypeWithRole() {
		Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '555551111', 'rr1', null);
		Map<String, EnvelopeConfiguration.RecipientType> typeMap = new Map<String, EnvelopeConfiguration.RecipientType> {
			'rr1' => new EnvelopeConfiguration.RecipientType(Recipient.TYPE_IN_PERSON_SIGNER, true),
			'rr2' => null
		};

		Test.startTest();
		RecipientService.MergeResult result1 = RecipientService.mergeTypeWithRole(r1, 'rr1', typeMap);
		RecipientService.MergeResult result2 = RecipientService.mergeTypeWithRole(r1, 'rr2', typeMap);
		RecipientService.MergeResult result3 = RecipientService.mergeTypeWithRole(r1, '', typeMap);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isMerged);
		System.assertNotEquals(null, result1.recipient);
		System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, result1.recipient.type);
		System.assert(result1.recipient.signNow);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isMerged);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isMerged);
	}

	@IsTest
	static void test_mergeRoleType() {
		Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', '555551111', 'rr1', null);
		Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '555552222', 'rr2', null);
		Recipient r3 = Recipient.fromSource('r3', 'r3@unit.test', '555553333', 'rr3', null);
		Recipient r4 = Recipient.fromSource('r4', 'r4@unit.test', '555554444', 'rr4', null);
		Recipient r5 = Recipient.fromSource('r5', 'r5@unit.test', '555555555', 'rr5', null);
		List<EnvelopeConfiguration.RecipientRoleType> roleTypes = new List<EnvelopeConfiguration.RecipientRoleType> {
			new EnvelopeConfiguration.RecipientRoleType('rrt1', new EnvelopeConfiguration.RecipientType(Recipient.TYPE_IN_PERSON_SIGNER, true)),
			new EnvelopeConfiguration.RecipientRoleType('rrt2', new EnvelopeConfiguration.RecipientType(Recipient.TYPE_CERTIFIED_DELIVERY, false)),
			new EnvelopeConfiguration.RecipientRoleType(null, null)
		};

		Test.startTest();
		RecipientService.MergeResult result1 = RecipientService.mergeRoleType(r1, 0, roleTypes);
		RecipientService.MergeResult result2 = RecipientService.mergeRoleType(r2, 1, roleTypes);
		RecipientService.MergeResult result3 = RecipientService.mergeRoleType(r3, 2, roleTypes);
		RecipientService.MergeResult result4 = RecipientService.mergeRoleType(r4, 3, roleTypes);
		RecipientService.MergeResult result5 = RecipientService.mergeRoleType(r5, 0, null);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isMerged);
		System.assertNotEquals(null, result1.recipient);
		System.assertNotEquals(null, result1.recipient.role);
		System.assertEquals('rrt1', result1.recipient.role.name);
		System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, result1.recipient.type);
		System.assert(result1.recipient.signNow);

		System.assertNotEquals(null, result2);
		System.assert(result2.isMerged);
		System.assertNotEquals(null, result2.recipient);
		System.assertNotEquals(null, result2.recipient.role);
		System.assertEquals('rrt2', result2.recipient.role.name);
		System.assertEquals(Recipient.TYPE_CERTIFIED_DELIVERY, result2.recipient.type);
		System.assert(!result2.recipient.signNow);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isMerged);

		System.assertNotEquals(null, result4);
		System.assert(!result4.isMerged);

		System.assertNotEquals(null, result5);
		System.assert(!result5.isMerged);
	}

	@IsTest
	static void test_mergeCustomSettings() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e.Id, 1));
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', '5555552222', 'rr2', null);
			Recipient r3 = Recipient.fromSource('r3', 'r3@unit.test', '5555553333', 'rr3', null);
			Recipient r4 = Recipient.fromSource('r4', 'r4@unit.test', '5555554444', 'rr4', null);
			insert new List<RoleSettings__c> {
				new RoleSettings__c(Name = 'Role1', Value__c = 1),
				new RoleSettings__c(Name = 'Role2', Value__c = 2),
				new RoleSettings__c(Name = 'Role3', Value__c = 3)
			};
			Recipient.EmailSettings es = new Recipient.EmailSettings(Localization.ZH_CN, Localization.getLabel(Localization.ZH_CN),
				'zh-CN subject', 'zh-CN message');
			EnvelopeConfiguration.RecipientSettings rs = new EnvelopeConfiguration.RecipientSettings(
				new List<EnvelopeConfiguration.RelatedContacts>(),
				new List<EnvelopeConfiguration.CustomRecipient>(),
				false,
				10,
				true,
				1,
				new List<EnvelopeConfiguration.RecipientRoleType> {
					new EnvelopeConfiguration.RecipientRoleType(
						'Role1',
						new EnvelopeConfiguration.RecipientType(Recipient.TYPE_IN_PERSON_SIGNER, true))
				},
				new Map<String, String> {
					r1.role.name => '',
					r2.role.name => 'tr2'
				},
				new Map<String, EnvelopeConfiguration.RecipientType> {
					'Role2' => new EnvelopeConfiguration.RecipientType(Recipient.TYPE_CARBON_COPY, false)
				},
				new Map<String, String> {
					'rr3' => 'n3'
				});

			Test.startTest();
			List<Recipient> result1 = RecipientService.mergeCustomSettings(null, null, null, null);
			List<Recipient> result2 = RecipientService.mergeCustomSettings(e.Id, new List<Recipient> { r1, r2, r3, r4 }, es, rs);
			Test.stopTest();

			System.assertEquals(null, result1);

			System.assertNotEquals(null, result2);
			System.assertEquals(4, result2.size());

			System.assertNotEquals(null, result2[0]);
			System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, result2[0].type);
			System.assert(result2[0].signNow);
			System.assertNotEquals(null, result2[0].role);
			System.assertEquals('Role1', result2[0].role.name);
			System.assertEquals(1, result2[0].role.value);
			System.assertEquals(null, result2[0].note);
			System.assertNotEquals(null, result2[0].emailSettings);
			System.assertEquals(es.language, result2[0].emailSettings.language);
			System.assertEquals(es.languageLabel, result2[0].emailSettings.languageLabel);
			System.assertEquals(es.subject, result2[0].emailSettings.subject);
			System.assertEquals(es.message, result2[0].emailSettings.message);

			System.assertNotEquals(null, result2[1]);
			System.assertEquals(Recipient.TYPE_SIGNER, result2[1].type);
			System.assert(!result2[1].signNow);
			System.assertNotEquals(null, result2[1].role);
			System.assertEquals('tr2', result2[1].role.name);
			System.assertEquals(0, result2[1].role.value);
			System.assertEquals(null, result2[1].note);
			System.assertEquals(es.language, result2[1].emailSettings.language);
			System.assertEquals(es.languageLabel, result2[1].emailSettings.languageLabel);
			System.assertEquals(es.subject, result2[1].emailSettings.subject);
			System.assertEquals(es.message, result2[1].emailSettings.message);

			System.assertNotEquals(null, result2[2]);
			System.assertEquals(Recipient.TYPE_SIGNER, result2[2].type);
			System.assert(!result2[2].signNow);
			System.assertNotEquals(null, result2[2].role);
			System.assertEquals('Role2', result2[2].role.name);
			System.assertEquals(2, result2[2].role.value);
			System.assertEquals('n3', result2[2].note);
			System.assertEquals(es.language, result2[2].emailSettings.language);
			System.assertEquals(es.languageLabel, result2[2].emailSettings.languageLabel);
			System.assertEquals(es.subject, result2[2].emailSettings.subject);
			System.assertEquals(es.message, result2[2].emailSettings.message);

			System.assertNotEquals(null, result2[3]);
			System.assertEquals(Recipient.TYPE_SIGNER, result2[3].type);
			System.assert(!result2[3].signNow);
			System.assertNotEquals(null, result2[3].role);
			System.assertEquals('Role3', result2[3].role.name);
			System.assertEquals(3, result2[3].role.value);
			System.assertEquals(null, result2[3].note);
			System.assertEquals(es.language, result2[2].emailSettings.language);
			System.assertEquals(es.languageLabel, result2[2].emailSettings.languageLabel);
			System.assertEquals(es.subject, result2[2].emailSettings.subject);
			System.assertEquals(es.message, result2[2].emailSettings.message);
		}
	}

	@IsTest
	static void test_mergeUserTags() {
		System.runAs(TestUtils.createUser()) {
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
	static void test_addEnvelopeRecipients_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope__c e2 = TestUtils.createEnvelope();
			Recipient e1r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e1.Id, 1));
			Recipient e2r1 = RecipientService.DB.convert(TestUtils.createEnvelopeRecipient(e2.Id, 1));
			Recipient r2 = Recipient.newRecipient(2, Recipient.TYPE_SIGNER, null, 'r2', 'r2@unit.test', null, null, false);
			Recipient r3 = Recipient.newRecipient(3, Recipient.TYPE_SIGNER, null, 'r3', 'r3@unit.test', null, null, false);

			Test.startTest();
			List<Recipient> result1 = RecipientService.addEnvelopeRecipients(e1.Id, new List<Recipient> { r2, r3 });
			List<Recipient> result2 = RecipientService.addEnvelopeRecipients(e2.Id, new List<Recipient> { r2, r3 },
				new Recipient.EmailSettings(
					Localization.EN,
					Localization.getLabel(Localization.EN),
					'en subject',
					'en message'),
				null);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(2, result1.size());
			System.assertNotEquals(null, result1[0]);
			System.assertEquals(2, result1[0].sequence);
			System.assertNotEquals(null, result1[1]);
			System.assertEquals(3, result1[1].sequence);

			System.assertNotEquals(null, result2);
			System.assertEquals(2, result2.size());
			System.assertNotEquals(null, result2[0]);
			System.assertEquals(2, result2[0].sequence);
			System.assertNotEquals(null, result2[1]);
			System.assertEquals(3, result2[1].sequence);
		}
	}

	@IsTest
	static void test_removeEnvelopeRecipients_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				RecipientService.removeEnvelopeRecipients(e.Id, null);
				throw new AssertException('Expected removeEnvelopeRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeEnvelopeRecipients_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r1 = TestUtils.createEnvelopeRecipient(e.Id, 1);
			Recipient__c r2 = TestUtils.createEnvelopeRecipient(e.Id, 2);
			Recipient__c r3 = TestUtils.createEnvelopeRecipient(e.Id, 3);

			Test.startTest();
			List<Recipient> result = RecipientService.removeEnvelopeRecipients(e.Id, new Set<Id> { r1.Id, r2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertNotEquals(null, result[0]);
			System.assertEquals(r3.Id, result[0].id);
			System.assertEquals(1, result[0].sequence);
		}
	}

	@IsTest
	static void test_updateEnvelopeRecipients_unauthorized() {
		Envelope__c e;
		System.runAs(TestUtils.createDocuSignUser()) {
			e = TestUtils.createEnvelope();
		}

		System.runAs(TestUtils.createUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
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
			System.assertEquals(r1.Id, result[0].id);
			System.assertEquals(1, result[0].sequence);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(r3.Id, result[1].id);
			System.assertEquals(2, result[1].sequence);
		}
	}

	@IsTest
	static void test_resolveRelatedContacts_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				RecipientService.resolveRelatedContacts(null, null, null);
				throw new AssertException('Expected resolveRelatedContacts to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveRelatedContacts_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Schema.Account a1 = TestUtils.createAccount();
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
			List<Recipient> result = RecipientService.resolveRelatedContacts(new Entity(a1.Id), rc1, new Map<String, Recipient.SigningGroup>());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	@IsTest
	static void test_resolveSourceRecipients_unauthorized() {
		System.runAs(TestUtils.createUser()) {
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
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

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
	static void test_resolveCustomRecipients_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				RecipientService.resolveCustomRecipients(null, null, null);
				throw new AssertException('Expected resolveCustomRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveCustomRecipients_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
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
			List<Recipient> result = RecipientService.resolveCustomRecipients(crs, sgs, es);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(Recipient.TYPE_SIGNER, result[0].type);
			System.assertEquals(es, result[0].emailSettings);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, result[1].type);
			System.assert(result[1].signNow);
			System.assertEquals(es, result[1].emailSettings);

			System.assertNotEquals(null, result[2]);
			System.assertEquals(Recipient.TYPE_SIGNER, result[2].type);
			System.assertNotEquals(null, result[2].signingGroup);
			System.assertEquals('sg3', result[2].signingGroup.name);
			System.assertEquals(es, result[2].emailSettings);
		}
	}

	@IsTest
	static void test_resolveSigningGroups_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				RecipientService.resolveSigningGroups(null, null);
				throw new AssertException('Expected resolveCustomRecipients to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveSigningGroups_not_found() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a.Id);
			c1.LastName = 'sg1x';
			Contact c2 = TestUtils.createContact(a.Id);
			c2.LastName = 'sg2x';
			update new List<Contact> { c1, c2 };

			EnvelopeConfiguration.RecipientSettings rs = new EnvelopeConfiguration.RecipientSettings(
				new List<EnvelopeConfiguration.RelatedContacts> {
					new EnvelopeConfiguration.RelatedContacts(
						new Map<String, String> {
							'role' => 'FirstName',
							'signinggroup' => 'LastName'
						},
						'Contacts',
						null)
				},
				new List<EnvelopeConfiguration.CustomRecipient> {
					new EnvelopeConfiguration.CustomRecipient(null, null, null, null, null, 1, null, null, null, null,
						'sg3x', false, null)
				},
				false, 0, true, 1, null, null, null, null);

			Test.startTest();
			try {
				RecipientService.resolveSigningGroups(new Entity(a.Id), rs);
				throw new AssertException('Expected resolveSigningGroups to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.SigningGroupNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveSigningGroups_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a.Id);
			c1.LastName = 'sg1';
			Contact c2 = TestUtils.createContact(a.Id);
			c2.LastName = 'sg2';
			update new List<Contact> { c1, c2 };

			EnvelopeConfiguration.RecipientSettings rs = new EnvelopeConfiguration.RecipientSettings(
				new List<EnvelopeConfiguration.RelatedContacts> {
					new EnvelopeConfiguration.RelatedContacts(
						new Map<String, String> {
							'role' => 'FirstName',
							'signinggroup' => 'LastName'
						},
						'Contacts',
						null)
				},
				new List<EnvelopeConfiguration.CustomRecipient> {
					new EnvelopeConfiguration.CustomRecipient(null, null, null, null, null, 1, null, null, null, null,
						'sg3', false, null)
				},
				false, 0, true, 1, null, null, null, null);

			Test.startTest();
			Map<String, Recipient.SigningGroup> result = RecipientService.resolveSigningGroups(new Entity(a.Id), rs);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(new Set<String> { 'sg1', 'sg2', 'sg3' }, result.keySet());
		}
	}
}
