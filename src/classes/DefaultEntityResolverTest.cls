@IsTest
private class DefaultEntityResolverTest {

	static testMethod void test_canResolve() {
		EntityResolver resolver = new DefaultEntityResolver();

		Test.startTest();
		System.assert(resolver.canResolve('Account'));
		System.assert(resolver.canResolve('account'));
		System.assert(resolver.canResolve('OPPORTUNITY'));
		System.assert(resolver.canResolve('\tEnvelope__c  '));
		System.assert(!resolver.canResolve(null));
		System.assert(!resolver.canResolve(''));
		System.assert(!resolver.canResolve('\r'));
		System.assert(!resolver.canResolve('unittest__BogusObject__c'));
		Test.stopTest();
	}

	static testMethod void test_resolve_Account() {
		System.runAs(TestUtils.createUser()) {
			TestUtils.createAccountConfiguration();
			Schema.Account a = TestUtils.createAccount();

			Test.startTest();
			Entity result = Entity.resolve('Account', a.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals('Account', result.type);
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
			Entity result = Entity.resolve('Opportunity', o.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals('Opportunity', result.type);
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
			Entity result = Entity.resolve('Contact', c.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals('Contact', result.type);
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
			Entity result = Entity.resolve('Case', c.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
			System.assertEquals('Case', result.type);
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
			System.assertEquals('User', result1.type);
			System.assertEquals(u.Id, result1.id);
			System.assertEquals(u.FirstName + ' ' + u.LastName, result1.name);
			System.assertEquals(null, result1.parent);

			System.assertNotEquals(null, result2);
			System.assert(result2.isValid);
			System.assertEquals('Account', result2.type);
			System.assertEquals(a.Id, result2.id);
			System.assertEquals(a.Name, result2.name);
			System.assertEquals(null, result2.parent);

			System.assertNotEquals(null, result3);
			System.assert(result3.isValid);
			System.assertEquals('Lead', result3.type);
			System.assertEquals(l.Id, result3.id);
			System.assertEquals(l.FirstName + ' ' + l.LastName, result3.name);
			System.assertEquals(null, result3.parent);
		}
	}

	static testMethod void test_resolve_error() {
		DefaultEntityResolver resolver = new DefaultEntityResolver();

		Test.startTest();
		try {
			resolver.resolve(null, null);
			throw new AssertException('Expected DefaultEntityResolver.resolve() to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedType, ex.getMessage());
		}
		try {
			resolver.resolve('test', null);
			throw new AssertException('Expected DefaultEntityResolver.resolve() to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedId, ex.getMessage());
		}
		Test.stopTest();
	}
}
