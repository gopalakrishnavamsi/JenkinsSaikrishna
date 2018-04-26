@IsTest
private class CredentialsTest {

	static testMethod void test_getAccountCredentials() {
		UUID accountId = UUID.randomUUID();
		TestUtils.createAccountConfiguration(accountId, accountId.toString());

		Test.startTest();
		Credentials.AccountCredentials result1 = Credentials.getAccountCredentials();
		Credentials.AccountCredentials result2 = Credentials.getAccountCredentials();
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertEquals(accountId, result1.accountId);
		System.assertEquals(accountId.toString(), result1.username);

		System.assert(result2 === result1);
	}

	static testMethod void test_getUserCredentials() {
		User u1 = TestUtils.createUser();
		User u2 = TestUtils.createUser();

		Test.startTest();
		Credentials.UserCredentials result1 = Credentials.getUserCredentials(u1.Id);
		Credentials.UserCredentials result2 = Credentials.getUserCredentials(u1.Id);
		Credentials.UserCredentials result3 = Credentials.getUserCredentials(u2.Id);
		Credentials.UserCredentials result4 = Credentials.getUserCredentials(u2.Id);
		Test.stopTest();

		UserSettings__c s1 = UserSettings__c.getInstance(u1.Id);
		UserSettings__c s2 = UserSettings__c.getInstance(u2.Id);

		System.assertNotEquals(null, result1);
		System.assertEquals(s1.Username__c, result1.username);
		System.assertEquals(s1.Password__c, result1.password);

		System.assert(result2 === result1);

		System.assert(result3 !== result1);
		System.assertNotEquals(null, result3);
		System.assertEquals(s2.Username__c, result3.username);
		System.assertEquals(s2.Password__c, result3.password);

		System.assert(result4 === result3);
	}

	static testMethod void test_buildAPICredentials() {
		UUID accountId = UUID.randomUUID();
		String au = UUID.randomUUID().toString();
		String ap = UUID.randomUUID().toString();
		Credentials.AccountCredentials ac1 = new Credentials.AccountCredentials(
			Environment.demo, accountId, au, ap, true);
		Credentials.AccountCredentials ac2 = new Credentials.AccountCredentials(
			Environment.demo, accountId, au, ap, false);
		Credentials.UserCredentials uc = new Credentials.UserCredentials(
			UUID.randomUUID().toString(), UUID.randomUUID().toString());

		Test.startTest();
		Credentials result1 = Credentials.buildAPICredentials(ac1, uc);
		Credentials result2 = Credentials.buildAPICredentials(ac2, uc);
		try {
			Credentials.buildAPICredentials(ac1, null);
			throw new AssertException('Expected buildAPICredentials to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.ConfigurationError, ex.getMessage());
		}
		try {
			Credentials.buildAPICredentials(null, uc);
			throw new AssertException('Expected buildAPICredentials to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.ConfigurationError, ex.getMessage());
		}
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertEquals(Environment.demo, result1.environment);
		System.assertEquals(accountId, result1.accountId);
		System.assertEquals(au, result1.username);
		System.assertEquals(ap, result1.password);
		System.assert(result1.useSendOnBehalfOf);
		System.assertEquals(uc.username, result1.sendOnBehalfOf);

		System.assertNotEquals(null, result2);
		System.assert(result2.isValid);
		System.assertEquals(Environment.demo, result2.environment);
		System.assertEquals(accountId, result2.accountId);
		System.assertEquals(uc.username, result2.username);
		System.assertEquals(uc.password, result2.password);
		System.assert(!result2.useSendOnBehalfOf);
		System.assertEquals(null, result2.sendOnBehalfOf);
	}

	static testMethod void test_getInstance_default() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Credentials result1 = Credentials.getInstance();
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertNotEquals(null, result1.environment);
			System.assertNotEquals(null, result1.environment.baseUrl);
			System.assertEquals(TestUtils.BASE_Url, result1.environment.baseUrl.toExternalForm());
			System.assert(result1.useSendOnBehalfOf);
			System.assertEquals(UserSettings__c.getInstance().Username__c, result1.sendOnBehalfOf);

			System.assert(result2 === result1);
		}
	}

