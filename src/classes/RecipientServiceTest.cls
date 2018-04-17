@IsTest
private class RecipientServiceTest {

	static testMethod void test_bad_resolver() {
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

	static testMethod void test_convert_Recipient_sobject() {
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
		Recipient result1 = RecipientService.convert(r1);
		Recipient result2 = RecipientService.convert(r2);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(r1.Id, result1.id);
		System.assertEquals(r1.Type__c, result1.type);
		System.assertEquals(r1.Sequence__c, result1.sequence);
		System.assertEquals(r1.RoutingOrder__c, result1.routingOrder);
		System.assertNotEquals(null, result1.role);
		System.assertEquals(r1.Role__c, result1.role.name);
		System.assertEquals(r1.Name, result1.name);
		System.assertEquals(r1.Email__c, result1.email);
		System.assertNotEquals(null, result1.signingGroup);
		System.assertEquals(r1.SigningGroupId__c, result1.signingGroup.id);
		System.assertEquals(r1.SigningGroupName__c, result1.signingGroup.name);
		System.assertEquals(r1.SmsPhoneNumber__c, result1.phone);
		System.assertNotEquals(null, result1.authentication);
		System.assertEquals(r1.AccessCode__c, result1.authentication.accessCode);
		System.assertEquals(r1.IdCheckRequired__c == true, result1.authentication.idCheckRequired == true);
		System.assertEquals(null, result1.authentication.smsPhoneNumbers);
		System.assertEquals(r1.Note__c, result1.note);
		System.assertNotEquals(null, result1.emailSettings);
		System.assertEquals(r1.Language__c, result1.emailSettings.language);
		System.assertEquals(r1.EmailSubject__c, result1.emailSettings.subject);
		System.assertEquals(r1.EmailMessage__c, result1.emailSettings.message);
		System.assertEquals(r1.HostName__c, result1.hostName);
		System.assertEquals(r1.HostEmail__c, result1.hostEmail);
		System.assertEquals(r1.SignNow__c, result1.signNow);
		System.assertEquals(null, result1.source);

		System.assertNotEquals(null, result2);
		System.assertEquals(r2.Id, result2.id);
		System.assertEquals(r2.Type__c, result2.type);
		System.assertEquals(r2.Sequence__c, result2.sequence);
		System.assertEquals(r2.RoutingOrder__c, result2.routingOrder);
		System.assertNotEquals(null, result2.role);
		System.assertEquals(r2.Role__c, result2.role.name);
		System.assertEquals(r2.Name, result2.name);
		System.assertEquals(r2.Email__c, result2.email);
		System.assertEquals(null, result2.signingGroup);
		System.assertEquals(r2.SmsPhoneNumber__c, result2.phone);
		System.assertNotEquals(null, result2.authentication);
		System.assertEquals(r2.AccessCode__c, result2.authentication.accessCode);
		System.assertEquals(r2.IdCheckRequired__c == true, result2.authentication.idCheckRequired == true);
		System.assertEquals(new List<String> { r2.SmsPhoneNumber__c }, result2.authentication.smsPhoneNumbers);
		System.assertEquals(r2.Note__c, result2.note);
		System.assertNotEquals(null, result2.emailSettings);
		System.assertEquals(r2.Language__c, result2.emailSettings.language);
		System.assertEquals(r2.EmailSubject__c, result2.emailSettings.subject);
		System.assertEquals(r2.EmailMessage__c, result2.emailSettings.message);
		System.assertEquals(r2.HostName__c, result2.hostName);
		System.assertEquals(r2.HostEmail__c, result2.hostEmail);
		System.assertEquals(r2.SignNow__c, result2.signNow);
		System.assertNotEquals(null, result2.source);
		System.assertEquals(r2.SourceId__c, result2.source.id);
	}

	static testMethod void test_getRecipients_unauthorized() {
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

	static testMethod void test_getRecipients_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			Contact c3 = TestUtils.createContact(a2.Id);

			Test.startTest();
			List<Recipient> result = RecipientService.getRecipients('Account', new Set<Id> { a1.Id, a2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			System.assertNotEquals(null, result[0]);
			System.assertEquals(null, result[0].id);
			System.assertEquals(Recipient.TYPE_SIGNER, result[0].type);
			System.assertNotEquals(null, result[0].source);
			System.assertEquals('Contact', result[0].source.type);

			System.assertNotEquals(null, result[1]);
			System.assertEquals(null, result[1].id);
			System.assertEquals(Recipient.TYPE_SIGNER, result[1].type);
			System.assertNotEquals(null, result[1].source);
			System.assertEquals('Contact', result[1].source.type);
		}
	}

	static testMethod void test_searchRecipients_unauthorized() {
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

	static testMethod void test_searchRecipients_CompoundMatchBeginning() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = SearchBehavior.CompoundMatchBeginning.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients('Lead', 'AB', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	static testMethod void test_searchRecipients_CompoundMatchExact() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = SearchBehavior.CompoundMatchExact.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients('Lead', 'AB', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(0, result.size());
		}
	}

	static testMethod void test_searchRecipients_CompoundMatchAny() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = SearchBehavior.CompoundMatchAny.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients('Lead', 'WX', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
		}
	}

	static testMethod void test_searchRecipients_DiscreteMatchBeginning() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = SearchBehavior.DiscreteMatchBeginning.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients('Lead', 'AB', 'WX');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
		}
	}

	static testMethod void test_searchRecipients_DiscreteMatchExact() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = SearchBehavior.DiscreteMatchExact.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients('Lead', 'ABCD', 'EFGH');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
		}
	}

	static testMethod void test_searchRecipients_DiscreteMatchAny() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.RecipientSearchBehavior__c = SearchBehavior.DiscreteMatchAny.name();
			update s;

			Lead l1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead l2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead l3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { l1, l2, l3 };

			Test.startTest();
			List<Recipient> result = RecipientService.searchRecipients('Lead', 'BC', 'XY');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
		}
	}
}
