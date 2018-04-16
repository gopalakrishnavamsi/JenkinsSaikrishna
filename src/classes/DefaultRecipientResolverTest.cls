@IsTest
private class DefaultRecipientResolverTest {

	static testMethod void test_canResolveRecipients() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canResolveRecipients('Account'));
		System.assert(rr.canResolveRecipients(' CASE '));
		System.assert(rr.canResolveRecipients('\ncontact'));
		System.assert(rr.canResolveRecipients('Lead'));
		System.assert(rr.canResolveRecipients('Opportunity'));
		System.assert(!rr.canResolveRecipients('whatever'));
		System.assert(!rr.canResolveRecipients(null));
		System.assert(!rr.canResolveRecipients(' '));
		Test.stopTest();
	}

	static testMethod void test_canSearchRecipients() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canSearchRecipients('Contact'));
		System.assert(rr.canSearchRecipients(' LEAD '));
		System.assert(rr.canSearchRecipients('\nuser'));
		System.assert(!rr.canSearchRecipients('whatever'));
		System.assert(!rr.canSearchRecipients(null));
		System.assert(!rr.canSearchRecipients(' '));
		Test.stopTest();
	}

	static testMethod void test_getRecipients_Account() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			Contact c3 = TestUtils.createContact(a2.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients('Account', new Set<Id> { a1.Id, a2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			Boolean foundC1 = false, foundC2 = false, foundC3 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals('Contact', r.source.type);
				System.assertNotEquals(null, r.source.parent);
				System.assertEquals('Account', r.source.parent.type);
				if (r.source.id == c1.Id) {
					foundC1 = true;
					System.assertEquals(a1.Id, r.source.parent.id);
					System.assertEquals(a1.Name, r.source.parent.name);
					System.assertEquals(c1.Name, r.name);
					System.assertEquals(c1.Email, r.email);
					System.assertEquals(c1.Phone, r.phone);
				} else if (r.source.id == c2.Id) {
					foundC2 = true;
					System.assertEquals(a1.Id, r.source.parent.id);
					System.assertEquals(a1.Name, r.source.parent.name);
					System.assertEquals(c2.Name, r.name);
					System.assertEquals(c2.Email, r.email);
					System.assertEquals(c2.Phone, r.phone);
				} else if (r.source.id == c3.Id) {
					foundC3 = true;
					System.assertEquals(a2.Id, r.source.parent.id);
					System.assertEquals(a2.Name, r.source.parent.name);
					System.assertEquals(c3.Name, r.name);
					System.assertEquals(c3.Email, r.email);
					System.assertEquals(c3.Phone, r.phone);
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
			}
			System.assert(foundC1);
			System.assert(foundC2);
			System.assert(foundC3);
		}
	}

	static testMethod void test_getRecipients_Case() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a2.Id);
			Case cs1 = TestUtils.createCase(a1.Id, c1.Id);
			Case cs2 = TestUtils.createCase(a2.Id, c2.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients('Case', new Set<Id> { cs1.Id, cs2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundC1 = false, foundC2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals('Contact', r.source.type);
				System.assertNotEquals(null, r.source.parent);
				System.assertEquals('Case', r.source.parent.type);
				if (r.source.id == c1.Id) {
					foundC1 = true;
					System.assertEquals(cs1.Id, r.source.parent.id);
					System.assertEquals(cs1.CaseNumber, r.source.parent.name);
					System.assertEquals(c1.Name, r.name);
					System.assertEquals(c1.Email, r.email);
					System.assertEquals(c1.Phone, r.phone);
				} else if (r.source.id == c2.Id) {
					foundC2 = true;
					System.assertEquals(cs2.Id, r.source.parent.id);
					System.assertEquals(cs2.CaseNumber, r.source.parent.name);
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

	static testMethod void test_getRecipients_Contact() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(null);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients('Contact', new Set<Id> { c1.Id, c2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundC1 = false, foundC2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals('Contact', r.source.type);
				if (r.source.id == c1.Id) {
					foundC1 = true;
					System.assertNotEquals(null, r.source.parent);
					System.assertEquals('Account', r.source.parent.type);
					System.assertEquals(a1.Id, r.source.parent.id);
					System.assertEquals(a1.Name, r.source.parent.name);
					System.assertEquals(c1.Name, r.name);
					System.assertEquals(c1.Email, r.email);
					System.assertEquals(c1.Phone, r.phone);
				} else if (r.source.id == c2.Id) {
					foundC2 = true;
					System.assertEquals(null, r.source.parent);
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

	static testMethod void test_getRecipients_Lead() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Lead l1 = TestUtils.createLead();
			Lead l2 = TestUtils.createLead();
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients('Lead', new Set<Id> { l1.Id, l2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundL1 = false, foundL2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals('Lead', r.source.type);
				System.assertEquals(null, r.source.parent);
				if (r.source.id == l1.Id) {
					foundL1 = true;
					System.assertEquals(l1.Name, r.name);
					System.assertEquals(l1.Email, r.email);
					System.assertEquals(l1.Phone, r.phone);
				} else if (r.source.id == l2.Id) {
					foundL2 = true;
					System.assertEquals(l2.Name, r.name);
					System.assertEquals(l2.Email, r.email);
					System.assertEquals(l2.Phone, r.phone);
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
			}
			System.assert(foundL1);
			System.assert(foundL2);
		}
	}

	static testMethod void test_getRecipients_Opportunity() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			Contact c3 = TestUtils.createContact(a2.Id);
			Opportunity o1 = TestUtils.createOpportunity(a1.Id);
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o1.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o1.Id, c2.Id);
			Opportunity o2 = TestUtils.createOpportunity(a2.Id);
			OpportunityContactRole ocr3 = TestUtils.createOpportunityContactRole(o2.Id, c3.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients('Opportunity', new Set<Id> { o1.Id, o2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			Boolean foundC1 = false, foundC2 = false, foundC3 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals('Contact', r.source.type);
				System.assertNotEquals(null, r.source.parent);
				System.assertEquals('Account', r.source.parent.type);
				if (r.source.id == c1.Id) {
					foundC1 = true;
					System.assertEquals(a1.Id, r.source.parent.id);
					System.assertEquals(a1.Name, r.source.parent.name);
					System.assertEquals(c1.Name, r.name);
					System.assertEquals(c1.Email, r.email);
					System.assertEquals(c1.Phone, r.phone);
					System.assertNotEquals(null, r.role);
					System.assertEquals(ocr1.Role, r.role.name);
				} else if (r.source.id == c2.Id) {
					foundC2 = true;
					System.assertEquals(a1.Id, r.source.parent.id);
					System.assertEquals(a1.Name, r.source.parent.name);
					System.assertEquals(c2.Name, r.name);
					System.assertEquals(c2.Email, r.email);
					System.assertEquals(c2.Phone, r.phone);
					System.assertNotEquals(null, r.role);
					System.assertEquals(ocr2.Role, r.role.name);
				} else if (r.source.id == c3.Id) {
					foundC3 = true;
					System.assertEquals(a2.Id, r.source.parent.id);
					System.assertEquals(a2.Name, r.source.parent.name);
					System.assertEquals(c3.Name, r.name);
					System.assertEquals(c3.Email, r.email);
					System.assertEquals(c3.Phone, r.phone);
					System.assertNotEquals(null, r.role);
					System.assertEquals(ocr3.Role, r.role.name);
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
			}
			System.assert(foundC1);
			System.assert(foundC2);
			System.assert(foundC3);
		}
	}

	static testMethod void test_getRecipients_invalid() {
		System.runAs(TestUtils.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.getRecipients('User', new Set<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected getRecipients to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveRecipientSource_1, new List<String> { 'User' }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	// TODO: Determine if there's a way to test this with encrypted (probabalistic and deterministic) and uncrypted fields.
	static testMethod void test_searchRecipients_Contact() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = new Contact(FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111', AccountId = a1.Id);
			Contact c2 = new Contact(FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Contact c3 = new Contact(FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Contact> { c1, c2, c3 };
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			System.assertNotEquals(null, rr.searchRecipients('Contact', null, null, SearchBehavior.SimpleMatchExact));
			System.assertNotEquals(null, rr.searchRecipients('Contact', 'ABCD', null, SearchBehavior.SimpleMatchExact));
			System.assertNotEquals(null, rr.searchRecipients('Contact', 'ABCD', 'WXYZ', SearchBehavior.SimpleMatchExact));
			System.assertNotEquals(null, rr.searchRecipients('Contact', 'BC', 'WXYZ', SearchBehavior.SimpleMatchAny));
			System.assertNotEquals(null, rr.searchRecipients('Contact', '', 'EF', SearchBehavior.SimpleMatchAny));
			System.assertNotEquals(null, rr.searchRecipients('Contact', '', 'EF', SearchBehavior.SimpleMatchBeginning));
			System.assertNotEquals(null, rr.searchRecipients('Contact', 'ABCD', 'EFGH', SearchBehavior.CompoundMatchExact));
			System.assertNotEquals(null, rr.searchRecipients('Contact', 'D E', null, SearchBehavior.CompoundMatchAny));
			System.assertNotEquals(null, rr.searchRecipients('Contact', 'ABCD', null, SearchBehavior.CompoundMatchBeginning));
			Test.stopTest();
		}
	}

	static testMethod void test_searchRecipients_Lead() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Lead c1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead c2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead c3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { c1, c2, c3 };
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			System.assertNotEquals(null, rr.searchRecipients('Lead', 'ABCD', null, null));
			Test.stopTest();
		}
	}

	static testMethod void test_searchRecipients_User() {
		System.runAs(TestUtils.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			System.assertNotEquals(null, rr.searchRecipients('User', UserInfo.getFirstName(), null, null));
			Test.stopTest();
		}
	}

	static testMethod void test_searchRecipients_invalid() {
		System.runAs(TestUtils.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.searchRecipients('Opportunity', null, null, null);
				throw new AssertException('Expected searchRecipients to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveRecipientSource_1, new List<String> { 'Opportunity' }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