	static testMethod void test_getInstance_custom() {
		String username = UUID.randomUUID().toString();
		String password = UUID.randomUUID().toString();

		Test.startTest();
		Credentials result1 = Credentials.getInstance(Environment.production, username, password);
		Credentials result2 = Credentials.getInstance(Environment.production, username, password);
		Credentials result3 = Credentials.getInstance(null, username, password);
		Credentials result4 = Credentials.getInstance(Environment.invalid, username, password);
		Credentials result5 = Credentials.getInstance(Environment.demo, '', password);
		Credentials result6 = Credentials.getInstance(Environment.demo, username, '    ');
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isValid);
		System.assertEquals(Environment.production, result1.environment);
		System.assertEquals(username, result1.username);
		System.assertEquals(password, result1.password);
		System.assert(!result1.useSendOnBehalfOf);

		System.assertNotEquals(null, result2);
		System.assert(result2 !== result1);
		System.assert(result2.isValid);
		System.assertEquals(Environment.production, result2.environment);
		System.assertEquals(username, result2.username);
		System.assertEquals(password, result2.password);
		System.assert(!result2.useSendOnBehalfOf);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isValid);

		System.assertNotEquals(null, result4);
		System.assert(!result4.isValid);

		System.assertNotEquals(null, result5);
		System.assert(!result5.isValid);

		System.assertNotEquals(null, result6);
		System.assert(!result6.isValid);
	}

	static testMethod void test_getInstance_user() {
		User u1 = TestUtils.createDocuSignUser();
		User u2 = TestUtils.createDocuSignUser();

		System.runAs(u1) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Credentials result1 = Credentials.getInstance(u1.Id, true);
			Credentials result2 = Credentials.getInstance(u1.Id, true);
			Credentials result3 = Credentials.getInstance(u2.Id, true);
			Credentials result4 = Credentials.getInstance(u2.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);

			System.assertNotEquals(null, result2);
			System.assert(result2.isValid);
			System.assert(result2 === result1);

			System.assertNotEquals(null, result3);
			System.assert(result3.isValid);
			System.assert(result3 !== result1);

			System.assertNotEquals(null, result4);
			System.assert(result4.isValid);
			System.assert(result4 !== result3);
		}
	}

	static testMethod void test_getInstance_error() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				Credentials.getInstance(UserInfo.getUserId(), true);
				throw new AssertException('Expected getInstance to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_save_insert_sobo() {
		UUID accountId = UUID.randomUUID();
		String username = UUID.randomUUID().toString();
		String password = UUID.randomUUID().toString();
		User u = TestUtils.createDocuSignAdministrator();

		System.runAs(u) {
			Test.startTest();
			Credentials result1 = Credentials.save(Environment.production, accountId,
				username, password, true, true);
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertEquals(Environment.production, result1.environment);
			System.assertEquals(accountId, result1.accountId);
			System.assertEquals(username, result1.username);
			System.assertEquals(password, result1.password);
			System.assertEquals(true, AccountSettings__c.getOrgDefaults().SetupComplete__c);
			System.assert(result1.useSendOnBehalfOf);
			System.assertEquals(username, result1.sendOnBehalfOf);
			System.assertEquals(username, [SELECT Username__c FROM User WHERE Id = :u.Id LIMIT 1].Username__c);
			System.assertEquals(username, UserSettings__c.getInstance().Username__c);
			System.assertEquals(null, UserSettings__c.getInstance().Password__c);

			System.assert(result2 === result1);
		}
	}

	static testMethod void test_save_insert_no_sobo() {
		UUID accountId = UUID.randomUUID();
		String username = UUID.randomUUID().toString();
		String password = UUID.randomUUID().toString();
		User u = TestUtils.createDocuSignAdministrator();

		System.runAs(u) {
			Test.startTest();
			Credentials result1 = Credentials.save(Environment.production, accountId,
				username, password, false, false);
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertEquals(Environment.production, result1.environment);
			System.assertEquals(accountId, result1.accountId);
			System.assertEquals(username, result1.username);
			System.assertEquals(password, result1.password);
			System.assertEquals(false, AccountSettings__c.getOrgDefaults().SetupComplete__c);
			System.assert(!result1.useSendOnBehalfOf);
			System.assertEquals(null, result1.sendOnBehalfOf);
			System.assertEquals(username, [SELECT Username__c FROM User WHERE Id = :u.Id LIMIT 1].Username__c);
			System.assertEquals(username, UserSettings__c.getInstance().Username__c);
			System.assertEquals(password, UserSettings__c.getInstance().Password__c);

			System.assert(result2 === result1);
		}
	}

	static testMethod void test_save_update() {
		UUID accountId = UUID.randomUUID();
		UUID username = UUID.randomUUID();
		String password = UUID.randomUUID().toString();
		User u = TestUtils.createDocuSignAdministrator();

		System.runAs(u) {
			TestUtils.createAccountConfiguration();
			Credentials baseline = Credentials.getInstance();

			Test.startTest();
			Credentials result1 = Credentials.save(Environment.production, accountId,
				String.valueOf(username), password, false, true);
			Credentials result2 = Credentials.getInstance();
			Test.stopTest();

			System.assert(result1 !== baseline);
			System.assertNotEquals(null, result1);
			System.assert(result1.isValid);
			System.assertEquals(Environment.production, result1.environment);
			System.assertEquals(accountId, result1.accountId);
			System.assertEquals(String.valueOf(username), result1.username);
			System.assertEquals(password, result1.password);
			System.assertEquals(true, AccountSettings__c.getOrgDefaults().SetupComplete__c);
			System.assert(!result1.useSendOnBehalfOf);
			System.assertEquals(null, result1.sendOnBehalfOf);
			System.assertEquals(String.valueOf(username), [SELECT Username__c FROM User WHERE Id = :u.Id LIMIT 1].Username__c);
			System.assertEquals(String.valueOf(username), UserSettings__c.getInstance().Username__c);
			System.assertEquals(password, UserSettings__c.getInstance().Password__c);

			System.assert(result2 === result1);
		}
	}

	static testMethod void test_addUsers() {
		String accountUsername = UUID.randomUUID().toString() + '@unit.test';
		UUID dsaUsername = UUID.randomUUID();
		User dsa = TestUtils.createDocuSignAdministrator();
		String dsu1Username = UUID.randomUUID().toString();
		User dsu1 = TestUtils.createUser();
		String dsu2Username = UUID.randomUUID().toString();
		User dsu2 = TestUtils.createUser();
		String dsu3Username = UUID.randomUUID().toString();
		User dsu3 = TestUtils.createUser();

		System.runAs(dsa) {
			TestUtils.createAccountConfiguration(UUID.randomUUID(), accountUsername);

			Test.startTest();
			Credentials.addUsers(new Map<Id, Credentials.UserCredentials> {
				dsu1.Id => new Credentials.UserCredentials(dsu1Username, 'password1', false),
				dsu2.Id => new Credentials.UserCredentials(dsu2Username, 'password2', true),
				dsu3.Id => null
			});
			Test.stopTest();

			System.assertEquals(dsu1Username, UserSettings__c.getInstance(dsu1.Id).Username__c);
			System.assertEquals('password1', UserSettings__c.getInstance(dsu1.Id).Password__c);
			System.assertEquals(dsu1Username, [SELECT Username__c FROM User WHERE Id = :dsu1.Id].Username__c);
			System.assert(!Permissions.isDocuSignAdministrator(dsu1.Id));
			System.assert(Permissions.isDocuSignUser(dsu1.Id));

			System.assertEquals(dsu2Username, UserSettings__c.getInstance(dsu2.Id).Username__c);
			System.assertEquals('password2', UserSettings__c.getInstance(dsu2.Id).Password__c);
			System.assertEquals(dsu2Username, [SELECT Username__c FROM User WHERE Id = :dsu2.Id].Username__c);
			System.assert(Permissions.isDocuSignAdministrator(dsu2.Id));
			System.assert(Permissions.isDocuSignUser(dsu2.Id));

			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu3.Id].Username__c);
			System.assert(!Permissions.isDocuSignAdministrator(dsu3.Id));
			System.assert(!Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	static testMethod void test_clear_account() {
		String accountUsername = UUID.randomUUID().toString() + '@unit.test';
		String dsaUsername = UUID.randomUUID().toString();
		User dsa = TestUtils.createDocuSignAdministrator(dsaUsername);
		String dsu1Username = UUID.randomUUID().toString();
		User dsu1 = TestUtils.createDocuSignUser(dsu1Username);
		String dsu2Username = UUID.randomUUID().toString();
		User dsu2 = TestUtils.createDocuSignUser(dsu2Username);
		String dsu3Username = UUID.randomUUID().toString();
		User dsu3 = TestUtils.createDocuSignUser(dsu3Username);

		System.runAs(dsa) {
			TestUtils.createAccountConfiguration(UUID.randomUUID(), accountUsername);

			Credentials result = Credentials.getInstance(dsu1.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu1Username), result.sendOnBehalfOf);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu2Username), result.sendOnBehalfOf);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu3Username), result.sendOnBehalfOf);

			Test.startTest();
			Credentials.clear(false);
			Test.stopTest();

			System.assertEquals(false, AccountSettings__c.getOrgDefaults().SetupComplete__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().BaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Username__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Password__c);

			System.assertEquals(String.valueOf(dsaUsername), UserSettings__c.getInstance(dsa.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsa.Id).Password__c);
			System.assertEquals(String.valueOf(dsaUsername), [SELECT Username__c FROM User WHERE Id = :dsa.Id].Username__c);
			System.assert(Permissions.isDocuSignAdministrator(dsa.Id));

			System.assertEquals(String.valueOf(dsu1Username), UserSettings__c.getInstance(dsu1.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu1.Id).Password__c);
			System.assertEquals(String.valueOf(dsu1Username), [SELECT Username__c FROM User WHERE Id = :dsu1.Id].Username__c);
			System.assert(Permissions.isDocuSignUser(dsu1.Id));

			System.assertEquals(String.valueOf(dsu2Username), UserSettings__c.getInstance(dsu2.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu2.Id).Password__c);
			System.assertEquals(String.valueOf(dsu2Username), [SELECT Username__c FROM User WHERE Id = :dsu2.Id].Username__c);
			System.assert(Permissions.isDocuSignUser(dsu2.Id));

			System.assertEquals(String.valueOf(dsu3Username), UserSettings__c.getInstance(dsu3.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu3.Id).Password__c);
			System.assertEquals(String.valueOf(dsu3Username), [SELECT Username__c FROM User WHERE Id = :dsu3.Id].Username__c);
			System.assert(Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	static testMethod void test_clear_all() {
		String accountUsername = UUID.randomUUID().toString() + '@unit.test';
		String dsaUsername = UUID.randomUUID().toString();
		User dsa = TestUtils.createDocuSignAdministrator(dsaUsername);
		String dsu1Username = UUID.randomUUID().toString();
		User dsu1 = TestUtils.createDocuSignUser(dsu1Username);
		String dsu2Username = UUID.randomUUID().toString();
		User dsu2 = TestUtils.createDocuSignUser(dsu2Username);
		String dsu3Username = UUID.randomUUID().toString();
		User dsu3 = TestUtils.createDocuSignUser(dsu3Username);

		System.runAs(dsa) {
			TestUtils.createAccountConfiguration(UUID.randomUUID(), accountUsername);

			Credentials result = Credentials.getInstance(dsu1.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu1Username), result.sendOnBehalfOf);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu2Username), result.sendOnBehalfOf);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu3Username), result.sendOnBehalfOf);

			Test.startTest();
			Credentials.clear(true);
			Test.stopTest();

			System.assertEquals(false, AccountSettings__c.getOrgDefaults().SetupComplete__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().BaseUrl__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Username__c);
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().Password__c);

			System.assertEquals(null, UserSettings__c.getInstance(dsa.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsa.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsa.Id].Username__c);
			System.assert(Permissions.isDocuSignAdministrator(dsa.Id));

			System.assertEquals(null, UserSettings__c.getInstance(dsu1.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu1.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu1.Id].Username__c);
			System.assert(!Permissions.isDocuSignUser(dsu1.Id));

			System.assertEquals(null, UserSettings__c.getInstance(dsu2.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu2.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu2.Id].Username__c);
			System.assert(!Permissions.isDocuSignUser(dsu2.Id));

			System.assertEquals(null, UserSettings__c.getInstance(dsu3.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu3.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu3.Id].Username__c);
			System.assert(!Permissions.isDocuSignUser(dsu3.Id));
		}
	}

	static testMethod void test_clear_users() {
		String accountUsername = UUID.randomUUID().toString() + '@unit.test';
		String dsaUsername = UUID.randomUUID().toString();
		User dsa = TestUtils.createDocuSignAdministrator(dsaUsername);
		String dsu1Username = UUID.randomUUID().toString();
		User dsu1 = TestUtils.createDocuSignUser(dsu1Username);
		String dsu2Username = UUID.randomUUID().toString();
		User dsu2 = TestUtils.createDocuSignUser(dsu2Username);
		String dsu3Username = UUID.randomUUID().toString();
		User dsu3 = TestUtils.createDocuSignUser(dsu3Username);

		System.runAs(dsa) {
			TestUtils.createAccountConfiguration(UUID.randomUUID(), accountUsername);

			Credentials result = Credentials.getInstance(dsu1.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu1Username), result.sendOnBehalfOf);

			result = Credentials.getInstance(dsu2.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu2Username), result.sendOnBehalfOf);

			result = Credentials.getInstance(dsu3.Id, false);
			System.assertNotEquals(null, result);
			System.assertEquals(accountUsername, result.username);
			System.assertEquals(String.valueOf(dsu3Username), result.sendOnBehalfOf);

			Test.startTest();
			Credentials.clear(new Set<Id> { dsu1.Id, dsu3.Id });
			Test.stopTest();

			System.assertEquals(true, AccountSettings__c.getOrgDefaults().SetupComplete__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Environment__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().BaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Username__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Password__c);

			System.assertNotEquals(null, UserSettings__c.getInstance(dsa.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsa.Id).Password__c);
			System.assertNotEquals(null, [SELECT Username__c FROM User WHERE Id = :dsa.Id].Username__c);
			System.assert(Permissions.isDocuSignAdministrator(dsa.Id));

			System.assertEquals(null, UserSettings__c.getInstance(dsu1.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu1.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu1.Id].Username__c);
			System.assert(!Permissions.isDocuSignUser(dsu1.Id));

			System.assertNotEquals(null, UserSettings__c.getInstance(dsu2.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu2.Id).Password__c);
			System.assertNotEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu2.Id].Username__c);
			System.assert(Permissions.isDocuSignUser(dsu2.Id));

			System.assertEquals(null, UserSettings__c.getInstance(dsu3.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(dsu3.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :dsu3.Id].Username__c);
			System.assert(!Permissions.isDocuSignUser(dsu3.Id));
		}
	}
}
