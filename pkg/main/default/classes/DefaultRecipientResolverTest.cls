@IsTest
private class DefaultRecipientResolverTest {

	@IsTest
	static void test_canResolveRecipients() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canResolveRecipients(Schema.Account.getSObjectType()));
		System.assert(rr.canResolveRecipients(Schema.Case.getSObjectType()));
		System.assert(rr.canResolveRecipients(Schema.Contact.getSObjectType()));
		System.assert(rr.canResolveRecipients(Schema.Lead.getSObjectType()));
		System.assert(rr.canResolveRecipients(Schema.Opportunity.getSObjectType()));
		System.assert(rr.canResolveRecipients(Schema.User.getSObjectType()));
		System.assert(!rr.canResolveRecipients(Schema.Envelope__c.getSObjectType()));
		System.assert(!rr.canResolveRecipients(null));
		Test.stopTest();
	}

	@IsTest
	static void test_canSearchRecipients() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canSearchRecipients(Schema.Contact.getSObjectType()));
		System.assert(rr.canSearchRecipients(Schema.Lead.getSObjectType()));
		System.assert(rr.canSearchRecipients(Schema.User.getSObjectType()));
		System.assert(!rr.canSearchRecipients(Schema.Envelope__c.getSObjectType()));
		System.assert(!rr.canSearchRecipients(null));
		Test.stopTest();
	}

	@IsTest
	static void test_getRecipients_Account() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			Contact c3 = TestUtils.createContact(a2.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients(Schema.Account.getSObjectType(), new Set<Id> { a1.Id, a2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			Boolean foundC1 = false, foundC2 = false, foundC3 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals(Schema.Contact.getSObjectType(), r.source.type);
				System.assertNotEquals(null, r.source.parent);
				System.assertEquals(Schema.Account.getSObjectType(), r.source.parent.type);
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

	@IsTest
	static void test_getRecipients_Case() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a2.Id);
			Case cs1 = TestUtils.createCase(a1.Id, c1.Id);
			Case cs2 = TestUtils.createCase(a2.Id, c2.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients(Schema.Case.getSObjectType(), new Set<Id> { cs1.Id, cs2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundC1 = false, foundC2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals(Schema.Contact.getSObjectType(), r.source.type);
				System.assertNotEquals(null, r.source.parent);
				System.assertEquals(Schema.Case.getSObjectType(), r.source.parent.type);
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

	@IsTest
	static void test_getRecipients_Contact() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(null);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients(Schema.Contact.getSObjectType(), new Set<Id> { c1.Id, c2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundC1 = false, foundC2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals(Schema.Contact.getSObjectType(), r.source.type);
				if (r.source.id == c1.Id) {
					foundC1 = true;
					System.assertNotEquals(null, r.source.parent);
					System.assertEquals(Schema.Account.getSObjectType(), r.source.parent.type);
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

	@IsTest
	static void test_getRecipients_Lead() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Lead l1 = TestUtils.createLead();
			Lead l2 = TestUtils.createLead();
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients(Schema.Lead.getSObjectType(), new Set<Id> { l1.Id, l2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundL1 = false, foundL2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals(Schema.Lead.getSObjectType(), r.source.type);
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

	@IsTest
	static void test_getRecipients_Opportunity() {
		System.runAs(UserMock.createUser()) {
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
			List<Recipient> result = rr.getRecipients(Schema.Opportunity.getSObjectType(), new Set<Id> { o1.Id, o2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size());

			Boolean foundC1 = false, foundC2 = false, foundC3 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals(Schema.Contact.getSObjectType(), r.source.type);
				System.assertNotEquals(null, r.source.parent);
				System.assertEquals(Schema.Account.getSObjectType(), r.source.parent.type);
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

	@IsTest
	static void test_getRecipients_Opportunity_no_access() {
		// Expect only one contact (c2Id) belonging to account to be shared with default settings
		// This may break if sharing settings are customized, so skip if OWS contact setting is not ControlledByParent.
		if ([SELECT DefaultContactAccess FROM Organization LIMIT 1].DefaultContactAccess == 'ControlledByParent') {
			Id oId, aId, c1Id, c2Id, c3Id;

			System.runAs(UserMock.createUser()) {
				aId = TestUtils.createAccount().Id;
				c1Id = TestUtils.createContact(null).Id;
				c2Id = TestUtils.createContact(aId).Id;
				c3Id = TestUtils.createContact(null).Id;
				oId = TestUtils.createOpportunity(aId).Id;
				TestUtils.createOpportunityContactRole(oId, c1Id);
				TestUtils.createOpportunityContactRole(oId, c2Id);
				TestUtils.createOpportunityContactRole(oId, c3Id);
			}

			System.runAs(UserMock.createUser()) {
				Test.startTest();
				List<Recipient> result = new DefaultRecipientResolver().getRecipients(
					Opportunity.getSObjectType(),
					new Set<Id> { oId });
				Test.stopTest();

				System.assertEquals(1, Collection.size(result));
				System.assertNotEquals(null, result[0]);
				System.assertNotEquals(null, result[0].source);
				System.assertEquals(c2Id, result[0].source.id);
			}
		}
	}

	@IsTest
	static void test_getRecipients_User() {
		System.runAs(UserMock.createAdministrator()) {
			User u1 = UserMock.createUser();
			User u2 = UserMock.createUser();
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRecipients(Schema.User.getSObjectType(), new Set<Id> { u1.Id, u2.Id });
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			Boolean foundU1 = false, foundU2 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertEquals(User.getSObjectType(), r.source.type);
				System.assertEquals(null, r.source.parent);
				if (r.source.id == u1.Id) {
					foundU1 = true;
					System.assertEquals(StringUtils.mkName(u1.FirstName, u1.LastName), r.name);
					System.assertEquals(u1.Email, r.email);
					System.assertEquals(u1.Phone, r.phone);
				} else if (r.source.id == u2.Id) {
					foundU2 = true;
					System.assertEquals(StringUtils.mkName(u1.FirstName, u1.LastName), r.name);
					System.assertEquals(u2.Email, r.email);
					System.assertEquals(u2.Phone, r.phone);
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
			}
			System.assert(foundU1);
			System.assert(foundU2);
		}
	}

	@IsTest
	static void test_getRecipients_invalid() {
		System.runAs(UserMock.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.getRecipients(Organization.getSObjectType(), new Set<Id> { UserInfo.getOrganizationId() });
				throw new AssertException('Expected getRecipients to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveRecipientSource_1, new List<String> {
					String.valueOf(Organization.getSObjectType())
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	// TODO: Determine if there's a way to test this with encrypted (probabilistic and deterministic) and unencrypted fields.
	@IsTest
	static void test_searchRecipients_Contact() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = new Contact(FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111', AccountId = a1.Id);
			Contact c2 = new Contact(FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Contact c3 = new Contact(FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Contact> { c1, c2, c3 };
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), null, null, Recipient.SearchBehavior.DiscreteMatchExact));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), 'ABCD', null, Recipient.SearchBehavior.DiscreteMatchExact));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), 'ABCD', 'WXYZ', Recipient.SearchBehavior.DiscreteMatchExact));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), 'BC', 'WXYZ', Recipient.SearchBehavior.DiscreteMatchAny));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), '', 'EF', Recipient.SearchBehavior.DiscreteMatchAny));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), '', 'EF', Recipient.SearchBehavior.DiscreteMatchBeginning));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), 'ABCD', 'EFGH', Recipient.SearchBehavior.CompoundMatchExact));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), 'D E', null, Recipient.SearchBehavior.CompoundMatchAny));
			System.assertNotEquals(null, rr.searchRecipients(Schema.Contact.getSObjectType(), 'ABCD', null, Recipient.SearchBehavior.CompoundMatchBeginning));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_searchRecipients_Lead() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Lead c1 = new Lead(Company = 'Unit Test 1', FirstName = 'ABCD', LastName = 'WXYZ', Email = 'c1@unit.test', MobilePhone = '5555551111');
			Lead c2 = new Lead(Company = 'Unit Test 2', FirstName = 'ABCD', LastName = 'EFGH', Email = 'c2@unit.test', Phone = '5555552222');
			Lead c3 = new Lead(Company = 'Unit Test 3', FirstName = 'EFGH', LastName = 'WXYZ', Email = 'c3@unit.test');
			insert new List<Lead> { c1, c2, c3 };
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			System.assertNotEquals(null, rr.searchRecipients(Schema.Lead.getSObjectType(), 'ABCD', null, null));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_searchRecipients_User() {
		System.runAs(UserMock.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			System.assertNotEquals(null, rr.searchRecipients(Schema.User.getSObjectType(), UserInfo.getFirstName(), null, null));
			Test.stopTest();
		}
	}

	// DFS-4571
	@IsTest
	static void test_search_with_apostrophe() {
		System.runAs(UserMock.createAdministrator()) {
			Contact c = new Contact(FirstName = 'Amy', LastName = 'O\'Hare');
			insert c;

			Lead l = new Lead(FirstName = 'Amy', LastName = 'O\'Hare', Company = 'test');
			insert l;

			User u = new User(FirstName = 'Amy', LastName = 'O\'Hare', Username = UUID.randomUUID().toString() + '@unit.test',
				Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1',
				ProfileId = UserInfo.getProfileId(), LanguageLocaleKey = 'en_US', Email = UUID.randomUUID().toString() + '@unit.test');
			insert u;

			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> contacts = rr.searchRecipients(Schema.Contact.getSObjectType(), 'Amy O\'H', null, Recipient.SearchBehavior.CompoundMatchBeginning);
			List<Recipient> leads = rr.searchRecipients(Schema.Lead.getSObjectType(), 'Amy O\'H', null, Recipient.SearchBehavior.CompoundMatchBeginning);
			List<Recipient> users = rr.searchRecipients(Schema.User.getSObjectType(), 'Amy O\'H', null, Recipient.SearchBehavior.CompoundMatchBeginning);
			Test.stopTest();

			System.assertNotEquals(null, contacts);
			System.assertEquals(1, contacts.size());
			System.assertNotEquals(null, contacts[0].source);
			System.assertEquals(c.Id, contacts[0].source.id);

			System.assertNotEquals(null, leads);
			System.assertEquals(1, leads.size());
			System.assertNotEquals(null, leads[0].source);
			System.assertEquals(l.Id, leads[0].source.id);

			System.assertNotEquals(null, users);
			System.assertEquals(1, users.size());
			System.assertNotEquals(null, users[0].source);
			System.assertEquals(u.Id, users[0].source.id);
		}
	}

	@IsTest
	static void test_searchRecipients_invalid() {
		System.runAs(UserMock.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.searchRecipients(Schema.Opportunity.getSObjectType(), null, null, null);
				throw new AssertException('Expected searchRecipients to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveRecipientSource_1, new List<String> {
					String.valueOf(Schema.Opportunity.getSObjectType())
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}
}