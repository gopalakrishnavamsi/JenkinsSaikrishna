@IsTest
private class DefaultEntityResolverTest {

	static testMethod void test_canResolve() {
		EntityResolver resolver = new DefaultEntityResolver();

		Test.startTest();
		System.assert(resolver.canResolve(Schema.Account.getSObjectType()));
		System.assert(resolver.canResolve(Schema.UserSettings__c.getSObjectType()));
		System.assert(!resolver.canResolve(null));
		Test.stopTest();
	}

	static testMethod void test_resolve_Account() {
		System.runAs(TestUtils.createUser()) {
			TestUtils.createAccountConfiguration();
			Schema.Account a = TestUtils.createAccount();

			Test.startTest();
			Entity result = Entity.resolve(a.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals(Schema.Account.getSObjectType(), result.type);
			System.assertEquals(a.Id, result.id);
			System.assertEquals(a.Name, result.name);
			System.assertEquals(null, result.parent);
		}
	}

	static testMethod void test_resolve_Opportunity() {
		System.runAs(TestUtils.createUser()) {
			TestUtils.createAccountConfiguration();
			Opportunity o = TestUtils.createOpportunity();

			Test.startTest();
			Entity result = Entity.resolve(o.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals(Opportunity.getSObjectType(), result.type);
			System.assertEquals(o.Id, result.id);
			System.assertNotEquals(null, result.parent);
			System.assertEquals(o.AccountId, result.parent.id);
		}
	}

	static testMethod void test_resolve_Contact() {
		System.runAs(TestUtils.createUser()) {
			TestUtils.createAccountConfiguration();
			Contact c = TestUtils.createContact();

			Test.startTest();
			Entity result = Entity.resolve(c.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals(Contact.getSObjectType(), result.type);
			System.assertEquals(c.Id, result.id);
			System.assertNotEquals(null, result.parent);
			System.assertEquals(c.AccountId, result.parent.id);
		}
	}

	static testMethod void test_resolve_Case() {
		System.runAs(TestUtils.createUser()) {
			TestUtils.createAccountConfiguration();
			Case c = TestUtils.createCase();

			Test.startTest();
			Entity result = Entity.resolve(c.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals(Case.getSObjectType(), result.type);
			System.assertEquals(c.Id, result.id);
			System.assertNotEquals(null, result.parent);
			System.assertEquals(c.AccountId, result.parent.id);
		}
	}

	static testMethod void test_resolve_other() {
		System.runAs(TestUtils.createAdministrator()) {
			TestUtils.createAccountConfiguration();
			User u = TestUtils.createUser();
			Schema.Account a = TestUtils.createAccount();
			Lead l = TestUtils.createLead();

			Test.startTest();
			Entity result1 = Entity.resolve(u.Id);
			Entity result2 = Entity.resolve(a.Id);
			Entity result3 = Entity.resolve(l.Id);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertEquals(User.getSObjectType(), result1.type);
			System.assertEquals(u.Id, result1.id);
			System.assertEquals(u.FirstName + ' ' + u.LastName, result1.name);
			System.assertEquals(null, result1.parent);

			System.assertNotEquals(null, result2);
			System.assert(result2.isValid);
			System.assertEquals(Schema.Account.getSObjectType(), result2.type);
			System.assertEquals(a.Id, result2.id);
			System.assertEquals(a.Name, result2.name);
			System.assertEquals(null, result2.parent);

			System.assertNotEquals(null, result3);
			System.assert(result3.isValid);
			System.assertEquals(Lead.getSObjectType(), result3.type);
			System.assertEquals(l.Id, result3.id);
			System.assertEquals(l.FirstName + ' ' + l.LastName, result3.name);
			System.assertEquals(null, result3.parent);
		}
	}

	static testMethod void test_resolve_error() {
		DefaultEntityResolver resolver = new DefaultEntityResolver();

		Test.startTest();
		try {
			resolver.resolve(null);
			throw new AssertException('Expected DefaultEntityResolver.resolve() to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedId, ex.getMessage());
		}
		Test.stopTest();
	}
}
