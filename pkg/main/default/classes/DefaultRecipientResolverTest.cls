@IsTest
private class DefaultRecipientResolverTest {

	@IsTest
	static void test_canResolveRelatedRecipients() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canResolveRelatedRecipients(Schema.Contact.getSObjectType()));
		System.assert(rr.canResolveRelatedRecipients(Schema.Lead.getSObjectType()));
		System.assert(rr.canResolveRelatedRecipients(Schema.User.getSObjectType()));
		System.assert(rr.canResolveRelatedRecipients(Schema.OpportunityContactRole.getSObjectType()));
		System.assert(rr.canResolveRelatedRecipients(Schema.CaseContactRole.getSObjectType()));
		System.assert(!rr.canResolveRelatedRecipients(Schema.Account.getSObjectType()));
		System.assert(!rr.canResolveRelatedRecipients(Schema.Envelope__c.getSObjectType()));
		System.assert(!rr.canResolveRelatedRecipients(null));
		Test.stopTest();
	}

	@IsTest
	static void test_canResolveSourceRecipients() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canResolveSourceRecipients(Schema.Account.getSObjectType()));
		System.assert(rr.canResolveSourceRecipients(Schema.Case.getSObjectType()));
		System.assert(rr.canResolveSourceRecipients(Schema.Contact.getSObjectType()));
		System.assert(rr.canResolveSourceRecipients(Schema.Lead.getSObjectType()));
		System.assert(rr.canResolveSourceRecipients(Schema.Opportunity.getSObjectType()));
		System.assert(rr.canResolveSourceRecipients(Schema.User.getSObjectType()));
		System.assert(!rr.canResolveSourceRecipients(Schema.Envelope__c.getSObjectType()));
		System.assert(!rr.canResolveSourceRecipients(null));
		Test.stopTest();
	}

	@IsTest
	static void test_canResolveRecipientType() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		System.assert(rr.canResolveRecipientType(Schema.Contact.getSObjectType()));
		System.assert(rr.canResolveRecipientType(Schema.Lead.getSObjectType()));
		System.assert(rr.canResolveRecipientType(Schema.User.getSObjectType()));
		System.assert(!rr.canResolveRecipientType(Schema.Envelope__c.getSObjectType()));
		System.assert(!rr.canResolveRecipientType(null));
		Test.stopTest();
	}

	@IsTest
	static void test_getSourceRecipients_Account() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a1.Id);
			Contact c3 = TestUtils.createContact(a2.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getSourceRecipients(
				Schema.Account.getSObjectType(),
				new Set<Id> { a1.Id, a2.Id });
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
	static void test_getSourceRecipients_Case() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(a2.Id);
			Case cs1 = TestUtils.createCase(a1.Id, c1.Id);
			Case cs2 = TestUtils.createCase(a2.Id, c2.Id);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getSourceRecipients(
				Schema.Case.getSObjectType(),
				new Set<Id> { cs1.Id, cs2.Id });
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
	static void test_getSourceRecipients_Contact() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a1 = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a1.Id);
			Contact c2 = TestUtils.createContact(null);
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getSourceRecipients(Schema.Contact.getSObjectType(), new Set<Id> { c1.Id, c2.Id });
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
	static void test_getSourceRecipients_Lead() {
		System.runAs(UserMock.createUser()) {
			Lead l1 = TestUtils.createLead();
			Lead l2 = TestUtils.createLead();
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getSourceRecipients(Schema.Lead.getSObjectType(), new Set<Id> { l1.Id, l2.Id });
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
	static void test_getSourceRecipients_Opportunity() {
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
			List<Recipient> result = rr.getSourceRecipients(Schema.Opportunity.getSObjectType(), new Set<Id> { o1.Id, o2.Id });
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
	static void test_getSourceRecipients_Opportunity_no_access() {
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
				List<Recipient> result = new DefaultRecipientResolver().getSourceRecipients(
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
	static void test_getSourceRecipients_User() {
		System.runAs(UserMock.createAdministrator()) {
			User u1 = UserMock.createUser();
			User u2 = UserMock.createUser();
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getSourceRecipients(Schema.User.getSObjectType(), new Set<Id> { u1.Id, u2.Id });
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
	static void test_getSourceRecipients_invalid() {
		System.runAs(UserMock.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.getSourceRecipients(Organization.getSObjectType(), new Set<Id> { UserInfo.getOrganizationId() });
				throw new AssertException('Expected getSourceRecipients to fail');
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

	@IsTest
	static void test_executeQuery_lookup() {
		Schema.Account a1 = TestUtils.createAccount();
		Opportunity o1 = TestUtils.createOpportunity(a1.Id);
		a1.Name = 'a1';
		a1.AccountNumber = '0001';
		Schema.Account a2 = TestUtils.createAccount();
		a2.Name = 'a2';
		a2.AccountNumber = '0002';
		Opportunity o2 = TestUtils.createOpportunity(a2.Id);
		Schema.Account b1 = TestUtils.createAccount();
		b1.Name = 'b1';
		b1.AccountNumber = '0003';
		Opportunity o3 = TestUtils.createOpportunity(b1.Id);
		Schema.Account b2 = TestUtils.createAccount();
		b2.Name = 'b2';
		b2.AccountNumber = '0004';
		Opportunity o4 = TestUtils.createOpportunity(b2.Id);
		update new List<Schema.Account> { a1, a2, b1, b2 };

		Test.startTest();
		List<SObject> result = DefaultRecipientResolver.executeQuery(
			Opportunity.getSObjectType(),
			new List<String> { 'Name', 'AccountNumber' },
			new Set<Id> { o1.Id, o2.Id, o3.Id, o4.Id },
			new Query.Relationship(
				true,
				'Account',
				'Account',
				'Account'),
			new Query.Filter(
				'Account.Name LIKE \'b%\'',
				'Account.AccountNumber DESC',
				1)); // expect only b2
		Test.stopTest();

		System.assertEquals(1, Collection.size(result));
		System.assertNotEquals(null, result[0]);
		System.assert(result[0] instanceof Schema.Opportunity);
		Schema.Account a = (Schema.Account)result[0].getSObject('Account');
		System.assertEquals(b2.Name, a.Name);
		System.assertEquals(b2.AccountNumber, a.AccountNumber);
	}

	@IsTest
	static void test_executeQuery_related_list() {
		Schema.Account a1 = TestUtils.createAccount();
		Opportunity o1 = TestUtils.createOpportunity(a1.Id);
		Contact c1 = TestUtils.createContact(a1.Id);
		c1.FirstName = 'a4';
		OpportunityContactRole o1c1 = TestUtils.createOpportunityContactRole(o1.Id, c1.Id);
		Contact c2 = TestUtils.createContact(a1.Id);
		c2.FirstName = 'b2';
		TestUtils.createOpportunityContactRole(o1.Id, c2.Id);
		Contact c3 = TestUtils.createContact(a1.Id);
		c3.FirstName = 'b3';
		TestUtils.createOpportunityContactRole(o1.Id, c3.Id);
		Schema.Account a2 = TestUtils.createAccount();
		Opportunity o2 = TestUtils.createOpportunity(a2.Id);
		Contact c4 = TestUtils.createContact(a2.Id);
		c4.FirstName = 'a1';
		TestUtils.createOpportunityContactRole(o2.Id, c4.Id);
		Contact c5 = TestUtils.createContact(a2.Id);
		c5.FirstName = 'a2';
		OpportunityContactRole o2c5 = TestUtils.createOpportunityContactRole(o2.Id, c5.Id);
		Contact c6 = TestUtils.createContact(a2.Id);
		c6.FirstName = 'a3';
		OpportunityContactRole o2c6 = TestUtils.createOpportunityContactRole(o2.Id, c6.Id);
		update new List<Contact> { c1, c2, c3, c4, c5, c6 };
		Query.Relationship r = new Query.Relationship(
			false,
			'OpportunityContactRoles',
			'Opportunity Contact Roles',
			'OpportunityContactRole');
		Query.Filter f = new Query.Filter(
			'Contact.Name LIKE \'a%\'',
			'Contact.Name DESC',
			2); // expect (o1.c1) and (o2.c6, o2.c5)

		Test.startTest();
		List<SObject> result = DefaultRecipientResolver.executeQuery(
			Opportunity.getSObjectType(),
			new List<String> { 'Role', 'Contact.Name' },
			new Set<Id> { o1.Id, o2.Id },
			r,
			f);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		System.assertNotEquals(null, result[0]);
		System.assert(result[0] instanceof Opportunity);
		System.assertEquals(o1.Id, result[0].Id);
		List<OpportunityContactRole> ocrs = ((Opportunity)result[0]).OpportunityContactRoles;
		System.assertEquals(1, Collection.size(ocrs));
		System.assertNotEquals(null, ocrs[0]);
		System.assertEquals(o1c1.Id, ocrs[0].Id);
		System.assertEquals(c1.Id, ocrs[0].ContactId);
		System.assertNotEquals(null, ocrs[0].Contact.Name);
		System.assert(ocrs[0].isSet('Role'));
		ocrs = ((Opportunity)result[1]).OpportunityContactRoles;
		System.assertEquals(2, Collection.size(ocrs));
		System.assertNotEquals(null, ocrs[0]);
		System.assertEquals(o2c6.Id, ocrs[0].Id);
		System.assertEquals(c6.Id, ocrs[0].ContactId);
		System.assertNotEquals(null, ocrs[0].Contact.Name);
		System.assert(ocrs[0].isSet('Role'));
		System.assertNotEquals(null, ocrs[1]);
		System.assertEquals(o2c5.Id, ocrs[1].Id);
		System.assertEquals(c5.Id, ocrs[1].ContactId);
		System.assertNotEquals(null, ocrs[1].Contact.Name);
		System.assert(ocrs[1].isSet('Role'));
	}

	@IsTest
	static void test_getRelatedRecipients_invalid_arguments() {
		System.runAs(UserMock.createUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.getRelatedRecipients(null, null, null, null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedType, ex.getMessage());
			}
			try {
				rr.getRelatedRecipients(Opportunity.getSObjectType(), null, null, null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedRelationship, ex.getMessage());
			}
			try {
				rr.getRelatedRecipients(Opportunity.getSObjectType(), null, new Query.Relationship(true, null, null, 'User'), null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedRelationship, ex.getMessage());
			}
			try {
				rr.getRelatedRecipients(Opportunity.getSObjectType(), null, new Query.Relationship(true, 'Owner', null, ''), null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedRelationship, ex.getMessage());
			}
			try {
				rr.getRelatedRecipients(Opportunity.getSObjectType(), null, new Query.Relationship(true, 'Owner', null, 'Opportunity'), null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotResolveRecipientSource_1,
					new List<Object> { 'Opportunity' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRelatedRecipients_unauthorized() {
		Schema.Account a = TestUtils.createAccount();

		System.runAs(UserMock.createRestrictedUser()) {
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			try {
				rr.getRelatedRecipients(
					Contact.getSObjectType(),
					new Set<Id> { a.Id },
					new Query.Relationship(
						false,
						'Contacts',
						'Contacts',
						'Contact'),
					null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRelatedRecipients_Contact_lookup() {
		Schema.Account a1 = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a1.Id);
		Case cs1 = TestUtils.createCase(a1.Id, c1.Id);
		Schema.Account a2 = TestUtils.createAccount();
		Contact c2 = TestUtils.createContact(a2.Id);
		Case cs2 = TestUtils.createCase(a2.Id, c2.Id);
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Schema.Case.getSObjectType(),
			new Set<Id> { cs1.Id, cs2.Id },
			new Query.Relationship(
				true,
				'Contact',
				'Contact',
				'Contact'),
			null);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		Boolean foundC1 = false, foundC2 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			Contact expected = null;
			if (r.source.id == c1.Id && !foundC1) {
				foundC1 = true;
				expected = c1;
			} else if (r.source.id == c2.Id && !foundC2) {
				foundC2 = true;
				expected = c2;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundC1 && foundC2);
	}

	@IsTest
	static void test_getRelatedRecipients_Contact_related_list() {
		Schema.Account a1 = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a1.Id);
		Contact c2 = TestUtils.createContact(a1.Id);
		Schema.Account a2 = TestUtils.createAccount();
		Contact c3 = TestUtils.createContact(a2.Id);
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Schema.Account.getSObjectType(),
			new Set<Id> { a1.Id, a2.Id },
			new Query.Relationship(
				false,
				'Contacts',
				'Contacts',
				'Contact'),
			null);
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		Boolean foundC1 = false, foundC2 = false, foundC3 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			Contact expected = null;
			if (r.source.id == c1.Id && !foundC1) {
				foundC1 = true;
				expected = c1;
			} else if (r.source.id == c2.Id && !foundC2) {
				foundC2 = true;
				expected = c2;
			} else if (r.source.id == c3.Id && !foundC3) {
				foundC3 = true;
				expected = c3;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundC1 && foundC2 && foundC3);
	}

	@IsTest
	static void test_getRelatedRecipients_Lead_lookup() {
		if (!Salesforce.isValidSObject('Campaign')
			|| !Salesforce.isValidSObject('CampaignMember')) {

			return;
		}

		Lead l1 = TestUtils.createLead();
		Lead l2 = TestUtils.createLead();
		SObject c1 = Salesforce.getSObjectType('Campaign').newSObject();
		c1.put('Name', UUID.randomUUID().toString());
		insert c1;
		SObjectType cmType = Salesforce.getSObjectType('CampaignMember');
		SObject cm1 = cmType.newSObject();
		cm1.put('CampaignId', c1.Id);
		cm1.put('LeadId', l1.Id);
		SObject cm2 = cmType.newSObject();
		cm2.put('CampaignId', c1.Id);
		cm2.put('LeadId', l2.Id);
		insert new List<SObject> { cm1, cm2 };
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Schema.CampaignMember.getSObjectType(),
			new Set<Id> { cm1.Id, cm2.Id },
			new Query.Relationship(
				true,
				'Lead',
				'Lead',
				'Lead'),
			null);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		Boolean foundL1 = false, foundL2 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			Lead expected = null;
			if (r.source.id == l1.Id && !foundL1) {
				foundL1 = true;
				expected = l1;
			} else if (r.source.id == l2.Id && !foundL2) {
				foundL2 = true;
				expected = l2;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundL1 && foundL2);
	}

	@IsTest
	static void test_getRelatedRecipients_Lead_related_list() {
		Individual i1 = new Individual(
			FirstName = UUID.randomUUID().toString(),
			LastName = UUID.randomUUID().toString());
		Individual i2 = new Individual(
			FirstName = UUID.randomUUID().toString(),
			LastName = UUID.randomUUID().toString());
		insert new List<Individual> { i1, i2 };
		Lead l1 = TestUtils.createLead();
		l1.IndividualId = i1.Id;
		Lead l2 = TestUtils.createLead();
		l2.IndividualId = i1.Id;
		Lead l3 = TestUtils.createLead();
		l3.IndividualId = i2.Id;
		update new List<Lead> { l1, l2, l3 };
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Schema.Individual.getSObjectType(),
			new Set<Id> { i1.Id, i2.Id },
			new Query.Relationship(
				false,
				'Leads',
				'Leads',
				'Lead'),
			null);
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		Boolean foundL1 = false, foundL2 = false, foundL3 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			Lead expected = null;
			if (r.source.id == l1.Id && !foundL1) {
				foundL1 = true;
				expected = l1;
			} else if (r.source.id == l2.Id && !foundL2) {
				foundL2 = true;
				expected = l2;
			} else if (r.source.id == l3.Id && !foundL3) {
				foundL3 = true;
				expected = l3;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundL1 && foundL2 && foundL3);
	}

	@IsTest
	static void test_getRelatedRecipients_User_lookup() {
		Schema.Account a1, a2;
		User u1 = UserMock.createUser();
		System.runAs(u1) {
			a1 = TestUtils.createAccount();
		}
		User u2 = UserMock.createUser();
		System.runAs(u2) {
			a2 = TestUtils.createAccount();
		}
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Schema.Account.getSObjectType(),
			new Set<Id> { a1.Id, a2.Id },
			new Query.Relationship(
				true,
				'CreatedBy',
				'Created By',
				'User'),
			null);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		Boolean foundU1 = false, foundU2 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			User expected = null;
			if (r.source.id == u1.Id && !foundU1) {
				foundU1 = true;
				expected = u1;
			} else if (r.source.id == u2.Id && !foundU2) {
				foundU2 = true;
				expected = u2;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundU1 && foundU2);
	}

	@IsTest
	static void test_getRelatedRecipients_User_related_list() {
		User m1 = UserMock.createUser();
		User u1 = UserMock.createUser();
		u1.ManagerId = m1.Id;
		User m2 = UserMock.createUser();
		User u2 = UserMock.createUser();
		u2.ManagerId = m2.Id;
		User u3 = UserMock.createUser();
		u3.ManagerId = m2.Id;
		update new List<User> { u1, u2, u3 };
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Schema.User.getSObjectType(),
			new Set<Id> { m1.Id, m2.Id },
			new Query.Relationship(
				false,
				'ManagedUsers',
				'Managed Users',
				'User'),
			null);
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		Boolean foundU1 = false, foundU2 = false, foundU3 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			User expected = null;
			if (r.source.id == u1.Id && !foundU1) {
				foundU1 = true;
				expected = u1;
			} else if (r.source.id == u2.Id && !foundU2) {
				foundU2 = true;
				expected = u2;
			} else if (r.source.id == u3.Id && !foundU3) {
				foundU3 = true;
				expected = u3;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundU1 && foundU2 && foundU3);
	}

	@IsTest
	static void test_getRelatedRecipients_OpportunityContactRoles() {
		Schema.Account a1 = TestUtils.createAccount();
		Opportunity o1 = TestUtils.createOpportunity(a1.Id);
		Contact c1 = TestUtils.createContact(a1.Id);
		OpportunityContactRole o1c1 = TestUtils.createOpportunityContactRole(o1.Id, c1.Id);
		o1c1.Role = 'o1c1';
		Contact c2 = TestUtils.createContact(a1.Id);
		OpportunityContactRole o1c2 = TestUtils.createOpportunityContactRole(o1.Id, c2.Id);
		o1c2.Role = 'o1c2';
		Schema.Account a2 = TestUtils.createAccount();
		Opportunity o2 = TestUtils.createOpportunity(a2.Id);
		Contact c3 = TestUtils.createContact(a2.Id);
		OpportunityContactRole o2c3 = TestUtils.createOpportunityContactRole(o2.Id, c3.Id);
		o2c3.Role = 'o2c3';
		update new List<OpportunityContactRole> { o1c1, o1c2, o2c3 };
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Opportunity.getSObjectType(),
			new Set<Id> { o1.Id, o2.Id },
			new Query.Relationship(
				false,
				'OpportunityContactRoles',
				'Opportunity Contact Roles',
				'OpportunityContactRole'),
			null);
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		Boolean foundC1 = false, foundC2 = false, foundC3 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			Contact expected = null;
			if (r.source.id == c1.Id && !foundC1) {
				foundC1 = true;
				expected = c1;
				System.assertEquals('o1c1', r.getRoleName());
			} else if (r.source.id == c2.Id && !foundC2) {
				foundC2 = true;
				expected = c2;
				System.assertEquals('o1c2', r.getRoleName());
			} else if (r.source.id == c3.Id && !foundC3) {
				foundC3 = true;
				expected = c3;
				System.assertEquals('o2c3', r.getRoleName());
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundC1 && foundC2 && foundC3);
	}

	@IsTest
	static void test_getRelatedRecipients_CaseContactRoles() {
		Schema.Account a1 = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a1.Id);
		Case cs1 = TestUtils.createCase(a1.Id, c1.Id);
		CaseContactRole cs1c1 = TestUtils.createCaseContactRole(cs1.Id, c1.Id);
		cs1c1.Role = 'cs1c1';
		Contact c2 = TestUtils.createContact(a1.Id);
		CaseContactRole cs1c2 = TestUtils.createCaseContactRole(cs1.Id, c2.Id);
		cs1c2.Role = 'cs1c2';
		Schema.Account a2 = TestUtils.createAccount();
		Contact c3 = TestUtils.createContact(a2.Id);
		Case cs2 = TestUtils.createCase(a2.Id, c3.Id);
		CaseContactRole cs2c3 = TestUtils.createCaseContactRole(cs2.Id, c3.Id);
		cs2c3.Role = 'cs2c3';
		update new List<CaseContactRole> { cs1c1, cs1c2, cs2c3 };
		DefaultRecipientResolver rr = new DefaultRecipientResolver();

		Test.startTest();
		List<Recipient> result = rr.getRelatedRecipients(
			Case.getSObjectType(),
			new Set<Id> { cs1.Id, cs2.Id },
			new Query.Relationship(
				false,
				'CaseContactRoles',
				'Case Contact Roles',
				'CaseContactRole'),
			null);
		Test.stopTest();

		System.assertEquals(3, Collection.size(result));
		Boolean foundC1 = false, foundC2 = false, foundC3 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.source);
			System.assertNotEquals(null, r.source.id);
			Contact expected = null;
			if (r.source.id == c1.Id && !foundC1) {
				foundC1 = true;
				expected = c1;
				System.assertEquals('cs1c1', r.getRoleName());
			} else if (r.source.id == c2.Id && !foundC2) {
				foundC2 = true;
				expected = c2;
				System.assertEquals('cs1c2', r.getRoleName());
			} else if (r.source.id == c3.Id && !foundC3) {
				foundC3 = true;
				expected = c3;
				System.assertEquals('cs2c3', r.getRoleName());
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundC1 && foundC2 && foundC3);
	}

	@IsTest
	static void test_getRelatedRecipients_AccountTeamMembers() {
		if (Salesforce.isValidSObject('AccountTeamMember')) { // Admin must enable
			SObjectType atm = Salesforce.getSObjectType('AccountTeamMember');
			Schema.Account a = TestUtils.createAccount();
			User u1 = UserMock.createUser();
			SObject atm1 = atm.newSObject();
			atm1.put('AccountId', a.Id);
			atm1.put('UserId', u1.Id);
			atm1.put('TeamMemberRole', 'atm1');
			User u2 = UserMock.createUser();
			SObject atm2 = atm.newSObject();
			atm2.put('AccountId', a.Id);
			atm2.put('UserId', u2.Id);
			atm2.put('TeamMemberRole', 'atm2');
			User u3 = UserMock.createUser();
			SObject atm3 = atm.newSObject();
			atm3.put('AccountId', a.Id);
			atm3.put('UserId', u3.Id);
			atm3.put('TeamMemberRole', 'atm3');
			insert new List<SObject> { atm1, atm2, atm3 };
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRelatedRecipients(
				Schema.Account.getSObjectType(),
				new Set<Id> { a.Id },
				new Query.Relationship(
					false,
					'AccountTeamMembers',
					'Account Team Members',
					'AccountTeamMember'),
				new Query.Filter(
					null,
					'TeamMemberRole DESC',
					2));
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			Boolean foundAtm2 = false, foundAtm3 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertNotEquals(null, r.source.id);
				User expected = null;
				if (r.source.id == u2.Id && !foundAtm2) {
					foundAtm2 = true;
					expected = u2;
					System.assertEquals('atm2', r.getRoleName());
				} else if (r.source.id == u3.Id && !foundAtm3) {
					foundAtm3 = true;
					expected = u3;
					System.assertEquals('atm3', r.getRoleName());
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
				System.assertEquals(expected.Name, r.name);
				System.assertEquals(expected.Email, r.email);
				System.assertEquals(expected.Phone, r.phone);
			}
			System.assert(foundAtm2 && foundAtm3);
		}
	}

	@IsTest
	static void test_getRelatedRecipients_OpportunityTeamMembers() {
		if (Salesforce.isValidSObject('OpportunityTeamMember')) { // Admin must enable
			SObjectType atm = Salesforce.getSObjectType('OpportunityTeamMember');
			Opportunity o = TestUtils.createOpportunity();
			User u1 = UserMock.createUser();
			SObject otm1 = atm.newSObject();
			otm1.put('OpportunityId', o.Id);
			otm1.put('UserId', u1.Id);
			otm1.put('TeamMemberRole', 'otm1');
			User u2 = UserMock.createUser();
			SObject otm2 = atm.newSObject();
			otm2.put('OpportunityId', o.Id);
			otm2.put('UserId', u2.Id);
			otm2.put('TeamMemberRole', 'otm2');
			User u3 = UserMock.createUser();
			SObject otm3 = atm.newSObject();
			otm3.put('OpportunityId', o.Id);
			otm3.put('UserId', u3.Id);
			otm3.put('TeamMemberRole', 'otm3');
			insert new List<SObject> { otm1, otm2, otm3 };
			DefaultRecipientResolver rr = new DefaultRecipientResolver();

			Test.startTest();
			List<Recipient> result = rr.getRelatedRecipients(
				Opportunity.getSObjectType(),
				new Set<Id> { o.Id },
				new Query.Relationship(
					false,
					'OpportunityTeamMembers',
					'Opportunity Team Members',
					'OpportunityTeamMember'),
				new Query.Filter(
					null,
					'TeamMemberRole DESC',
					2));
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			Boolean foundOtm2 = false, foundOtm3 = false;
			for (Recipient r : result) {
				System.assertNotEquals(null, r);
				System.assertNotEquals(null, r.source);
				System.assertNotEquals(null, r.source.id);
				User expected = null;
				if (r.source.id == u2.Id && !foundOtm2) {
					foundOtm2 = true;
					expected = u2;
					System.assertEquals('otm2', r.getRoleName());
				} else if (r.source.id == u3.Id && !foundOtm3) {
					foundOtm3 = true;
					expected = u3;
					System.assertEquals('otm3', r.getRoleName());
				} else {
					throw new AssertException('Unexpected recipient: ' + r);
				}
				System.assertEquals(expected.Name, r.name);
				System.assertEquals(expected.Email, r.email);
				System.assertEquals(expected.Phone, r.phone);
			}
			System.assert(foundOtm2 && foundOtm3);
		}
	}

	@IsTest
	static void test_getRecipients_invalid() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();
		SObjectType type = Opportunity.getSObjectType();
		Set<Id> ids = new Set<Id>();

		Test.startTest();
		try {
			rr.getRecipients(type, ids);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { String.valueOf(type) }), ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getRecipients_Contact() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();
		SObjectType type = Contact.getSObjectType();
		Contact r1 = TestUtils.createContact();
		Contact r2 = TestUtils.createContact();
		Set<Id> ids = new Set<Id> { r1.Id, r2.Id };

		Test.startTest();
		List<Recipient> result = rr.getRecipients(type, ids);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		Boolean foundR1 = false, foundR2 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			Id sourceId = r.getSourceId();
			System.assertNotEquals(null, sourceId);
			Contact expected = null;
			if (sourceId == r1.Id && !foundR1) {
				foundR1 = true;
				expected = r1;
			} else if (sourceId == r2.Id && !foundR2) {
				foundR2 = true;
				expected = r2;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundR1 && foundR2);
	}

	@IsTest
	static void test_getRecipients_Lead() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();
		SObjectType type = Lead.getSObjectType();
		Lead r1 = TestUtils.createLead();
		Lead r2 = TestUtils.createLead();
		Set<Id> ids = new Set<Id> { r1.Id, r2.Id };

		Test.startTest();
		List<Recipient> result = rr.getRecipients(type, ids);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		Boolean foundR1 = false, foundR2 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			Id sourceId = r.getSourceId();
			System.assertNotEquals(null, sourceId);
			Lead expected = null;
			if (sourceId == r1.Id && !foundR1) {
				foundR1 = true;
				expected = r1;
			} else if (sourceId == r2.Id && !foundR2) {
				foundR2 = true;
				expected = r2;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundR1 && foundR2);
	}

	@IsTest
	static void test_getRecipients_User() {
		DefaultRecipientResolver rr = new DefaultRecipientResolver();
		SObjectType type = User.getSObjectType();
		User r1 = UserMock.createUser();
		User r2 = UserMock.createUser();
		Set<Id> ids = new Set<Id> { r1.Id, r2.Id };

		Test.startTest();
		List<Recipient> result = rr.getRecipients(type, ids);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		Boolean foundR1 = false, foundR2 = false;
		for (Recipient r : result) {
			System.assertNotEquals(null, r);
			Id sourceId = r.getSourceId();
			System.assertNotEquals(null, sourceId);
			User expected = null;
			if (sourceId == r1.Id && !foundR1) {
				foundR1 = true;
				expected = r1;
			} else if (sourceId == r2.Id && !foundR2) {
				foundR2 = true;
				expected = r2;
			} else {
				throw new AssertException('Unexpected recipient: ' + r);
			}
			System.assertEquals(expected.Name, r.name);
			System.assertEquals(expected.Email, r.email);
			System.assertEquals(expected.Phone, r.phone);
		}
		System.assert(foundR1 && foundR2);
	}
}
