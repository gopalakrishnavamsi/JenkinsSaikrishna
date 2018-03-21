@IsTest
private class EntityTest {

	static testMethod void test_equals() {
		Entity e1 = new Entity(UserInfo.getUserId());
		Entity e2 = new Entity(UserInfo.getUserId());
		Entity e3 = new Entity(UserInfo.getOrganizationId());

		Test.startTest();
		System.assertEquals(e1, e2);
		System.assertNotEquals(e1, e3);
		Test.stopTest();
	}

	static testMethod void test_toString() {
		System.runAs(TestUtils.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Entity e1 = new Entity(o.Id, o.Name, new Entity(a.Id, a.Name, null));
			Entity e2 = new Entity(a.Id, a.Name, null);
			Entity e3 = new Entity(null);

			Test.startTest();
			System.assertEquals(String.format('{0}: {1} {2} {3}', new List<String> {
				e1.label, e1.name, System.Label.ForLabel, e1.parent.name
			}), e1.toString());
			System.assertEquals(String.format('{0}: {1}', new List<String> {
				e2.label, e2.name
			}), e2.toString());
			System.assertEquals('', e3.toString());
			Test.stopTest();
		}
	}

	static testMethod void test_isValid() {
		Test.startTest();
		System.assert(Entity.isValid(new Entity(UserInfo.getUserId())));
		System.assert(!Entity.isValid(new Entity(null)));
		System.assert(!Entity.isValid(null));
		Test.stopTest();
	}

	static testMethod void test_resolve() {
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
		Test.startTest();
		try {
			Entity.resolve(null);
			throw new AssertException('Expected Entity.resolve() to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedId, ex.getMessage());
		}
		try {
			Entity.resolve(null, UserInfo.getUserId());
			throw new AssertException('Expected Entity.resolve() to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedType, ex.getMessage());
		}
		Test.stopTest();
	}
}
